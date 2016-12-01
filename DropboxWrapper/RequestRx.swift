//
//  RequestRx.swift
//  DropboxWrapper
//
//  Created by Liwei Zhang on 2016-11-28.
//  Copyright © 2016 Liwei Zhang. All rights reserved.
//

import Foundation
import SwiftyDropbox
import RxSwift

/// Rx wrapper for API request.
open class DropboxRequestRx: DropboxRequest {
    open var disposeBag: DisposeBag = DisposeBag()
    public var dirPathUrlRx: URL? {
        guard let url = URL(string: dirPath) else {
            errorHandlerRx(Files.LookupError.malformedPath(nil) as! Error)
            return nil
        }
        return url
    }
    /// Adapter to meet the error type requirement of Rx.
    public var errorHandlerRx: ((Error) -> Void) {
        return {
            guard let err = $0 as? CustomStringConvertible else {
                return
            }
            self.errorHandler(err)
        }
    }
}

/// Constructor of DropboxRequestRx.
public func createDropboxRequestRx(worker: DropboxWorker, path: Path, errorHandler: @escaping (CustomStringConvertible) -> Void) -> DropboxRequestRx {
    let req = DropboxRequestRx()
    req.worker = worker
    req.path = path
    req.errorHandler = errorHandler
    return req
}

/// Requests.
protocol RequestMakable {
    associatedtype ResultA
    associatedtype ResultB
    associatedtype ResultC
    func upload(fileData: Data, completionHandler: @escaping (ResultA) -> Void)
    func listFolder(all: Bool, doneHandler: @escaping ([ResultB]) -> Void)
    func continueListFolder(from cursor: String, previousResults: [ResultB], doneHandler: @escaping ([ResultB]) -> Void)
    func createFolder(completionHandler: @escaping (ResultC) -> Void)
}

extension DropboxRequestRx : RequestMakable {
    
    /// Upload request.
    public typealias OkUp = Files.FileMetadata
    public typealias ErrUp = Files.UploadError
    public typealias OkUpSerializer = Files.FileMetadataSerializer
    public typealias ErrUpSerializer = Files.UploadErrorSerializer
    public typealias ReqUp = UploadRequest<OkUpSerializer, ErrUpSerializer>
    
    public func upload(fileData: Data, completionHandler: @escaping (OkUp) -> Void) {
        let request = client.files.upload(path: fullPath, input: fileData)
        let responsable = AnyDropboxResponsable<OkUp, ErrUp, ReqUp>(dropboxResponsable: request.response)
        let observable = observableDropboxResponse(queue: queue, responsable: responsable)
        observable
            .subscribe(onNext: { completionHandler($0) },
                       onError: { self.errorHandlerRx($0) },
                       onCompleted: { print("COMPLETED upload.") })
            .addDisposableTo(disposeBag)
    }
    
    /// List request
    public typealias OkLi = Files.ListFolderResult
    public typealias ErrLi = Files.ListFolderError
    public typealias OkLiSerializer = Files.ListFolderResultSerializer
    public typealias ErrLiSerializer = Files.ListFolderErrorSerializer
    public typealias ReqLi = RpcRequest<OkLiSerializer, ErrLiSerializer>
    public typealias LiResultEntry = Files.Metadata
    
    /// Initial listing request.
    public func listFolder(all: Bool, doneHandler: @escaping ([LiResultEntry]) -> Void) {
        let request = client.files.listFolder(path: fullPath)
        let responsable = AnyDropboxResponsable<OkLi, ErrLi, ReqLi>(dropboxResponsable: request.response)
        let observable = observableDropboxResponse(queue: queue, responsable: responsable)
        observable
            .subscribe(onNext: {
                if all && $0.hasMore {
                    self.continueListFolder(from: $0.cursor,
                                         previousResults: $0.entries,
                                         doneHandler: doneHandler)
                } else {
                    doneHandler($0.entries)
                }
                
            },
                       onError: { self.errorHandlerRx($0) },
                       onCompleted:  { print("COMPLETED listFolder") })
            .addDisposableTo(disposeBag)
    }
    
    public typealias ErrLiCon = Files.ListFolderContinueError
    public typealias ErrLiConSerializer = Files.ListFolderContinueErrorSerializer
    public typealias ReqLiCon = RpcRequest<OkLiSerializer, ErrLiConSerializer>
    
