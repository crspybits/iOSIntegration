//
//  ShareViewController.swift
//  Share
//
//  Created by Christopher G Prince on 10/3/20.
//

import UIKit
import MobileCoreServices
import iOSShared
import iOSBasics
import SwiftUI
import iOSSignIn
import ServerShared

struct ShowAlert {
    let title: String
    let message: String
}

// https://medium.com/macoclock/ios-share-extension-swift-5-1-1606263746b
// https://stackoverflow.com/questions/40769387/getting-an-ios-share-action-extension-to-show-up-only-for-a-single-image
// https://diamantidis.github.io/2020/01/11/share-extension-custom-ui
// https://dmtopolog.com/ios-app-extensions-data-sharing/
// https://www.9spl.com/blog/build-share-extension-ios-using-swift/

// To make a custom UI: https://stackoverflow.com/questions/25922118 (The original superclass for ShareViewController was `SLComposeServiceViewController`).

class ShareViewController: UIViewController {
    let viewModel = ViewModel()
    var serverInterface:ServerInterface!
    var hostingController:UIHostingController<SharingView>!
    var showAlert: ShowAlert?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.info("viewDidLoad: ShareViewController")

        viewModel.userSignedIn = false
        
        if setupServices() {
            viewModel.userSignedIn = Services.session.signInServices.manager.userIsSignedIn
        }
        
        viewModel.cancel = { [weak self] in
            self?.cancel()
        }
        
        viewModel.post = { [weak self] preview, sharingGroupUUID in
            self?.uploadFile(preview: preview, sharingGroupUUID: sharingGroupUUID)
        }
        
        setupView()
        
        getSharedFile()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        setViewModelSize(size: size)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let showAlert = showAlert {
            Alert.show(withTitle: showAlert.title, message: showAlert.message, style: .alert) {
                 self.cancel()
            }
        }
    }
    
    func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    }
    
    // MARK: Button actions
    /*
    @IBAction func cancelAction(_ sender: Any) {
        // See also https://stackoverflow.com/questions/43670938
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    @IBAction func postAction(_ sender: Any) {
    }*/
}


extension ShareViewController {
    func cancel() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    func done() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    func setupView() {
        setViewModelSize(size: view.frame.size)
        hostingController = UIHostingController(rootView: SharingView(viewModel: viewModel))
        addChild(hostingController)
        
        // Having problems not getting clipping when I do this from SwiftUI, so doing it here. See also https://stackoverflow.com/questions/57269651
        hostingController.view.layer.cornerRadius = 10
        hostingController.view.layer.masksToBounds = true
        hostingController.view.layer.borderWidth = 1
        
        let color: UIColor
        if traitCollection.userInterfaceStyle == .light {
            color = UIColor(white: 0.3, alpha: 1)
        } else {
            color = UIColor(white: 0.7, alpha: 1)
        }
        
        hostingController.view.layer.borderColor = color.cgColor
        
        view.addSubview(hostingController.view)
        addConstaints()
    }
    
    func setViewModelSize(size: CGSize) {
        let widthProportion: CGFloat = 0.8
        let shortHeightProportion: CGFloat = widthProportion
        let tallHeightProportion: CGFloat = 0.6
        
        viewModel.width = size.width * widthProportion
        
        if size.height > size.width {
            viewModel.height = size.height * tallHeightProportion
        }
        else {
            viewModel.height = size.height * shortHeightProportion
        }
    }
    
    func addConstaints() {
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        hostingController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    func setupServices() -> Bool {
        // If the sharing extension is used twice in a row, we oddly have a state where it's already been initialized. Get a crash on multiple initialization, so be careful.
        if Services.setupState == .none {
            Services.setup()
        }
        
        if Services.setupState == .done(appLaunch: false) {
            Services.session.appLaunch(options: nil)
        }
        
        logger.info("Services.session.setupState: \(Services.setupState)")
        
        guard Services.setupState.isComplete else {
            logger.error("Services.session.setupState: \(Services.setupState)")
            showAlert = ShowAlert(title: "Alert!", message: "Problem with setting up sharing.")
            return false
        }
        
        serverInterface = Services.session.serverInterface

        serverInterface.syncCompleted = { [weak self] in
            guard let self = self else { return }
            if let sharingGroups = try? self.serverInterface.syncServer.sharingGroups() {
                self.viewModel.sharingGroups = sharingGroups.enumerated().map { index, group in
                    return SharingGroupData(id: group.sharingGroupUUID, name: group.sharingGroupName ?? "Album \(index)")
                }
            }
            self.serverInterface.syncCompleted = nil
        }
        
        do {
            try Services.session.serverInterface.syncServer.sync()
        }
        catch let error {
            logger.error("\(error)")
        }
        
        return true
    }

    func getSharedFile() {
        getSharedFile { [weak self] result in
            switch result {
            case .success(let sharedFile):
                var image: UIImage?
                var imageURL: URL?
                
                switch sharedFile {
                case .image(let url):
                    imageURL = url
                    do {
                        let data = try Data(contentsOf: url)
                        image = UIImage(data: data)
                    } catch let error {
                        logger.error("\(error)")
                    }
                }
                
                if let image = image, let url = imageURL {
                    DispatchQueue.main.async {
                        self?.viewModel.preview = .image(image, url)
                    }
                }
                else {
                    self?.showAlert = ShowAlert(title: "Alert!", message: "Could not load image!")
                }
            case .failure(let error):
                self?.showAlert = ShowAlert(title: "Alert!", message: "Could not load image!")
                logger.error("\(error)")
            }
        }
    }
    
    enum SharedFile {
        case image(URL)
    }

    enum HandleSharedFileError: Error {
        case notJustOneFile
        case wrongFileType
        case noURL
    }

    func getSharedFile(completion: @escaping (Result<SharedFile, Error>)->()) {
        let attachments = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        let jpegType = "public.jpeg"
        
        guard attachments.count == 1 else {
            completion(.failure(HandleSharedFileError.notJustOneFile))
            return
        }
          
        let attachment = attachments[0]

        guard attachment.hasItemConformingToTypeIdentifier(jpegType) else {
            completion(.failure(HandleSharedFileError.wrongFileType))
            return
        }

        let dataContentType = kUTTypeData as String
        attachment.loadItem(forTypeIdentifier: dataContentType, options: nil) { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let url = data as? URL {
                completion(.success(.image(url)))
                return
            }
            
            completion(.failure(HandleSharedFileError.noURL))
        }
    }
    
    func uploadFile(preview: Preview, sharingGroupUUID: UUID) {
        let fileUUID = UUID()
        let fileGroupUUID = UUID()
        
        let declaration1 = FileDeclaration(uuid: fileUUID, mimeType: MimeType.jpeg, appMetaData: nil, changeResolverName: nil)
        let declarations = Set<FileDeclaration>([declaration1])

        guard case .image(_, let url) = preview else {
            Alert.show(withTitle: "Alert!", message: "Could not get image!", style: .alert)
            cancel()
            return
        }
        
        let uploadable1 = FileUpload(uuid: fileUUID, dataSource: .copy(url))
        let uploadables = Set<FileUpload>([uploadable1])

        let testObject = ObjectDeclaration(fileGroupUUID: fileGroupUUID, objectType: "Image", sharingGroupUUID: sharingGroupUUID, declaredFiles: declarations)
        
        do {
            try serverInterface.syncServer.queue(uploads: uploadables, declaration: testObject)
            done()
        } catch let error {
            logger.error("\(error)")
            Alert.show(withTitle: "Alert!", message: "Could not queue image for upload!", style: .alert)
            cancel()
        }
    }
}
