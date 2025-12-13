// Copyright (c) 2025 The swift-multiarray authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
// type `RawRepresentation` as well as conversion functions `from` and `to`.
// Typically, you will not define `Generic` instances by hand, but have the
// `@Generic` macro derive them for you.
//
// A true sum-of-products (or rather, product-of-sums) representation would
// probably be better, but this is good enough for now.
public protocol Generic {
    associatedtype RawRepresentation

    var rawRepresentation: RawRepresentation { get }
    init(from rep: RawRepresentation)
}

extension Generic where RawRepresentation == Self {
    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self { self }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) { self = rep }
}

@attached(extension, conformances: Generic, names: arbitrary)
public macro Generic() = #externalMacro(module: "MultiArrayMacros", type: "GenericExtensionMacro")

// Primal types
extension Int: Generic {}
extension Int8: Generic {}
extension Int16: Generic {}
extension Int32: Generic {}
extension Int64: Generic {}
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
extension Int128: Generic {}
extension UInt: Generic {}
extension UInt8: Generic {}
extension UInt16: Generic {}
extension UInt32: Generic {}
extension UInt64: Generic {}
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
extension UInt128: Generic {}
#if arch(arm64)
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
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
    public typealias RawRepresentation = UInt8

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: UInt8 { self ? 1 : 0 }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = rep != 0
    }
}

public extension FixedWidthInteger {
    typealias RawRepresentation = Self
}

public extension BinaryFloatingPoint {
    typealias RawRepresentation = Self
}

public extension SIMD {
    typealias RawRepresentation = Self
}

// Unit: constructors without arguments
public struct Unit {
    @inlinable
    @_alwaysEmitIntoClient
    init() {}
}

extension Unit: Generic {
    public typealias RawRepresentation = Self
}

// Constant: Encode boxed/constant data (i.e. don't do anything with it; will
// not be encoded into a struct-of-array representation)
public struct Box<Element> {
    public let unbox: Element

    @inlinable
    @_alwaysEmitIntoClient
    public init(_ value: Element) {
        self.unbox = value
    }
}

extension Box: Generic {
    public typealias RawRepresentation = Self
}

// Products: encode multiple arguments to constructors
public struct Product<A, B> {
    public let _0: A
    public let _1: B

    @inlinable
    @_alwaysEmitIntoClient
    public init(_ lhs: A, _ rhs: B) {
        self._0 = lhs
        self._1 = rhs
    }
}

extension Product: Generic where A: Generic, B: Generic {
    public typealias RawRepresentation = Product<A.RawRepresentation, B.RawRepresentation>

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Product<A.RawRepresentation, B.RawRepresentation> {
        .init(self._0.rawRepresentation, self._1.rawRepresentation)
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = Product(
            A(from: rep._0),
            B(from: rep._1)
        )
    }
}

// Sums: encode choice between constructors
//
// TODO: This is just a simply binary sum, which will work but we should really
// make a sum-of-products style representation, so that for the array storage
// it's easier to represent with a single tag array.
public enum Sum<A, B> {
    case lhs(A)
    case rhs(B)
}

extension Sum: Generic where A: Generic, B: Generic {
    public typealias RawRepresentation = Sum<A.RawRepresentation, B.RawRepresentation>

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Sum<A.RawRepresentation, B.RawRepresentation> {
        switch self {
            case let .lhs(left): .lhs(left.rawRepresentation)
            case let .rhs(right): .rhs(right.rawRepresentation)
        }
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = switch rep {
            case let .lhs(left): .lhs(A(from: left))
            case let .rhs(right): .rhs(B(from: right))
        }
    }
}
