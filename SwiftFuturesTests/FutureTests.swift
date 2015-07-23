//
//  FutureTests.swift
//  SwiftFutures
//
//  Created by Neil Gall on 22/07/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import XCTest

class FutureTests: XCTestCase {

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
    
    func testPure() {
        let f = pure(2)
        f.get { v in
            XCTAssertEqual(v, 2)
            self.async?.fulfill()
        }
        wait()
    }
    
    private func genuineAsync(i: Int) -> Future<Int> {
        return Future<Int>() { get in
            dispatch_async(dispatch_get_main_queue()) {
                get(i)
            }
        }
    }
    
    func testGenuineAsync() {
        genuineAsync(5).get { v in
            XCTAssertEqual(v, 5)
            self.async?.fulfill()
        }
        wait()
    }

    func testPureWorksWithFunctions() {
        func add(a: Int, b: Int) -> Int {
            return a+b
        }

        let f = pure(add)
        f.get { v in
            XCTAssertEqual(v(3, b: 8), 11)
            self.async?.fulfill()
        }
        wait()
    }
    
    func testLiftToOptional() {
        let f = pure(2)
        let optf: Future<Int?> = lift(f)
        optf.get { v in
            switch v {
            case .Some(let v): XCTAssertEqual(v, 2)
            case .None: XCTFail()
            }
            self.async?.fulfill()
        }
        wait()
    }
    
    func testLiftToEither() {
        let f = pure(3)
        let eitherf: Future<Either<Int, String>> = lift(f)
        eitherf.get { v in
            switch (v) {
            case .Value(let v): XCTAssertEqual(v, 3)
            case .Error: XCTFail()
            }
            self.async?.fulfill()
        }
        wait()
    }

    private func add(a: Int)(_ b: Int) -> Int {
        return a+b
    }
    
    private func asyncAdd(a: Int)(_ b: Int) -> Future<Int> {
        return Future() { get in
            dispatch_async(dispatch_get_main_queue()) {
                get(a+b)
            }
        }
    }
    
    func testFmap() {
        let f = pure(3)
        let g = f.fmap(add(2))
        g.get { v in
            XCTAssertEqual(v, 5)
            self.async?.fulfill()
        }
        wait()
    }
    
    func testFlatmap() {
        let f = pure(3)
        let g = f.flatMap(asyncAdd(5))
        g.get { v in
            XCTAssertEqual(v, 8)
            self.async?.fulfill()
        }
        wait()
    }
    
    func testInfixFmap() {
        let f = add(2) <%> pure(6)
        f.get { v in
            XCTAssertEqual(v, 8)
            self.async?.fulfill()
        }
        wait()
    }
    
    func testInfixApply() {
        let f = pure(add(9)) <*> genuineAsync(7)
        f.get { v in
            XCTAssertEqual(v, 16)
            self.async?.fulfill()
        }
        wait()
    }
    
    func testApplicativeStyle() {
        let f = add <%> genuineAsync(3) <*> genuineAsync(8)
        f.get { v in
            XCTAssertEqual(v, 11)
            self.async?.fulfill()
        }
        wait()
    }
    
    func testMonadicBind() {
        let f = pure(2) >>- asyncAdd(3)
        f.get { v in
            XCTAssertEqual(v, 5)
            self.async?.fulfill()
        }
        wait()
    }

    func testChainedMonadicBind() {
        let f = pure(2) >>- asyncAdd(3) >>- asyncAdd(7)
        f.get { v in
            XCTAssertEqual(v, 12)
            self.async?.fulfill()
        }
        wait()
    }
    
    func testMonadicBindWithReduce() {
        let values = [7, 9, 14, 3, 6].map(asyncAdd)
        let f = values.reduce(pure(0), combine: >>-)
        f.get { v in
            XCTAssertEqual(v, 39)
            self.async?.fulfill()
        }
        wait()
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
    
    func testApplicativeUseOfCompletionClosures() {
        func async(r: Int, completion: Int -> ()) {
            dispatch_async(dispatch_get_main_queue()) {
                completion(r)
            }
        }
        
        let f = CompletionFuture<Int>()
        let g = CompletionFuture<Int>()

        async(3, completion: f.closure)
        async(6, completion: g.closure)
        
        let r = add <%> f <*> g
        r.get { v in
            XCTAssertEqual(v, 9);
            self.async?.fulfill()
        }
        wait()
    }
}
