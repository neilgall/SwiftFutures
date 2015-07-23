//
//  CompletionFuture.swift
//  SwiftFutures
//
//  Created by Neil Gall on 23/07/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public class CompletionFuture<Result> : FutureType {
    public typealias Value = Result
    
    private var result: Result?
    private var getResult: (Result -> ())?
    
    public var get: (Value -> ()) -> () {
        get { return CompletionFuture.getImpl(self) }
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
    
    private static func getImpl<V>(c: CompletionFuture<V>) -> (V -> ()) -> () {
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

public func future<C>(f: (C -> ()) -> ()) -> CompletionFuture<C> {
    let c = CompletionFuture<C>()
    f(c.closure)
    return c
}

public func future<A0,C>(f: (A0, C -> ()) -> ())(_ a0: A0) -> CompletionFuture<C> {
    let c = CompletionFuture<C>()
    f(a0, c.closure)
    return c
}

public func future<A0,A1,C>(f: (A0, A1, C -> ()) -> ())(_ a0: A0, _ a1: A1) -> CompletionFuture<C> {
    let c = CompletionFuture<C>()
    f(a0, a1, c.closure)
    return c
}

public func future<A0,A1,A2,C>(f: (A0, A1, A2, C -> ()) -> ())(_ a0: A0, _ a1: A1, _ a2: A2) -> CompletionFuture<C> {
    let c = CompletionFuture<C>()
    f(a0, a1, a2, c.closure)
    return c
}

public func future<A0,A1,A2,A3,C>(f: (A0, A1, A2, A3, C -> ()) -> ())(_ a0: A0, _ a1: A1, _ a2: A2, _ a3: A3) -> CompletionFuture<C> {
    let c = CompletionFuture<C>()
    f(a0, a1, a2, a3, c.closure)
    return c
}

public func future<A0,A1,A2,A3,A4,C>(f: (A0, A1, A2, A3, A4, C -> ()) -> ())(_ a0: A0, _ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4) -> CompletionFuture<C> {
    let c = CompletionFuture<C>()
    f(a0, a1, a2, a3, a4, c.closure)
    return c
}

public func liftM<A0,C>(f: (A0, C -> ()) -> ()) -> (A0 -> CompletionFuture<C>) {
    let c = CompletionFuture<C>()
    return { a0 in f(a0, c.closure); return c }
}

public func liftM<A0,A1,C>(f: (A0, A1, C -> ()) -> ()) -> (A0 -> A1 -> CompletionFuture<C>) {
    let c = CompletionFuture<C>()
    return { a0 in { a1 in f(a0, a1, c.closure); return c } }
}

