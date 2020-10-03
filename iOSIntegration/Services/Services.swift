import UIKit
import iOSSignIn
import iOSShared
import ServerShared
import iOSBasics

enum ServicesError: Error {
    case noDocumentDirectory
}

class Services {
    // In the documents directory
    let logFileName = "LogFile.txt"

    static let session = Services()
    var signInServices: SignInServices!
    var serverInterface:ServerInterface!
    var setupFailure = false
    var signInsToAdd = [GenericSignIn]()
    private static let plistServerConfig = ("Server", "plist")

    private init() {
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
        
        guard let bundleIdentifier =  Bundle.main.bundleIdentifier else {
            logger.error("Could not get bundle identifier")
            setupFailure = true
            return
        }
        
        do {
            try setupLogging()
        } catch let error {
            logger.error("Could not setup logging: \(error)")
            setupFailure = true
        }
        
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
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return signInServices.manager.application(UIApplication.shared, open: url) ||
            signInServices.sharingInvitation.application(UIApplication.shared, open: url)
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


