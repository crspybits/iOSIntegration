//
//  ShareViewController.swift
//  Share
//
//  Created by Christopher G Prince on 10/3/20.
//

import UIKit
import Social
import MobileCoreServices
import iOSShared
import iOSBasics

// https://medium.com/macoclock/ios-share-extension-swift-5-1-1606263746b
// https://stackoverflow.com/questions/40769387/getting-an-ios-share-action-extension-to-show-up-only-for-a-single-image
// https://diamantidis.github.io/2020/01/11/share-extension-custom-ui
// https://dmtopolog.com/ios-app-extensions-data-sharing/
// https://www.9spl.com/blog/build-share-extension-ios-using-swift/

// To make a custom UI: https://stackoverflow.com/questions/25922118 (The original superclass for ShareViewController was `SLComposeServiceViewController`).

class ShareViewController: UIViewController {
    var imageData: NSData?
    @IBOutlet weak var sharingContainer: UIView!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sharingItems: UICollectionView!
    var serverInterface:ServerInterface!
    var groups = [iOSBasics.SharingGroup]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        serverInterface = Services.session.serverInterface
        
        sharingContainer.layer.cornerRadius = 10
        sharingContainer.layer.masksToBounds = true
        
        Services.session.appLaunch(options: nil)
        let failure = Services.session.setupFailure
        logger.info("Services.session.setupFailure: \(failure)")
        
        #warning("Handle this error; show an alert and quit if we get it.")
        guard !failure else {
            return
        }
        
        serverInterface.syncCompleted = { [weak self] in
            guard let self = self else { return }
            if let sharingGroups = try? self.serverInterface.syncServer.sharingGroups() {
                self.groups = sharingGroups
                self.tableView.reloadSections([0], with: .automatic)
            }
            self.serverInterface.syncCompleted = nil
        }
        
        do {
            try Services.session.serverInterface.syncServer.sync()
        }
        catch let error {
            logger.error("\(error)")
        }
        
        //self.handleSharedFile()
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
    
    @IBAction func cancelAction(_ sender: Any) {
        // See also https://stackoverflow.com/questions/43670938
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    @IBAction func postAction(_ sender: Any) {
    }
}

extension ShareViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = groups[indexPath.row].sharingGroupName ?? "Sharing group \(indexPath.row)"
        cell.backgroundColor = .clear
        return cell
    }
}
