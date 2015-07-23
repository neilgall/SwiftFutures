//
//  CompletionFutureTests.swift
//  SwiftFutures
//
//  Created by Neil Gall on 23/07/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import XCTest

class CompletionFutureTests: XCTestCase {

    var async: XCTestExpectation?
    
    override func setUp() {
        async = expectationWithDescription("expectation")
    }
    
    override func tearDown() {
        async = nil
    }
    
    private func wait() {
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    private func asyncAdd(i: Int)(j: Int) -> Future<Int> {
        return Future<Int>() { get in
            dispatch_async(dispatch_get_main_queue()) {
                get(i+j)
            }
        }
    }
    
    private func subtract(a: Int)(_ b: Int) -> Int {
        return a-b
    }
    
    func testCapturingCompletionBlockWithAsyncDispatch() {
        func async(r: Int, completion: Int -> ()) {
            dispatch_async(dispatch_get_main_queue()) {
                completion(r)
            }
        }
        
        let f = CompletionFuture<Int>()
        async(3, completion: f.closure)
        
        f.get { r in
            XCTAssertEqual(r, 3);
            self.async?.fulfill()
        }
        wait()
    }
    
    func testCapturingCompletionBlockWithSyncDispatch() {
        func sync(r: Int, completion: Int -> ()) {
            completion(r)
        }
        
        let f = CompletionFuture<Int>()
        sync(3, completion: f.closure)
        
        f.get { r in
            XCTAssertEqual(r, 3);
            self.async?.fulfill()
        }
        wait()
    }
    
    private func uncurriedAsyncAdd(a: Int, b: Int, c: Int -> ()) {
        dispatch_async(dispatch_get_main_queue()) {
            c(a+b)
        }
    }
    
    func testCurriedCompletionFuture() {
        let f = future(uncurriedAsyncAdd)(3, 8)
        f.get { v in
            XCTAssertEqual(v, 11)
            self.async?.fulfill()
        }
        wait()
    }
    
    func testApplicativeUseOfCompletionFutures() {
        let f = future(uncurriedAsyncAdd)(6, 9)
        let g = future(uncurriedAsyncAdd)(3, 5)
        
        let r = subtract <%> f <*> g
        r.get { v in
            XCTAssertEqual(v, 7);
            self.async?.fulfill()
        }
        wait()
    }

    func testMonadicUseOfCompletionFutures() {
        let f = liftM(uncurriedAsyncAdd)(6)
        let g = liftM(uncurriedAsyncAdd)(7)
        let h = pure(3) >>- f >>- g >>- asyncAdd(4)
        
        h.get { v in
            XCTAssertEqual(v, 20)
            self.async?.fulfill()
        }
        wait()
    }
}
