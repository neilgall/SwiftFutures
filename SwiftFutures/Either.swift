//
//  Either.swift
//  SwiftFutures
//
//  Created by Neil Gall on 22/07/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

// Either enumeration
// 
// Can hold either a .Value of ValueType or a .Error of ErrorType.
// Supports fmap() over a function returning some other value and
// flatMap() over a function returning another Either.
//
public enum Either<ValueType, ErrorType> {
    case Value(ValueType)
    case Error(ErrorType)
  
    // Map f over this either.
    // if .Value then returns f(value) wrapped in a new Either
    // if .Error then returns the error wrapped in the new Either type
    //
    public func fmap<R>(f: ValueType -> R) -> Either<R, ErrorType> {
        switch self {
        case Value(let v): return .Value(f(v))
        case Error(let e): return .Error(e)
        }
    }
    
    // Flat-map f over this either
    // if .Value then returns f(value)
    // if .Error then returns the eror wrapped in the new Either type
    //
    public func flatMap<R>(f: ValueType -> Either<R, ErrorType>) -> Either<R, ErrorType> {
        switch self {
        case Value(let v): return f(v)
        case Error(let e): return .Error(e)
        }
    }
}
