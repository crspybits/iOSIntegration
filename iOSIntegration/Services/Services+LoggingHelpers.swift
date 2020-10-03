//
//  Services+LoggingHelpers.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 10/3/20.
//

import Foundation
import Logging
import FileLogging
import iOSShared

extension Services {
    func getDocumentsDirectory() throws -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard paths.count > 0 else {
            throw ServicesError.noDocumentDirectory
        }
        
        return paths[0]
    }
    
    func logFileURL() throws -> URL {
        return try getDocumentsDirectory().appendingPathComponent(logFileName)
    }
    
    // Subsequent uses of the `logger` will log both to a file and the Xcode console.
    // Only call this once, during app launch.
    func setupLogging() throws {
        let loggingURL = try logFileURL()

        LoggingSystem.bootstrap { label in
            var handlers = [LogHandler]()
            
            if let logFileHandler = try? FileLogHandler(label: label, localFile: loggingURL) {
                handlers += [logFileHandler]
                logger.info("Also logging to file: \(loggingURL)")
            }
            else {
                logger.error("Could not open: \(loggingURL)")
            }
            
            handlers += [StreamLogHandler.standardOutput(label: label)]

            return MultiplexLogHandler(handlers)
        }
    }
    
    var currentLogFileContents: String? {
        guard let url = try? logFileURL() else {
            logger.error("Could not get log file URL")
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else {
            logger.error("Could not read data from log file URL: \(url)")
            return nil
        }
        
        guard let logString = String(data: data, encoding: .utf8) else {
            logger.error("Could not convert log data to a string")
            return nil
        }
        
        return logString
    }
}
