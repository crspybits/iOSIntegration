
import Foundation
import iOSBasics
import iOSShared
import SQLite
import iOSDropbox
import iOSSignIn
import PersistentValue
import ServerShared

enum ServerInterfaceError: Error {
    case cannotFindFile
    case noDeviceUUID
    case badUUID
    case noSharingGroups
    case cannotConvertStringToData
    case noServerURL
}

class ServerInterface {
    var firstSharingGroupUUID:UUID?
    
    let deviceUUIDString = try! PersistentValue<String>(name: "ServerInterface.deviceUUID", storage: .userDefaults)
        
    // This is within the app's Documents directory
    let databaseFileName = "SQLite.db"
    
    let deviceUUID:UUID
    
    let hashingManager = HashingManager()
    let syncServer:SyncServer

    init(signIns: SignIns, serverURL: URL) throws {
        if deviceUUIDString.value == nil {
            deviceUUIDString.value = UUID().uuidString
        }
        
        guard let uuidString = deviceUUIDString.value else {
            throw ServerInterfaceError.noDeviceUUID
        }
        
        guard let uuid = UUID(uuidString: uuidString) else {
            throw ServerInterfaceError.badUUID
        }
        
        deviceUUID = uuid

        try hashingManager.add(hashing: DropboxHashing())

        let dbURL = Files.getDocumentsDirectory().appendingPathComponent(databaseFileName)
        logger.info("SQLite db: \(dbURL.path)")

        let db = try Connection(dbURL.path)

        let config = Configuration(appGroupIdentifier: nil, serverURL: serverURL, minimumServerVersion: nil, failoverMessageURL: nil, cloudFolderName: "BackgroundTesting", deviceUUID: deviceUUID, temporaryFiles: Configuration.defaultTemporaryFiles)

        syncServer = try SyncServer(hashingManager: hashingManager, db: db, configuration: config, signIns: signIns)
        logger.info("SyncServer initialized!")
        
        syncServer.delegate = self
    }
    
