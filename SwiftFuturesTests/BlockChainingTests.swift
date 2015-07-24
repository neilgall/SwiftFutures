//
//  BlockChainingTests.swift
//  SwiftFutures
//
//  Created by Neil Gall on 23/07/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import XCTest

class BlockChainingTests: XCTestCase {
    
    var async: XCTestExpectation?
    
    override func setUp() {
        async = expectationWithDescription("expectation")
    }
    
    override func tearDown() {
        async = nil
    }
    
    private func wait() {
        waitForExpectationsWithTimeout(1000, handler: nil)
    }
    
    func testCurriedSubtract() {
        let a = asyncSubtract(5)
        a(j: 20) { c in
            XCTAssertEqual(c, 15)
            self.async?.fulfill()
        }
        wait()
    }

    func testAsyncBlockChainWithAsyncDispatch() {
        func async(r: Int, completion: Int -> ()) {
            dispatch_async(dispatch_get_main_queue()) {
                completion(r)
            }
        }
        
        let f = AsyncBlockChain<Int>()
        async(3, completion: f.closure)
        
        f.get { r in
            XCTAssertEqual(r, 3);
            self.async?.fulfill()
        }
        wait()
    }
    
    func testAsyncBlockChainWithSyncDispatch() {
        func sync(r: Int, completion: Int -> ()) {
            completion(r)
        }
        
        let f = AsyncBlockChain<Int>()
        sync(3, completion: f.closure)
        
        f.get { r in
            XCTAssertEqual(r, 3);
            self.async?.fulfill()
        }
        wait()
    }
    
    func testAsyncBlockChainPassingCompletionValuesCommutative() {
        asyncChain(asyncInt(2)) >>> asyncAdd(7) >>> asyncAdd(9) >>> { sum in
            XCTAssertEqual(sum, 18);
            self.async?.fulfill()
        }
        
        wait()
    }

    func testAsyncBlockChainPassingCompletionValuesNonCommutative() {
        asyncChain(asyncInt(22)) >>> asyncSubtract(7) >>> asyncSubtract(9) >>> { result in
            XCTAssertEqual(result, 6);
            self.async?.fulfill()
        }
        
        wait()
    }
}

func asyncInt(r: Int)(completion: Int -> ()) {
    dispatch_async(dispatch_get_main_queue()) {
        completion(r)
    }
}

func asyncAdd(i: Int)(j: Int, c: Int -> ()) {
    dispatch_async(dispatch_get_main_queue()) {
        c(i+j)
    }
}

func asyncSubtract(i: Int)(j: Int, c: Int -> ()) {
    dispatch_async(dispatch_get_main_queue()) {
        c(j-i)
    }
}