    /// Continued listing request.
    public func continueListFolder(from cursor: String, previousResults: [LiResultEntry], doneHandler: @escaping ([LiResultEntry]) -> Void) {
        let request = client.files.listFolderContinue(cursor: cursor)
        let responsable = AnyDropboxResponsable<OkLi, ErrLiCon, ReqLiCon>(dropboxResponsable: request.response)
        let observable = observableDropboxResponse(queue: queue, responsable: responsable)
        observable
            .subscribe(onNext: {
                if $0.hasMore {
                    self.continueListFolder(from: $0.cursor,
                                         previousResults: previousResults + $0.entries,
                                         doneHandler: doneHandler)
                } else {
                    doneHandler(previousResults + $0.entries)
                }
            },
                       onError: { self.errorHandlerRx($0) },
                       onCompleted:  { print("COMPLETED continueListFolder.") })
            .addDisposableTo(disposeBag)
    }
    
    /// Create folder.
    public typealias OkCr = Files.FolderMetadata
    public typealias ErrCr = Files.CreateFolderError
    public typealias OkCrSerializer = Files.FolderMetadataSerializer
    public typealias ErrCrSerializer = Files.CreateFolderErrorSerializer
    public typealias ReqCr = RpcRequest<OkCrSerializer, ErrCrSerializer>
    
    public func createFolder(completionHandler: @escaping (OkCr) -> Void) {
        let request = client.files.createFolder(path: fullPath)
        let responsable = AnyDropboxResponsable<OkCr, ErrCr, ReqCr>(dropboxResponsable: request.response)
        let observable = observableDropboxResponse(queue: queue, responsable: responsable)
        observable
            .subscribe(onNext: { completionHandler($0) },
                       onError: { self.errorHandlerRx($0) },
                       onCompleted: { print("COMPLETED folderCreation.") })
            .addDisposableTo(disposeBag)
    }
    
    /// Delete.
    public typealias OkDeSerializer = Files.MetadataSerializer
    public typealias ErrDeSerializer = Files.DeleteErrorSerializer
    public typealias ReqDe = RpcRequest<OkDeSerializer, ErrDeSerializer>
    public typealias ErrDe = Files.DeleteError
    
    public func delete(completionHandler: @escaping (LiResultEntry) -> Void) {
        let request = client.files.delete(path: fullPath)
        let responsable = AnyDropboxResponsable<LiResultEntry, ErrDe, ReqDe>(dropboxResponsable: request.response)
        let observable = observableDropboxResponse(queue: queue, responsable: responsable)
        observable
            .subscribe(onNext: { completionHandler($0) },
                       onError: { self.errorHandlerRx($0) },
                       onCompleted: { print("COMPLETED delete.") })
            .addDisposableTo(disposeBag)
    }
}

/// Error handling.
protocol DirPathErrorHandlable {
    func handleDirPathError(doneHandler: @escaping () -> Void)
}

extension DropboxRequestRx : DirPathErrorHandlable {
    
    /// Check and create dir path when needed.
    /// Always check path one level above, since path the process only triggered
    /// when the level operated on comes across path errors.
    public func handleDirPathError(doneHandler: @escaping () -> Void) {
        guard let urlDir = URL(string: dirPath) else {
            errorHandler!(Files.LookupError.malformedPath(nil))
            return
        }
        let objNameAbove = urlDir.lastPathComponent
        let dirPathAbove = urlDir.deletingLastPathComponent().absoluteString
        let pathAbove = Path(dirPath: dirPathAbove, objName: objNameAbove)
        let sharedWorker = DropboxWorker(client: client, dispatchQueues: queues)
        let listFolderRequest = createDropboxRequestRx(worker: sharedWorker, path: pathAbove, errorHandler: errorHandler!)
        listFolderRequest.listFolder(all: false, doneHandler: { _ in
            /// Above level exists.
            let createFolderRequestRx = createDropboxRequestRx(worker: sharedWorker, path: pathAbove, errorHandler: self.errorHandler!)
            createFolderRequestRx.createFolder(completionHandler: { _ in
                doneHandler()
            })
        })
    }
}


