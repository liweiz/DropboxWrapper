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
    let timeout: TimeInterval = 30.0
    
    var client: DropboxClient!
    var rootDir: String!
    var worker: DropboxWorker!
    
    override func setUp() {
        super.setUp()
        
        client = DropboxClient(accessToken: "_t5sqh9TeTsAAAAAAAAACVRFDVY8aEGcbAGonfnNuhh5ine_r1uMRAjJK4_a_3XX")
        rootDir = "https://www.dropbox.com"
        worker = DropboxWorker(client: client, dispatchQueues: [])
    }
    
}

class DropboxWrapperTests: BaseTestCase {
    
    
    func testListingRequestRx() {
        // Given
        let path = Path(dirPath: "", objName: "")
        let request = createDropboxRequestRx(worker: worker, path: path, errorHandler: { print("ERROR Listing: \($0.description)") })
        let expectation = self.expectation(description: "Listing request should succeed: \(request.fullPath)")
        var listed: [DropboxRequestRx.LiResultEntry]?
        print("1")
        
        // When
        request.listing(all: false, doneHandler: {
            listed = $0
            print("OK Listing: \($0)")
            expectation.fulfill()
        })
        print("2")
        
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
        print("1")
        
        // When
        request.createFolder(completionHandler: {
            created = $0
            print("OK Listing: \($0)")
            expectation.fulfill()
        })
        print("2")
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertNotNil(created)
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
