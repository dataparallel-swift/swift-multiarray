// Copyright (c) 2026 The swift-multiarray authors. All rights reserved.
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
    public var rawRepresentation: RawRepresentation { self }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) { self = rep }
}

/// A storage representation that preserves the domain constraint of a
/// `RawRepresentable` type while using its raw value as the physical layout.
///
/// This allows binary validation to distinguish a constrained raw-value field
/// from an unconstrained scalar without encoding surface-type information.
/// Use it as the representation of a raw-value type to obtain the default
/// `Generic` witnesses:
///
/// ```swift
/// extension Status: Generic {
///     typealias RawRepresentation = RawValueRepresentation<Self>
/// }
/// ```
public struct RawValueRepresentation<Value: RawRepresentable> {
    @usableFromInline
    internal let rawValue: Value.RawValue

    @inlinable
    internal init(unchecked rawValue: Value.RawValue) {
        self.rawValue = rawValue
    }
}

extension Generic where Self: RawRepresentable, RawRepresentation == RawValueRepresentation<Self> {
    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: RawRepresentation {
        RawValueRepresentation(unchecked: self.rawValue)
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        guard let value = Self(rawValue: rep.rawValue) else {
            preconditionFailure("Invalid raw value for \(Self.self): \(rep.rawValue)")
        }
        self = value
    }
}

/// Derives `Generic` for a struct.
///
/// Stored properties must have explicit type annotations. For generic structs,
/// put the `Generic` constraints on the struct declaration itself. The complete
/// conformance is emitted in an extension so the struct retains its synthesized
/// memberwise initializer. Public conversion witnesses are `@inlinable` only
/// when every encoded field is public or usable from inline code. A nested type
/// cannot be `private` because its generated conformance extension is
/// file-scoped; use `fileprivate` instead.
@attached(extension, conformances: Generic, names: arbitrary)
public macro Generic() = #externalMacro(module: "MultiArrayMacros", type: "GenericExtensionMacro")

// Primal, fixed size types
extension Int8: Generic {}
extension Int16: Generic {}
extension Int32: Generic {}
extension Int64: Generic {}
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
extension Int128: Generic {}
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

// Primal, platform dependent sized types
extension Int: Generic {
    #if arch(x86_64) || arch(arm64)
    public typealias RawRepresentation = Int64
    #else
    public typealias RawRepresentation = Int32
    #endif

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: RawRepresentation { RawRepresentation(self) }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = Int(rep)
    }
}

extension UInt: Generic {
    #if arch(x86_64) || arch(arm64)
    public typealias RawRepresentation = UInt64
    #else
    public typealias RawRepresentation = UInt32
    #endif

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: RawRepresentation { RawRepresentation(self) }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = UInt(rep)
    }
}

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

public extension SIMD where Scalar: Generic {
    typealias RawRepresentation = Self
}

// Unit: constructors without arguments
public struct Unit {
    @inlinable
    @_alwaysEmitIntoClient
    public init() {}
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

extension Box: Equatable where Element: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.unbox == rhs.unbox }
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
