//
//  TypeErasedResponseFunc.swift
//  DropboxWrapper
//
//  Created by Liwei Zhang on 2016-11-28.
//  Copyright © 2016 Liwei Zhang. All rights reserved.
//

import Foundation
import SwiftyDropbox

/// Generic type for API response.
protocol DropboxResponsable {
    associatedtype Ok
    associatedtype Err
    associatedtype Req
    func response(queue: DispatchQueue?, completionHandler: @escaping (Ok?, CallError<Err>?) -> Void) -> Req
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
