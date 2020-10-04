import UIKit
import iOSSignIn
import iOSShared
import ServerShared
import iOSBasics
import PersistentValue

enum ServicesError: Error {
    case noDocumentDirectory
}

class Services {
    // You must use the App Groups Entitlement and setup a applicationGroupIdentifier https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups
    let applicationGroupIdentifier = "group.biz.SpasticMuffin.SharedImages"
    
    // See https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps
    // Note this can't just be your bundle ID. See https://useyourloaf.com/blog/keychain-group-access/
    // and https://stackoverflow.com/questions/11726672/access-app-identifier-prefix-programmatically
    let keychainSharingGroup = "BH68R29JBE.biz.SpasticMuffin.SharedImages"
    
    // Going to use the literal bundle id, so it's the same across the app and the sharing extension.
    let keychainService = "biz.SpasticMuffin.SharedImages"

    // In the documents directory
    let logFileName = "LogFile.txt"

    static let session = Services()
    var signInServices: SignInServices!
    var serverInterface:ServerInterface!
    var setupFailure = false
    var signInsToAdd = [GenericSignIn]()
    private static let plistServerConfig = ("Server", "plist")

    private init() {
        do {
            try SharedContainer.appLaunchSetup(applicationGroupIdentifier: applicationGroupIdentifier)
        } catch let error {
            logger.error("\(error)")
            setupFailure = true
            return
        }
        
        logger.info("SharedContainer.session.sharedContainerURL: \(String(describing: SharedContainer.session?.sharedContainerURL))")
                
        guard let documentsURL = SharedContainer.session?.documentsURL else {
            logger.error("Could not get documentsURL")
            setupFailure = true
            return
        }
        
        PersistentValueFile.alternativeDocumentsDirectory = documentsURL.path
        PersistentValueKeychain.keychainService = keychainService
        PersistentValueKeychain.accessGroup = keychainSharingGroup

        guard let path = Bundle.main.path(forResource: Self.plistServerConfig.0, ofType: Self.plistServerConfig.1) else {
            setupFailure = true
            return
        }
        
        guard let configPlist = NSDictionary(contentsOfFile: path) as? Dictionary<String, Any> else {
            setupFailure = true
            return
        }
        
        guard let urlString = configPlist["serverURL"] as? String,
            let serverURL = URL(string: urlString) else {
            logger.error("Cannot get server URL")
            setupFailure = true
            return
        }
        
        let signIns = SignIns(signInServicesHelper: self)
        
        do {
            serverInterface = try ServerInterface(signIns: signIns, serverURL: serverURL)
        } catch let error {
            logger.error("Could not start ServerInterface: \(error)")
            setupFailure = true
        }
        
        // This is used to form the URL-type links used for sharing.
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            logger.error("Could not get bundle identifier")
            setupFailure = true
            return
        }
        
        setupLogging()
        
        // Do this *after* `setupLogging`-- the initial logger created by `iOSShared` doesn't have the file logging setup.
        set(logLevel: .trace)
        
        setupSignInServices(configPlist: configPlist, signIns: signIns, bundleIdentifier: bundleIdentifier, helper: self)
        
        logger.info("Services: init successful!")
    }
    
    func appLaunch(options: [UIApplication.LaunchOptionsKey: Any]?) {
        for signIn in signInsToAdd {
            signInServices.manager.addSignIn(signIn, launchOptions: options)
        }
    }
}

extension Services: SharingInvitationHelper {
    func getSharingInvitationInfo(sharingInvitationUUID: UUID, completion: @escaping (Result<SharingInvitationInfo, Error>) -> ()) {
        serverInterface.syncServer.getSharingInvitationInfo(sharingInvitationUUID: sharingInvitationUUID, completion: completion)
    }
}

extension Services: SignInServicesHelper {
    public func signUserOut() {
        signInServices.manager.currentSignIn?.signUserOut()
    }
    
    public var currentCredentials: GenericCredentials? {
        return signInServices.manager.currentSignIn?.credentials
    }
    
    public var cloudStorageType: CloudStorageType? {
        return signInServices.manager.currentSignIn?.cloudStorageType
    }
    
    public var userType: UserType? {
        return signInServices.manager.currentSignIn?.userType
    }
}
