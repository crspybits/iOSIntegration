//
//  ShareViewController.swift
//  Share
//
//  Created by Christopher G Prince on 10/3/20.
//

import UIKit
//import Social
import MobileCoreServices
import iOSShared
import iOSBasics
import SwiftUI
import iOSSignIn

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.info("viewDidLoad: ShareViewController")

        guard setupServices() else {
            return
        }
        
        viewModel.userSignedIn = Services.session.signInServices.manager.userIsSignedIn

        setupView()
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
        let heightProportion: CGFloat = 0.7
        viewModel.width = size.width * widthProportion
        viewModel.height = size.height * heightProportion
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        setViewModelSize(size: size)
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
            #warning("Handle this error; show an alert and quit the sharing extension if we get it.")
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

    func handleSharedFile() {
        // extracting the path to the URL that is being shared
        let attachments = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        let contentType = "public.jpeg"
        let dataContentType = kUTTypeData as String
          
        for provider in attachments {
            // Check if the content type is the same as we expected
            let conforms = provider.hasItemConformingToTypeIdentifier(contentType)
            if conforms {
                provider.loadItem(forTypeIdentifier: dataContentType,
                            options: nil) { [unowned self] (data, error) in
                    // Handle the error here if you want
                    guard error == nil else { return }
                       
                    if let url = data as? URL,
                        let imageData = try? Data(contentsOf: url) {
                       
                    } else {
                        // Handle this situation as you prefer
                        fatalError("Impossible to save image")
                    }
                }
            }
        }
    }
    
    
    // If you return `false` here, when the UI comes up, the `Post` button will not be available.
    func isContentValid() -> Bool {
        
//        if let data = imageData {
//            if contentText.count > 0 {
//                return true
//            }
//        }
        return false
    }

    func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
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
