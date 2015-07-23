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
    
    private func subtract(a: Int)(_ b: Int) -> Int {
        return a-b
    }
    
    private func asyncAdd(a: Int)(_ b: Int) -> Future<Int> {
        return Future() { get in
            dispatch_async(dispatch_get_main_queue()) {
                get(a+b)
            }
        }
    }

    private func asyncSubtract(a: Int)(_ b: Int) -> Future<Int> {
        return Future() { get in
            dispatch_async(dispatch_get_main_queue()) {
                get(a-b)
            }
        }
    }

    func testFmapAdd() {
        let f = pure(3)
        let g = f.fmap(add(2))
        g.get { v in
            XCTAssertEqual(v, 5)
            self.async?.fulfill()
        }
        wait()
    }

    func testFmapSubtract() {
        let f = pure(2)
        let g = f.fmap(subtract(3))
        g.get { v in
            XCTAssertEqual(v, 1)
            self.async?.fulfill()
        }
        wait()
    }

    func testFlatMapAdd() {
        let f = pure(3)
        let g = f.flatMap(asyncAdd(5))
        g.get { v in
            XCTAssertEqual(v, 8)
            self.async?.fulfill()
        }
        wait()
    }

    func testFlatMapSubtract() {
        let f = pure(3)
        let g = f.flatMap(asyncSubtract(5))
        g.get { v in
            XCTAssertEqual(v, 2)
            self.async?.fulfill()
        }
        wait()
    }

    func testInfixFmapAdd() {
        let f = add(2) <%> pure(6)
        f.get { v in
            XCTAssertEqual(v, 8)
            self.async?.fulfill()
        }
        wait()
    }

    func testInfixFmapSubtract() {
        let f = subtract(6) <%> pure(2)
        f.get { v in
            XCTAssertEqual(v, 4)
            self.async?.fulfill()
        }
        wait()
    }

    func testInfixApplyAdd() {
        let f = pure(add(9)) <*> genuineAsync(7)
        f.get { v in
            XCTAssertEqual(v, 16)
            self.async?.fulfill()
        }
        wait()
    }

    func testInfixApplySubtract() {
        let f = pure(subtract(9)) <*> genuineAsync(7)
        f.get { v in
            XCTAssertEqual(v, 2)
            self.async?.fulfill()
        }
        wait()
    }

    func testApplicativeStyleAdd() {
        let f = add <%> genuineAsync(3) <*> genuineAsync(8)
        f.get { v in
            XCTAssertEqual(v, 11)
            self.async?.fulfill()
        }
        wait()
    }

    func testApplicativeStyleSubtract() {
        let f = subtract <%> genuineAsync(8) <*> genuineAsync(3)
        f.get { v in
            XCTAssertEqual(v, 5)
            self.async?.fulfill()
        }
        wait()
    }

    func testMonadicBindAdd() {
        let f = pure(2) >>- asyncAdd(3)
        f.get { v in
            XCTAssertEqual(v, 5)
            self.async?.fulfill()
        }
        wait()
    }

    func testMonadicBindSubtract() {
        let f = pure(2) >>- asyncSubtract(3)
        f.get { v in
            XCTAssertEqual(v, 1) // 3-2
            self.async?.fulfill()
        }
        wait()
    }

    func testChainedMonadicBindAdd() {
        let f = pure(2) >>- asyncAdd(3) >>- asyncAdd(7)
        f.get { v in
            XCTAssertEqual(v, 12)
            self.async?.fulfill()
        }
        wait()
    }

    func testChainedMonadicBindSubtract() {
        let f = pure(2) >>- asyncSubtract(3) >>- asyncSubtract(7)
        f.get { v in
            XCTAssertEqual(v, 6) // 7-(3-2)
            self.async?.fulfill()
        }
        wait()
    }

    func testMonadicBindWithReduceAdd() {
        let values = [7, 9, 14, 3, 6].map(asyncAdd)
        let f = values.reduce(pure(0), combine: >>-)
        f.get { v in
            XCTAssertEqual(v, 39)
            self.async?.fulfill()
        }
        wait()
    }

    func testMonadicBindWithReduceSubtract() {
        let values = [7, 9, 14, 3, 6].map(asyncSubtract)
        let f = values.reduce(pure(0), combine: >>-)
        f.get { v in
            XCTAssertEqual(v, 15) // 6-(3-(14-(9-(7-0))))
            self.async?.fulfill()
        }
        wait()
    }
}
