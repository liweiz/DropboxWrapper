//
//  Request.swift
//  DropboxWrapper
//
//  Created by Liwei Zhang on 2016-11-28.
//  Copyright © 2016 Liwei Zhang. All rights reserved.
//

import Foundation
import SwiftyDropbox
import RxSwift
//import Alamofire



/// Client and alternative queues to work with API.
public struct DropboxWorker {
    public let client: DropboxClient
    public let dispatchQueues: [DispatchQueue]
}

/// Path to work with API.
public struct Path {
    public let dirPath: String
    public let objName: String
}

/// Request to API.
open class DropboxRequest {
    /// Worker.
    var worker: DropboxWorker!
    public var client: DropboxClient  { return worker!.client }
    public var queues: [DispatchQueue] { return worker!.dispatchQueues }
    /// Path.
    var path: Path!
    public var dirPath: String { return path.dirPath }
    public var objName: String { return path.objName }
    public var fullPath: String { return path.dirPath + (path.dirPath.characters.count == 0 ? "" : "/") + path!.objName }
    public var dirPathUrl: URL? {
        guard let url = URL(string: dirPath) else {
            return nil
        }
        return url
    }
    public var fullPathUrl: URL? {
        guard let url = URL(string: path!.dirPath + "/" + path!.objName) else {
            return nil
        }
        return url
    }
    /// Error handler.
    var errorHandler: ((CustomStringConvertible) -> Void)!
    /// Queue.
    public var queue: DispatchQueue = DispatchQueue.main
}

/// Constructor of DropboxRequest.
public func createDropboxRequest(worker: DropboxWorker, path: Path, errorHandler: @escaping (CustomStringConvertible) -> Void) -> DropboxRequest {
    let req = DropboxRequest()
    req.worker = worker
    req.path = path
    req.errorHandler = errorHandler
    return req
}

// Steps to upload a file:
// 1. Get title name from user input and use as file base name.
// 2. Find out existance of same title name content in file system. Check folder
//    and different versions of the file. If no folder exists, create one.
// 3. Find out the version for the file and combine the title wih the version
//    picked as the file name.
// 4. Upload file.






