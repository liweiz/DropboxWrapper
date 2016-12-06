//
//  DropboxWrapperTests.swift
//  DropboxWrapperTests
//
//  Created by Liwei Zhang on 2016-11-28.
//  Copyright © 2016 Liwei Zhang. All rights reserved.
//

import XCTest
import SwiftyDropbox
@testable import DropboxWrapper

class BaseTestCase: XCTestCase {
    let timeout: TimeInterval = 15.0
    
    var client: DropboxClient!
    var rootDir: String!
    var worker: DropboxWorker!
    
    override func setUp() {
        super.setUp()
        
        client = DropboxClient(accessToken: "_t5sqh9TeTsAAAAAAAAAC-6G9TGzC7PpF-No4bxjPaUVQNXnVVz3ul1Gk4nX6sr6")
        worker = DropboxWorker(client: client, dispatchQueues: [])
    }
    
    func createATextFile() -> Data? {
        let content = "Just for testing."
        return content.data(using: .unicode)
    }
}

class DropboxWrapperTests: BaseTestCase {
    
    
    func testListFolderRequestRx() {
        // Given
        let path = Path(dirPath: "", objName: "")
        let request = createDropboxRequestRx(worker: worker, path: path, errorHandler: { print("ERROR ListFolder: \($0.description)") })
        let expectation = self.expectation(description: "ListFolder request should succeed: \(request.fullPath)")
        var listed: [DropboxRequestRx.LiResultEntry]?
        
        // When
        request.listFolder(all: false, doneHandler: {
            listed = $0
            print("OK ListFolder: \($0)")
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(listed)
    }
    
    func testCreateFolderRequestRx() {
        // Given
        let path = Path(dirPath: "/", objName: "testFolderInRootDir")
        let request = createDropboxRequestRx(worker: worker, path: path, errorHandler: { print("ERROR CreateFolder: \($0.description)") })
        let expectation = self.expectation(description: "CreateFolder request should succeed: \(request.fullPath)")
        var created: DropboxRequestRx.OkCr?
        
        // When
        request.createFolder(completionHandler: {
            created = $0
            print("OK CreateFolder: \($0)")
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(created)
    }
    
    func testUploadRequestRx() {
        // Given
        let path = Path(dirPath: "/testFolderInRootDir/", objName: "text_0")
        let request = createDropboxRequestRx(worker: worker, path: path, errorHandler: { print("ERROR Upload: \($0.description)") })
        let expectation = self.expectation(description: "Upload request should succeed: \(request.fullPath)")
        let toUpload = createATextFile()
        var uploaded: DropboxRequestRx.OkUp?
        
        // When
        request.upload(fileData: toUpload!, completionHandler: {
            uploaded = $0
            print("OK Upload: \($0)")
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(uploaded)
    }
    
    func testDeleteRequestRx() {
        // Given
        let path = Path(dirPath: "/", objName: "testFolderInRootDir")
        let request = createDropboxRequestRx(worker: worker, path: path, errorHandler: { print("ERROR Delete: \($0.description)") })
        let expectation = self.expectation(description: "Delete request should succeed: \(request.fullPath)")
        var deleted: DropboxRequestRx.LiResultEntry?
        
        // When
        request.delete(completionHandler: {
            deleted = $0
            print("OK Delete: \($0)")
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(deleted)
    }
    
    func testStringReversed() {
        // Given
        let aString = "ab cde f ghij"
        // When
        let reversed = aString.reversed
        
        // Then
        XCTAssertEqual(reversed, "jihg f edc ba")
    }
    
    /// String sequence
    func testMaxTailingInt() {
        // Given
        let strings = [
            "a 4",
            "v 1",
            " -5"
        ]
        // When correct split
        let okMax = strings.maxTailingInt(by: " ")
        let nilMax = strings.maxTailingInt(by: "1")
        
        // Then
        XCTAssertEqual(okMax, 4)
        XCTAssertNil(nilMax)
    }
    
    /// String
    func testStringSplitInReversedOrder() {
        // Given
        let aString = "ab cde f ghij"
        // When correct split
        let correctSplit = aString.splitInReversedOrder(by: " ")
        
        // Then
        XCTAssertEqual(correctSplit?.left, "ab cde f")
        XCTAssertEqual(correctSplit?.right, "ghij")
        
        // When not found
        let notFoundSplit = aString.splitInReversedOrder(by: "")
        
        // Then
        XCTAssertNil(notFoundSplit)
    }
    
}
