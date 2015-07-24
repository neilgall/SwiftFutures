//
//  BlockChaining.swift
//  SwiftFutures
//
//  Created by Neil Gall on 23/07/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public class AsyncBlockChain<Result> : FutureType {
    public typealias Value = Result
    
    private var result: Result?
    private var getResult: (Result -> ())?
    
    public var get: (Value -> ()) -> () {
        get { return AsyncBlockChain.getImpl(self) }
    }
    
    public var closure: (Result -> ()) {
        return { result in
            if let get = self.getResult {
                get(result)
                self.getResult = nil
            } else {
                self.result = result
            }
        }
    }
    
    private static func getImpl<V>(c: AsyncBlockChain<V>) -> (V -> ()) -> () {
        return { get in
            if let result = c.result {
                get(result)
                c.result = nil
            } else {
                c.getResult = get
            }
        }
    }
}

public func asyncChain<C>(f: (C -> ()) -> ()) -> AsyncBlockChain<C> {
    let c = AsyncBlockChain<C>()
    f(c.closure)
    return c
}

infix operator >>> { associativity left }
public func >>> <LHS:FutureType, RHS> (lhs: LHS, rhs: (LHS.Value, RHS -> ()) -> ()) -> AsyncBlockChain<RHS> {
    let c = AsyncBlockChain<RHS>()
    lhs.get { lhsValue in
        rhs(lhsValue, c.closure)
    }
    return c
}

public func >>> <LHS:FutureType> (lhs: LHS, rhs: LHS.Value -> ()) {
    lhs.get { lhsValue in
        rhs(lhsValue)
    }
}

infix operator >>| { associativity left }
public func >>| <LHS:FutureType, RHS> (lhs: LHS, rhs: (RHS -> ()) -> ()) -> AsyncBlockChain<RHS> {
    let c = AsyncBlockChain<RHS>()
    lhs.get { _ in
        rhs(c.closure)
    }
    return c
}

public func >>| <LHS:FutureType> (lhs: LHS, rhs: () -> ()) {
    lhs.get { _ in }
}
