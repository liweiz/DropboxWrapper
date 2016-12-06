//
//  TypeErasedResponseFunc.swift
//  DropboxWrapper
//
//  Created by Liwei Zhang on 2016-11-28.
//  Copyright © 2016 Liwei Zhang. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyDropbox

/// Protocol for API response func.
protocol DropboxResponsable {
    associatedtype Ok
    associatedtype Err
    associatedtype Req
    func response(queue: DispatchQueue?, completionHandler: @escaping (Ok?, CallError<Err>?) -> Void) -> Req
}

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

/// To meet the rx's Swift.Error requirement for onError.
extension CallError : Error {}

/// Type-erased wrapper for Dropbox API response.
struct AnyDropboxResponsable<K, E, Q> : DropboxResponsable {
    typealias Ok = K
    typealias Err = E
    typealias Req = Q
    
    typealias ResponseHandler = (DispatchQueue?, @escaping (Ok?, CallError<Err>?) -> Void) -> Req
    
    let dropboxResponsable: ResponseHandler
    
    @discardableResult
    func response(queue: DispatchQueue?, completionHandler: @escaping (Ok?, CallError<Err>?) -> Void) -> Req {
        return self.dropboxResponsable(queue, completionHandler)
    }
}
