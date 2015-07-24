//
//  Future.swift
//  SwiftFutures
//
//  Created by Neil Gall on 22/07/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

// A future value of type Value
// Supports functor-style fmap and flatMap over the contained value.
// Value can be obtained by passing a closure to `get` to be invoked
// once the value is available.
//
public protocol FutureType {
    typealias Value
    var get : (Value -> ()) -> () { get }
}

// A simple FutureType implementation which is used for the return
// type for most combinators.
//
public struct Future<V>: FutureType {
    public typealias Value = V
    public let get: (V -> ()) -> ()
}

extension FutureType {
    // Map f over this future. Returns a new Future with the
    // eventual result of applying f to the value in this future.
    //
    // @param f a function receiving this future's Value
    // @return a new Future containing the result of applying f to
    // this future's eventual value.
    //
    public func fmap<V>(f: Value -> V) -> Future<V> {
        return Future<V>() { getr in self.get { getr(f($0)) } }
    }
    
    // Flat-map f over this future. Returns the result of f
    // when applied to the eventual value in this future.
    //
    // @param f a function receiving this future's Value and returning a future
    // @return the result of applying f to this future's eventual value
    //
    public func flatMap<V, F: FutureType where F.Value == V>(f: Value -> F) -> Future<V> {
        return Future<V>() { getr in self.get { f($0).get { getr($0) } } }
    }
}

// Create a Future from a bare value. This can be used to invoke a
// curried asynchronous function in an applicative style, or for lifting
// a synchronous function to the Future monad.
//
// @param v a value
// @return A Future which will yield v when requested

public func pure<V>(v: V) -> Future<V> {
    return Future() { $0(v) }
}

// Lift a future into the Optional functor. Unlike bare optionals, there
// is no automatic unwrapping of Future optionals, so this is required
// to apply or bind a Future non-optional to a function expecting an
// optional.
//
// @param v a Future value
// @return a Future optional, containing .Some(v)
//
public func lift<V,F:FutureType where F.Value == V>(v: F) -> Future<Optional<V>> {
    return Future() { getOptional in v.get { getOptional(.Some($0)) } }
}

// Lift a future into the Either functor. As per lift for Optionals,
// this may be required to apply or bind a future bare value to a
// function expecting an Either.
//
// @param v a Future value
// @return a Future Either, containing .Value(v)
//
public func lift<E,F:FutureType>(v: F) -> Future<Either<F.Value,E>> {
    return Future() { getEither in v.get { getEither(.Value($0)) } }
}

// Infix version of Future.fmap. (a -> b) -> f a -> f b
//
// @param lhs a simple function dealing in non-futures
// @parma rhs a Future of the input type to lhs
// @return a new Future containing the result of applying lhs to
// rhs's eventual value.
//
infix operator <%> { associativity left }
public func <%> <F:FutureType, R>(lhs: F.Value -> R, rhs: F) -> Future<R> {
    return rhs.fmap(lhs)
}

// Infix applicative apply. f (a -> b) -> f a -> f b
//
// @param lhs A function dealing in non-futures, wrapped in a Future
// @param rhs A future value of the input type to lhs
// @return a new Future containing the result of applying the eventual
// function in lhs to the eventual value in rhs.
//
infix operator <*> { associativity left }
public func <*> <LHS:FutureType, RHS:FutureType, R where LHS.Value == RHS.Value -> R>(lhs: LHS, rhs: RHS) -> Future<R> {
    return Future() { getrhs in rhs.get { a in lhs.get { getrhs($0(a)) } } }
}

// Infix monadic bind between futures. m a -> (a -> m b) -> m b
//
// @param lhs a Future value
// @param rhs a function receiving lhs' Value type and returning a new future
// @return a new Future containing the result of applying rhs to the eventual
// value inside lhs
//
infix operator >>- { associativity left }
public func >>- <LHS:FutureType, RHS:FutureType> (lhs: LHS, rhs: LHS.Value -> RHS) -> Future<RHS.Value> {
    return Future() { getrhs in lhs.get { rhs($0).get(getrhs) } }
}

// Infix monadic bind between futures, discarding the intermediate value. m a -> m b -> m b
//
// @param lhs A future value
// @param rhs A function returning a future value
// @return A new future representing the lhs sequenced before the rhs
//
infix operator >>| { associativity left }
public func >>| <LHS:FutureType, RHS:FutureType> (lhs: LHS, rhs: () -> RHS) -> Future<RHS.Value> {
    return Future() { getrhs in lhs.get { _ in rhs().get(getrhs) } }
}

// Infix end-of-chain binding which breaks out of the monad. m a -> (a -> ()) -> ()
// Yes, not strictly functional but this is Swift not Haskell.
//
// @param lhs a Future value
// @param rhs a closure receiving the value type inside LHS and returning nothing
//
public func >>- <LHS:FutureType> (lhs: LHS, rhs: LHS.Value -> ()) {
    return lhs.get() { value in rhs(value) }
}
