// Copyright (c) 2025 PassiveLogic, Inc.

// A simple datatype-generic protocol. This protocol is intended to be _open_,
// in that users can add conformance for their own data types.
//
// Datatype-generic functions are based on the idea of converting values of
// datatype `T` into corresponding values of a (nearly) isomorphic type `Rep T`.
// The type `Rep T` is built from a limited set of type constructors, all
// provided by this module. A datatype-generic function is then an overloaded
// function with instances for most of these type constructors, together with a
// wrapper that performs the mapping between `T` and `Rep T`. By using this
// technique, we merely need a few generic instances in order to implement
// functionality that works for any representable type.
//
// Representable types are members of the `Generic` protocol, which defines the
// type `Rep` as well as conversion functions `from` and `to`. Typically, you
// will not define `Generic` instances by hand, but have the `@Generic` macro
// derive them for you.
//
// A true sum-of-products (or rather, product-of-sums) representation would
// probably be better, but this is good enough for now.
public protocol Generic {
    associatedtype Rep
    @inlinable @inline(__always) static func from(_ x: Self) -> Rep
    @inlinable @inline(__always) static func to(_ x: Rep) -> Self
}

@attached(extension, conformances: Generic, names: arbitrary)
public macro Generic() =
    #externalMacro(module: "MultiArrayMacros", type: "GenericExtensionMacro")

// Primal types
extension Int: Generic {}
extension Int8: Generic {}
extension Int16: Generic {}
extension Int32: Generic {}
extension Int64: Generic {}
extension Int128: Generic {}
extension UInt: Generic {}
extension UInt8: Generic {}
extension UInt16: Generic {}
extension UInt32: Generic {}
extension UInt64: Generic {}
extension UInt128: Generic {}
#if arch(arm64)
extension Float16: Generic {}
#endif
extension Float32: Generic {}
extension Float64: Generic {}

extension SIMD2: Generic {}
extension SIMD3: Generic {}
extension SIMD4: Generic {}
extension SIMD8: Generic {}
extension SIMD16: Generic {}
extension SIMD32: Generic {}
extension SIMD64: Generic {}

extension Bool: Generic {
    public typealias Rep = UInt8
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep { x ? 1 : 0 }
    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self { x != 0 }
}

public extension FixedWidthInteger {
    typealias Rep = Self
    @inlinable @inline(__always) static func from(_ x: Self) -> Self.Rep { x }
    @inlinable @inline(__always) static func to(_ x: Self.Rep) -> Self { x }
}

public extension BinaryFloatingPoint {
    typealias Rep = Self
    @inlinable @inline(__always) static func from(_ x: Self) -> Self.Rep { x }
    @inlinable @inline(__always) static func to(_ x: Self.Rep) -> Self { x }
}

public extension SIMD {
    typealias Rep = Self
    @inlinable @inline(__always) static func from(_ x: Self) -> Self.Rep { x }
    @inlinable @inline(__always) static func to(_ x: Self.Rep) -> Self { x }
}

// Unit: constructors without arguments
public struct U {
    @inlinable @inline(__always) init() {}
}

extension U: Generic {
    public typealias Rep = U
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep { x }
    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self { x }
}

// Constant: Encode boxed/constant data (i.e. don't do anything with it; will
// not be encoded into a struct-of-array representation)
public struct K<A> {
    public let unK: A
    @inlinable @inline(__always) public init(_ x: A) {
        self.unK = x
    }
}

extension K: Generic {
    public typealias Rep = Self
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep { x }
    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self { x }
}

// Products: encode multiple arguments to constructors
public struct P<A, B> {
    public let _0: A
    public let _1: B
    @inlinable @inline(__always) public init(_ _0: A, _ _1: B) {
        self._0 = _0
        self._1 = _1
    }
}

extension P: Generic where A: Generic, B: Generic {
    public typealias Rep = P<A.Rep, B.Rep>
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        Self.Rep(A.from(x._0), B.from(x._1))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        Self(A.to(x._0), B.to(x._1))
    }
}

// Sums: encode choice between constructors
//
// TODO: This is just a simply binary sum, which will work but we should really
// make a sum-of-products style representation, so that for the array storage
// it's easier to represent with a single tag array.
public enum S<A, B> {
    case L(A)
    case R(B)
}

extension S: Generic where A: Generic, B: Generic {
    public typealias Rep = S<A.Rep, B.Rep>
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        switch x {
            case let .L(a): .L(A.from(a))
            case let .R(b): .R(B.from(b))
        }
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        switch x {
            case let .L(a): .L(A.to(a))
            case let .R(b): .R(B.to(b))
        }
    }
}
