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