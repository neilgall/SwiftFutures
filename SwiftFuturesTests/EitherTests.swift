//
//  EitherTests.swift
//  SwiftFutures
//
//  Created by Neil Gall on 22/07/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import XCTest

class EitherTests: XCTestCase {

    func testValue() {
        let e: Either<Int,String> = .Value(2)
        switch e {
        case .Value(let v): XCTAssert(v == 2)
        case .Error: XCTFail()
        }
    }
    
    func testError() {
        let e: Either<Int, String> = .Error("bad")
        switch e {
        case .Value: XCTFail()
        case .Error(let e): XCTAssertEqual(e, "bad")
        }
    }
    
    func testValueFmap() {
        let e: Either<Int, String> = .Value(2)
        let f = e.fmap { $0 + 2 }
        switch f {
        case .Value(let v): XCTAssertEqual(v, 4)
        case .Error: XCTFail()
        }
    }
    
    func testErrorFmap() {
        let e: Either<Int, String> = .Error("bad fmap")
        let f = e.fmap { $0 + 2 }
        switch f {
        case .Value: XCTFail()
        case .Error(let e): XCTAssertEqual(e, "bad fmap")
        }
    }
    
    func addIfEven(v: Int)(w: Int) -> Either<Int, String> {
        if v % 2 == 0 {
            return .Value(v + w)
        } else {
            return .Error("not even")
        }
    }
    
    func testValueFlatMap() {
        let e: Either<Int, String> = .Value(6)
        let f = e.flatMap(addIfEven(4))
        switch f {
        case .Value(let v): XCTAssertEqual(v, 10)
        case .Error: XCTFail()
        }
    }
    
    func testErrorFlatMap() {
        let e: Either<Int, String> = .Error("bad flatmap")
        let f = e.flatMap(addIfEven(4))
        switch f {
        case .Value: XCTFail()
        case .Error(let e): XCTAssertEqual(e, "bad flatmap")
        }
    }
    
    func testErrorFromFunctionFlatMap() {
        let e: Either<Int, String> = .Value(6)
        let f = e.flatMap(addIfEven(3))
        switch f {
        case .Value: XCTFail()
        case .Error(let e): XCTAssertEqual(e, "not even")
        }
    }
}
