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
    
    func wait() {
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
    
    func testGenuineAsync() {
        let f = Future<Int>() { get in
            dispatch_async(dispatch_get_main_queue()) {
                get(5)
            }
        }
        f.get { v in
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

    func add(a: Int)(_ b: Int) -> Int {
        return a+b
    }
    
    func asyncAdd(a: Int)(_ b: Int) -> Future<Int> {
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
}
