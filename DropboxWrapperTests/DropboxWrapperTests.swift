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
    let timeout: TimeInterval = 4.0
    
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
    let randomNumberStringForSingleUploadAndDelete = String(arc4random())
    
    
    func testListFolderRequestRx() {
        // Given
        let path = Path(dirPath: "", objName: "")
        let request = createDropboxRequestRx(worker: worker, path: path, errorHandler: { print("ERROR ListFolder: \($0.description)") })
        let expectation = self.expectation(description: "ListFolder request should succeed: \(request.fullPath)")
        var listed: [DropboxRequestRx.LiResultEntry]?
        
        // When
        request.listFolder(all: false, jobDoneHandler: {
            listed = $0
            print("OK ListFolder: \($0)")
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(listed)
    }
    
    func testContinueListFolderRequestRx() {
        // Given
        let path = Path(dirPath: "/", objName: "testFolderInRootDir-ListAndListContinue")
        let request = createDropboxRequestRx(worker: worker, path: path, errorHandler: { print("ERROR ListFolder: \($0.description)") })
        let expectation = self.expectation(description: "ContinueListFolder request should succeed: \(request.fullPath)")
        var listed: [DropboxRequestRx.LiResultEntry]?
        
        // When
        request.listFolder(all: true, jobDoneHandler: {
            listed = $0
            print("OK ListFolder: \($0)")
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: timeout * 10, handler: nil)
        
        // Then
        XCTAssertNotNil(listed)
    }
    
    func testCreateFolderRequestRx() {
        // Given
        let path = Path(dirPath: "/", objName: "testFolderInRootDir" + "-" + randomNumberStringForSingleUploadAndDelete)
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
        let path = Path(dirPath: "/testFolderInRootDir/", objName: "text_" + randomNumberStringForSingleUploadAndDelete)
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
    
    func testUploadWithProperNameRequest() {
        func uploadOnce() {
            // Given
            let path = Path(dirPath: "/testFolderInRootDir/", objName: "text")
            let toUpload = createATextFile()
            let expectation = self.expectation(description: "createUploadWithProperNameRequest request should succeed: \(path.fullPath)")
            var uploaded: DropboxRequestRx.OkUp?
            let request = createUploadWithProperNameRequest(worker: worker, path: path, versionSeparator: "_", fileData: toUpload!, completionHandler: {
                uploaded = $0
                print("OK UploadWithProperNameRequest: \($0)")
                expectation.fulfill()
            }, errorHandler: { print("ERROR createUploadWithProperNameRequest: \($0.description)") })
            
            // When
            request.uploadWithProperName()
            
            waitForExpectations(timeout: timeout, handler: nil)
            
            // Then
            XCTAssertNotNil(uploaded)
        }
        
//        uploadOnce()
        
        for _ in 0..<4 {
            uploadOnce()
        }
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
    
    func testDeleteRequestRx() {
        // Given
        let pathToDelete = Path(dirPath: "/testFolderInRootDir/", objName: "textToDelete_" + randomNumberStringForSingleUploadAndDelete)
        let request = createDropboxRequestRx(worker: worker, path: pathToDelete, errorHandler: { print("ERROR Delete: \($0.description)") })
        let expectation = self.expectation(description: "Delete request should succeed: \(request.fullPath)")
        var deleted: DropboxRequestRx.LiResultEntry?
        
        // When
        let pathToUpload = Path(dirPath: "/testFolderInRootDir/", objName: "textToDelete_" + randomNumberStringForSingleUploadAndDelete)
        let uploadRequest = createDropboxRequestRx(worker: worker, path: pathToUpload, errorHandler: { print("ERROR Upload: \($0.description)") })
        let uploadExpectation = self.expectation(description: "Upload request should succeed: \(request.fullPath)")
        let toUpload = createATextFile()
        var uploaded: DropboxRequestRx.OkUp?
        
        // When
        uploadRequest.upload(fileData: toUpload!, completionHandler: {
            uploaded = $0
            print("OK Upload: \($0)")
            uploadExpectation.fulfill()
            request.delete(completionHandler: {
                deleted = $0
                print("OK Delete: \($0)")
                expectation.fulfill()
            })
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(uploaded)
        XCTAssertNotNil(deleted)
    }
}
