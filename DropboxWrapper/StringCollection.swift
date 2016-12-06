//
//  StringCollection.swift
//  DropboxWrapper
//
//  Created by Liwei Zhang on 2016-12-01.
//  Copyright © 2016 Liwei Zhang. All rights reserved.
//

import Foundation

extension Collection where Self.Iterator.Element == String {
    /// Returns max Int for all given strings' tailing parts separated by separator.
    func maxTailingInt(by separator: String) -> Int? {
        guard count > 0 else {
            return nil
        }
        let intStrings = map { $0.splitInReversedOrder(by: separator)?.right }
        guard !intStrings.contains(where: {
            switch $0 {
            case nil:
                return true
            case _ as Int:
                return true
            default:
                return false
            }
        }) else {
            return nil
        }
        return intStrings.map { Int($0!)! }.max()
    }
}
