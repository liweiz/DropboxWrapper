//
//  Job.swift
//  DropboxWrapper
//
//  Created by Liwei Zhang on 2016-12-01.
//  Copyright © 2016 Liwei Zhang. All rights reserved.
//

import Foundation

open class UploadWithProperNameRequest: DropboxRequestRx {
    open var versionSeparator: String!
    open var fileData: Data!
    open var completionHandler: ((DropboxRequestRx.OkUp) -> Void)!
    open var versionNo = 0
    
    /// uploadWithProperName firstly looks at all file names under target
    /// directory. a) missing folder(s) in directory => upload directly. b)
    /// all names available => calculate the version number and upload with
    /// name containing that number.
    /// Possilble error: upload error/list error
    open func uploadWithProperName() {
        /// Firstly, get the proper version for this upload.
        findOutProperVersion(completionHandler: {
            /// Dir path exists.
            if let maxVer = $0 {
                self.versionNo = maxVer + 1
            }
            self.upload()
        })
    }
    
    func findOutProperVersion(completionHandler: @escaping (Int?) -> Void) {
        let path = Path(dirPath: dirPath, objName: objName)
        let request = createDropboxRequestRx(worker: worker, path: path, errorHandler: handleListError)
        request.listFolder(all: true, jobDoneHandler: { completionHandler($0.map { $0.name }.maxTailingInt(by: self.versionSeparator)) })
    }
    
    func handleListError(err: ErrorRx) {
        switch err {
        case ErrLi.path:
            upload()
        default:
            errorHandler(err)
        }
    }
    
    /// Directory not existing indicates no existing files in target folder.
    /// Simply upload file with name containing first version number. Missing
    /// folder would be created and file would be uploaded.
    func upload() {
        let properPath = Path(dirPath: dirPath, objName: objName + versionSeparator + String(versionNo))
        let request = createDropboxRequestRx(worker: worker, path: properPath, errorHandler: errorHandler)
        request.upload(fileData: fileData, completionHandler: completionHandler)
    }
}

/// Constructor of DropboxRequestRxJob.
public func createUploadWithProperNameRequest(worker: DropboxWorker, path: Path, versionSeparator: String, fileData: Data, completionHandler: @escaping (DropboxRequestRx.OkUp) -> Void, errorHandler: @escaping (ErrorRx) -> Void) -> UploadWithProperNameRequest {
    let req = partiallyCreateUploadWithProperNameRequest(worker: worker, path: path, errorHandler: errorHandler)
    req.versionSeparator = versionSeparator
    req.fileData = fileData
    req.completionHandler = completionHandler
    return req
}

/// Partial constructor of DropboxRequestRxJob to give generic func enough clue.
func partiallyCreateUploadWithProperNameRequest(worker: DropboxWorker, path: Path, errorHandler: @escaping (ErrorRx) -> Void) -> UploadWithProperNameRequest {
    return createDropboxRequestWrapper(worker: worker, path: path, errorHandler: errorHandler)
}


