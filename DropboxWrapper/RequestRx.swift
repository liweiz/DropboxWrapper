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

/// Wrapper turns API response func to an obverable.
func observableDropboxResponse<Ok, Err, Req>(queue: DispatchQueue? = nil, responsable: AnyDropboxResponsable<Ok, Err, Req>) -> Observable<Ok> {
    return Observable.create { observer in
        responsable.response(queue: queue, completionHandler: {
            switch $0 {
            case (nil, let err?):
                observer.on(.error(err))
            case (let res?, nil):
                observer.on(.next(res))
                observer.on(.completed)
            default:
                print("No info in response.")
            }
        })
        return Disposables.create()
    }
}

/// Rx wrapper for API request.
open class DropboxRequestRx: DropboxRequest {
    open var disposeBag: DisposeBag = DisposeBag()
    public var dirPathUrlRx: URL? {
        get {
            guard let url = URL(string: dirPath) else {
                errorHandlerRx!(Files.LookupError.malformedPath(nil) as! Error)
                return nil
            }
            return url }
    }
    /// Wrapper to meet the error type from Rx.
    public var errorHandlerRx: ((Error) -> Void)? {
        get {
            guard let h = errorHandler else {
                return nil
            }
            return {
                guard let err = $0 as? CustomStringConvertible else {
                    return
                }
                h(err)
            }
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
extension DropboxRequestRx {
    
    /// Upload request.
    
    public typealias OkUp = Files.FileMetadata
    public typealias ErrUp = Files.UploadError
    public typealias OkUpSerializer = Files.FileMetadataSerializer
    public typealias ErrUpSerializer = Files.UploadErrorSerializer
    public typealias ReqUp = UploadRequest<OkUpSerializer, ErrUpSerializer>
    
    public func upload(fileData: Data,
                completionHandler: @escaping (OkUp) -> Void) {
        let request = client.files.upload(path: dirPath, input: fileData)
        let responsable = AnyDropboxResponsable<OkUp, ErrUp, ReqUp>(dropboxResponsable: request.response)
        let observable = observableDropboxResponse(queue: queue, responsable: responsable)
        observable
            .subscribe(onNext: { completionHandler($0) },
                       onError: { self.errorHandlerRx!($0) },
                       onCompleted: { print("upload completed.") })
            .addDisposableTo(disposeBag)
    }
    
    /// List request
    
    public typealias OkLi = Files.ListFolderResult
    public typealias ErrLi = Files.ListFolderError
    public typealias OkLiSerializer = Files.ListFolderResultSerializer
    public typealias ErrLiSerializer = Files.ListFolderErrorSerializer
    public typealias ReqLi = RpcRequest<OkLiSerializer, ErrLiSerializer>
    
    public func listing(all: Bool, doneHandler: @escaping ([OkUp]) -> Void) {
        let request = client.files.listFolder(path: fullPath)
        let responsable = AnyDropboxResponsable<OkLi, ErrLi, ReqLi>(dropboxResponsable: request.response)
        let observable = observableDropboxResponse(queue: queue, responsable: responsable)
        observable
            .subscribe(onNext: {
                guard let initialResults = $0.entries as? [OkUp] else {
                    print("initialListing results type not consistent.")
                    return
                }
                if all && $0.hasMore {
                    self.continueListing(from: $0.cursor,
                                         previousResults: initialResults,
                                         doneHandler: doneHandler)
                } else {
                    doneHandler(initialResults)
                }
                
            },
                       onError: { self.errorHandlerRx!($0) },
                       onCompleted:  { print("initialListing completed.") })
            .addDisposableTo(disposeBag)
    }
    
    public typealias ErrLiCon = Files.ListFolderContinueError
    public typealias ErrLiConSerializer = Files.ListFolderContinueErrorSerializer
    public typealias ReqLiCon = RpcRequest<OkLiSerializer, ErrLiConSerializer>
    
    public func continueListing(from cursor: String,
                         previousResults: [OkUp],
                         doneHandler: @escaping ([OkUp]) -> Void) {
        let request = client.files.listFolderContinue(cursor: cursor)
        let responsable = AnyDropboxResponsable<OkLi, ErrLiCon, ReqLiCon>(dropboxResponsable: request.response)
        let observable = observableDropboxResponse(queue: queue, responsable: responsable)
        observable
            .subscribe(onNext: {
                guard let continuedResults = $0.entries as? [OkUp] else {
                    print("continueListing results type not consistent.")
                    return
                }
                if $0.hasMore {
                    self.continueListing(from: $0.cursor,
                                         previousResults: previousResults + continuedResults,
                                         doneHandler: doneHandler)
                } else {
                    doneHandler(previousResults + continuedResults)
                }
            },
                       onError: { self.errorHandlerRx!($0) },
                       onCompleted:  { print("continueListing completed.") })
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
                       onError: { self.errorHandlerRx!($0) },
                       onCompleted: { print("folderCreation completed.") })
            .addDisposableTo(disposeBag)
    }
}

/// Error handling.
extension DropboxRequestRx {
    
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
        let listingRequest = createDropboxRequestRx(worker: sharedWorker, path: pathAbove, errorHandler: errorHandler!)
        listingRequest.listing(all: false, doneHandler: { _ in
            /// Above level exists.
            let createFolderRequestRx = createDropboxRequestRx(worker: sharedWorker, path: pathAbove, errorHandler: self.errorHandler!)
            createFolderRequestRx.createFolder(completionHandler: { _ in
                doneHandler()
            })
        })
    }
}

///
extension DropboxRequestRx {
    
    func makeSureNoNameConflict(client: DropboxClient,
                                on queue: DispatchQueue? = nil,
                                with name: String,
                                under dir: String,
                                nameConflictHandler: @escaping () -> Void,
                                completionHandler: @escaping ([Files.Metadata]) -> Void,
                                errorHandler: @escaping (Error) -> Void) {
        let q = queue ?? DispatchQueue.main
        listFolderAll(client: client, on: q, path: dir, doneHandler: {
            ($0.map { $0.name }).contains(name) ? nameConflictHandler() : completionHandler($0)
        }, errorHandler: errorHandler)
    }
    
    
    
    
    
    func maxTailingInt(among names: [String], seperator: String) -> Int? {
        guard names.count > 0 else {
            return nil
        }
        let intStrings = names.map { $0.splitInReversedOrder(by: seperator)?.right }
        guard intStrings.contains(where: { $0 == nil }) == false else {
            return nil
        }
        guard intStrings.contains(where: { Int($0!) == nil }) == false else {
            return nil
        }
        let ints = intStrings.map { Int($0!)! }
        return ints.reduce(ints.first!, { max($0, $1) })
    }
}
