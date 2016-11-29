//
//  StringHelper.swift
//  NoteBook
//
//  Created by Liwei Zhang on 2016-11-11.
//  Copyright © 2016 Liwei Zhang. All rights reserved.
//

import Foundation

extension String {
    var reversed: String {
        return String(characters.reversed())
    }
    
    /// split splits the string into max 3 parts: the heading part, the string that is used to split and the tailing part. It returns nil if byString is not found.
    func splitInReversedOrder(by aString: String) -> (left: String, right: String)? {
        let reversedSelf = reversed
        let reversedGiven = aString.reversed
        guard let reversedRange = reversedSelf.range(of: reversedGiven) else {
            return nil
        }
        return (reversedSelf[reversedRange.upperBound..<reversedSelf.endIndex].reversed, reversedSelf[reversedSelf.startIndex..<reversedRange.lowerBound].reversed)
    }
}