    func sync(sharingGroupUUID: UUID? = nil) {
        do {
            try syncServer.sync(sharingGroupUUID: sharingGroupUUID)
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    func sharingGroups() {
        do {
            let sharingGroups = try syncServer.sharingGroups()
            for sharingGroup in sharingGroups {
                logger.info("\(sharingGroup)")
                if firstSharingGroupUUID == nil {
                    firstSharingGroupUUID = sharingGroup.sharingGroupUUID
                }
            }
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    func createSharingInvitation(permission: Permission, sharingGroupUUID: UUID, numberAcceptors: UInt, allowSharingAcceptance: Bool) {
        syncServer.createSharingInvitation(withPermission: permission, sharingGroupUUID: sharingGroupUUID, numberAcceptors: numberAcceptors, allowSharingAcceptance: allowSharingAcceptance) { result in
            switch result {
            case .failure(let error):
                logger.error("\(error)")
            case .success(let code):
                let sharingURL = Services.session.signInServices.sharingInvitation.createSharingURL(invitationCode: code.uuidString)
                logger.info("sharingURL: \(sharingURL)")
            }
        }
    }
    
    // With a nil fileGroupUUID, creates a new fileGroupUUID.
    func uploadNewFile(sharingGroupUUID: UUID, fileGroupUUID: UUID?, textForFile: String) {
        let fileUUID1 = UUID()

        do {
            let declaration1 = FileDeclaration(uuid: fileUUID1, mimeType: MimeType.text, appMetaData: nil, changeResolverName: nil)
            let declarations = Set<FileDeclaration>([declaration1])
        
            guard let data = textForFile.data(using: .utf8) else {
                throw ServerInterfaceError.cannotConvertStringToData
            }
            
            let uploadable1 = FileUpload(uuid: fileUUID1, dataSource: .data(data))
            let uploadables = Set<FileUpload>([uploadable1])
        
            var fileGroup: UUID
            if let fileGroupUUID = fileGroupUUID {
                fileGroup = fileGroupUUID
            }
            else {
                fileGroup = UUID()
            }
            
            let testObject = ObjectDeclaration(fileGroupUUID: fileGroup, objectType: "foo", sharingGroupUUID: sharingGroupUUID, declaredFiles: declarations)
            
            try syncServer.queue(uploads: uploadables, declaration: testObject)
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    func uploadMultipleImageFiles(sharingGroupUUID: UUID) {
        let catImageFile = ("Cat", "jpg")

        let fileUUID1 = UUID()
        let fileUUID2 = UUID()
        let fileUUID3 = UUID()
        let fileUUID4 = UUID()

        do {
            let declaration1 = FileDeclaration(uuid: fileUUID1, mimeType: MimeType.jpeg, appMetaData: nil, changeResolverName: nil)
            let declaration2 = FileDeclaration(uuid: fileUUID2, mimeType: MimeType.jpeg, appMetaData: nil, changeResolverName: nil)
            let declaration3 = FileDeclaration(uuid: fileUUID3, mimeType: MimeType.jpeg, appMetaData: nil, changeResolverName: nil)
            let declaration4 = FileDeclaration(uuid: fileUUID4, mimeType: MimeType.jpeg, appMetaData: nil, changeResolverName: nil)
            let declarations = Set<FileDeclaration>([declaration1, declaration2, declaration3, declaration4])

            guard let exampleCatImageURL = Bundle.main.url(forResource: catImageFile.0, withExtension: catImageFile.1) else {
                throw ServerInterfaceError.cannotFindFile
            }
        
            let uploadable1 = FileUpload(uuid: fileUUID1, dataSource: .immutable(exampleCatImageURL))
            let uploadable2 = FileUpload(uuid: fileUUID2, dataSource: .immutable(exampleCatImageURL))
            let uploadable3 = FileUpload(uuid: fileUUID3, dataSource: .immutable(exampleCatImageURL))
            let uploadable4 = FileUpload(uuid: fileUUID4, dataSource: .immutable(exampleCatImageURL))
            let uploadables = Set<FileUpload>([uploadable1, uploadable2, uploadable3, uploadable4])
        
            let testObject = ObjectDeclaration(fileGroupUUID: UUID(), objectType: "foo", sharingGroupUUID: sharingGroupUUID, declaredFiles: declarations)
            
            try syncServer.queue(uploads: uploadables, declaration: testObject)
        } catch let error {
            logger.error("\(error)")
        }
    }
}

extension ServerInterface: SyncServerDelegate {
    func error(_ syncServer: SyncServer, error: ErrorEvent) {
        logger.error("\(String(describing: error))")

        switch error {
        case .error:
            break
        case .showAlert(let title, let message):
            Alert.show(withTitle: title, message:message)
        }
    }
    
    func syncCompleted(_ syncServer: SyncServer, result: SyncResult) {
        logger.info("syncCompleted: \(result)")
        
        switch result {
        case .index(sharingGroupUUID: _, index: let fileIndex):
            for file in fileIndex {
                logger.info("\(file)")
            }

        case .noIndex:
            break
        }
    }

    func uuidCollision(_ syncServer: SyncServer, type: UUIDCollisionType, from: UUID, to: UUID) {
    }
    
    // The rest have informative detail; perhaps purely for testing.
    
    func uploadQueue(_ syncServer: SyncServer, event: UploadEvent) {
        logger.info("uploadQueue: \(event)")
    }
    
    func downloadQueue(_ syncServer: SyncServer, event: DownloadEvent) {
        logger.info("downloadQueue: \(event)")
    }

    // Request to server for upload deletion completed successfully.
    func deletionCompleted(_ syncServer: SyncServer) {
        logger.info("deletionCompleted")
    }

    // Called when vN deferred upload(s), or deferred deletions, successfully completed, is/are detected.
    func deferredCompleted(_ syncServer: SyncServer, operation: DeferredOperation, numberCompleted: Int) {
        logger.info("deferredCompleted: \(operation); numberCompleted: \(numberCompleted)")
    }
    
    // Another client deleted a file/file group.
    func downloadDeletion(_ syncServer: SyncServer, details: DownloadDeletion) {
        logger.info("downloadDeletion: \(details)")
    }
}
