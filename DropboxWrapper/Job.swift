//
//  Job.swift
//  DropboxWrapper
//
//  Created by Liwei Zhang on 2016-12-01.
//  Copyright © 2016 Liwei Zhang. All rights reserved.
//

import Foundation

//open class DropboxRequestRxJob: DropboxRequestRx {
//    open var versionSeparator: String!
//    var generalErrorHandler: 
//    
//    open func uploadWithProperName(under dirPath: String, for objName: String, fileData: Data, doneHandler: @escaping (DropboxRequestRx.OkUp) -> Void) {
//        let generalErrorHandler = errorHandler!
//        setErrorHandlerToSolveUploadDirNotExist(fileData: fileData, doneHandler: doneHandler)
//        /// Firstly, get the proper version for this upload.
//        findOutProperVersion(under: dirPath, for: objName, by: versionSeparator, doneHandler: {
//            /// Dir path exists.
//            var thisVer: Int = 0
//            if let maxVer = $0 {
//                thisVer = maxVer + 1
//            }
//            let properPath = Path(dirPath: dirPath, objName: objName + self.versionSeparator + String(thisVer))
//            /// Upload with proper version.
//            let uploadRequest = createDropboxRequestRxJob(worker: self.worker, path: properPath, versionSeparator: self.versionSeparator, errorHandler: initialErrorHandler)
//            uploadRequest.upload(fileData: fileData, completionHandler: doneHandler)
//        })
//    }
//    
//    /// Default error to handle upload dir path not exist.
//    /// ListFolder returns error if folder not exist, while upload creates 
//    /// not-previously-existing folders for the path.
//    /// ListFolder is used firstly to find out the proper version number.
//    func setErrorHandlerToSolveUploadDirNotExist(fileData: Data, doneHandler: @escaping (DropboxRequestRx.OkUp) -> Void) {
//        errorHandler = { _ in
//            self.solveUploadDirNotExist(fileData: fileData, doneHandler: doneHandler)
//        }
//    }
//    
//    func findOutProperVersion(under dirPath: String, for objName: String, by separator: String, doneHandler: @escaping (Int?) -> Void) {
//        let path = Path(dirPath: dirPath, objName: objName)
//        let request = createDropboxRequestRx(worker: worker, path: path, errorHandler: errorHandler)
//        request.listFolder(all: true, doneHandler: { doneHandler($0.map { $0.name }.maxTailingInt(by: separator)) })
//    }
//    
//    func solveUploadDirNotExist(fileData: Data, doneHandler: @escaping (DropboxRequestRx.OkUp) -> Void) {
//        let properPath = Path(dirPath: dirPath, objName: objName + versionSeparator + String(0))
//        let request = createDropboxRequestRx(worker: worker, path: properPath, errorHandler: errorHandler)
//        request.upload(fileData: fileData, completionHandler: doneHandler)
//    }
//}
//
///// Constructor of DropboxRequestRxJob.
//public func createDropboxRequestRxJob(worker: DropboxWorker, path: Path, versionSeparator: String, errorHandler: @escaping (CustomStringConvertible) -> Void) -> DropboxRequestRxJob {
//    let req = DropboxRequestRxJob()
//    req.versionSeparator = versionSeparator
//    req.worker = worker
//    req.path = path
//    req.errorHandler = errorHandler
//    return req
//}

