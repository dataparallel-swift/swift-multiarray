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

/// Converts an element to and from an equivalent storage representation.
///
/// Conversions must preserve the logical value. For cross-isolation use, they
/// must not mutate shared state or expose hidden non-sendable state. Derive a
/// conformance with `@Generic`, or compose the supplied representation types.
public protocol Generic {
    /// The representation used to store this value.
    associatedtype RawRepresentation

    /// This value expressed in its storage representation.
    var rawRepresentation: RawRepresentation { get }
    /// Reconstructs a value from a valid storage representation.
    init(from rep: RawRepresentation)
}

extension Generic where RawRepresentation == Self {
    @inlinable
    public var rawRepresentation: RawRepresentation { self }

    @inlinable
    public init(from rep: RawRepresentation) { self = rep }
}

/// Derives `Generic` for a struct or raw-value enum.
///
/// Structs use explicitly typed stored properties and retain their memberwise
/// initializer. Static and computed properties are excluded. Conditional stored
/// properties and declaration-initialized stored `let` properties are unsupported;
/// write a manual conformance or initialize immutable fields in an initializer.
/// Generic constraints belong on the original declaration.
///
/// Enums must have a raw value and no associated values. Nested types must be
/// at least `fileprivate`. Public conversion witnesses are `@inlinable` only when
/// every represented field is public or `@usableFromInline`.
/// See <doc:RepresentingCustomTypes> for examples and declaration limitations.
@attached(extension, conformances: Generic, names: arbitrary)
public macro Generic() = #externalMacro(module: "MultiArrayMacros", type: "GenericExtensionMacro")

/// Wraps a mutable stored property in `Box` while exposing its original type.
///
/// Use this inside an `@Generic` struct when a field's type is not itself
/// `Generic`. The macro creates a `_name: Box<T>` backing field and transparent
/// accessors. Initializers without a property default must initialize that
/// backing field directly. Accessor macros cannot be applied to `let`; use an
/// explicit `Box<T>` property for immutable fields.
@attached(accessor, names: named(get), named(set))
@attached(peer, names: prefixed(_))
public macro Box() = #externalMacro(module: "MultiArrayMacros", type: "BoxPropertyMacro")

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
    public var rawRepresentation: RawRepresentation { RawRepresentation(self) }

    @inlinable
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
    public var rawRepresentation: RawRepresentation { RawRepresentation(self) }

    @inlinable
    public init(from rep: RawRepresentation) {
        self = UInt(rep)
    }
}

extension Bool: Generic {
    public typealias RawRepresentation = UInt8

    @inlinable
    public var rawRepresentation: UInt8 { self ? 1 : 0 }

    @inlinable
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
