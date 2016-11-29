//
//  ConvertedError.swift
//  DropboxWrapper
//
//  Created by Liwei Zhang on 2016-11-28.
//  Copyright © 2016 Liwei Zhang. All rights reserved.
//

import Foundation
import SwiftyDropbox

/// Recategorized error from API.
public enum ConvertedDropboxError {
    case unknown
    case invalidCursor
    case malformedPath
    case notFound
    case noPermission
    case needDifferentName
    case noSpace
    case lineBusy
}

/// Handle recategorized error.
public func convertedDropboxErrorHander(unknown: @escaping () -> Void,
                                 invalidCursor: @escaping () -> Void,
                                 malformedPath: @escaping () -> Void,
                                 notFound: @escaping () -> Void,
                                 noPermission: @escaping () -> Void,
                                 needDifferentName: @escaping () -> Void,
                                 noSpace: @escaping () -> Void,
                                 lineBusy: @escaping () -> Void) -> (ConvertedDropboxError) -> Void {
    return {
        switch $0 {
        case .unknown:
            unknown()
        case .invalidCursor:
            invalidCursor()
        case .malformedPath:
            malformedPath()
        case .notFound:
            notFound()
        case .noPermission:
            noPermission()
        case .needDifferentName:
            needDifferentName()
        case .noSpace:
            noSpace()
        case .lineBusy:
            lineBusy()
        default:
            print("error not categorized: \($0)")
        }
    }
}

/// Recategorize error.
public func convertDropboxError(from apiError: CustomStringConvertible) -> ConvertedDropboxError {
    switch apiError {
    case let list as Files.ListFolderError:
        switch list {
        case .path(let lookupError):
            /// Get into nested.
            return convertDropboxError(from: lookupError)
        default:
            /// Unknown.
            return .unknown
        }
    case let listC as Files.ListFolderContinueError:
        switch listC {
        case .path(let lookupError):
            /// Get into nested.
            return convertDropboxError(from: lookupError)
        case .reset:
            /// Cursor not valid any more. Restart new listing needed.
            return .invalidCursor
        default:
            /// Unknown.
            return .unknown
        }
    case let lookup as Files.LookupError:
        switch lookup {
        case .malformedPath:
            /// Path alert needed.
            return .malformedPath
        case .notFound:
            /// File/folder to find not found.
            return .notFound
        case .restrictedContent:
            /// Permission alert needed.
            return .noPermission
        default:
            /// Unknown.
            return .unknown
        }
    case let upload as Files.UploadError:
        switch upload {
        case .path(let uploadWriteFailed):
            /// Get into nested.
            return convertDropboxError(from: uploadWriteFailed)
        default:
            /// Unknown.
            return .unknown
        }
    case let createFolder as Files.CreateFolderError:
        switch createFolder {
        case .path(let writeErr):
            /// Get into nested.
            return convertDropboxError(from: writeErr)
        }
    case let write as Files.WriteError:
        switch write {
        case .conflict:
            /// Other operations are undergoing, try later.
            return .lineBusy
        case .disallowedName:
            /// Name change needed.
            return .needDifferentName
        case .noWritePermission:
            /// Permission alert needed.
            return .noPermission
        case .insufficientSpace:
            /// Space alert needed.
            return .noSpace
        case .malformedPath:
            /// Path alert needed.
            return .malformedPath
        default:
            /// Unknown.
            return .unknown
        }
    case let uploadWrite as Files.UploadWriteFailed:
        return convertDropboxError(from: uploadWrite.reason)
    default:
        /// Unknown.
        return .unknown
    }
}
