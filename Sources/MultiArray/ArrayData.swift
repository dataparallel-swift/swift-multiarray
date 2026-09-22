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

import Foundation

// Storage of datatype-generic values with an underlying struct-of-arrays
// representation. This is intended to be _closed_, as it only operates over the
// fixed set of Generic representation types.
public protocol ArrayData {
    associatedtype Buffer

    static func initialize(_ arrayData: Buffer, at: Int, to value: Self)

    /// Initializes the first `count` elements of an uninitialized destination
    /// from initialized, nonoverlapping source storage. Implementations must
    /// preserve value ownership, including retaining reference-valued fields.
    static func initialize(_ arrayData: Buffer, from: Buffer, count: Int)
    static func initialize(_ arrayData: Buffer, repeating: Self, count: Int)
    static func deinitialize(_ arrayData: Buffer, count: Int)

    static func read(_ arrayData: Buffer, at index: Int) -> Self
    static func write(_ arrayData: Buffer, at index: Int, to value: Self)

    static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Buffer
    static func rawSize(capacity: Int, from offset: Int) -> Int
}

// This instance is intended for values which are trivially copyable without
// references (i.e. machine types)
extension ArrayData where Buffer == UnsafeMutablePointer<Self> {
    @inlinable
    public static func initialize(_ arrayData: Self.Buffer, at index: Int, to value: Self) {
        (arrayData + index).initialize(to: value)
    }

    @inlinable
    public static func initialize(_ destination: Self.Buffer, from source: Self.Buffer, count: Int) {
        // XXX: We could use the following to avoid importing Foundation, and
        // once we reach this pathway it should compile down to the same thing.
        // To statically ensure this we would like to add the BitwiseCopyable
        // constraint, but SIMDStorage is not BitwiseCopyable (even though it
        // really is) so instead of relying on the optimisation to fire just
        // call memcpy directly.
        //
        // > destination.initialize(from: source, count: count)
        memcpy(destination, source, count * MemoryLayout<Self>.stride)
    }

    @inlinable
    public static func initialize(_ arrayData: Self.Buffer, repeating value: Self, count: Int) {
        arrayData.initialize(repeating: value, count: count)
    }

    @inlinable
    public static func deinitialize(_: Self.Buffer, count _: Int) { /* no-op */ }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func read(_ arrayData: Self.Buffer, at index: Int) -> Self {
        arrayData[index]
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func write(_ arrayData: Self.Buffer, at index: Int, to value: Self) {
        arrayData[index] = value
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Self.Buffer {
        reserveCapacity(for: Self.self, count: capacity, from: &context)
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func rawSize(capacity: Int, from offset: Int) -> Int {
        getRawSize(for: Self.self, count: capacity, from: offset)
    }
}

// Primal types
extension Int8: ArrayData {}
extension Int16: ArrayData {}
extension Int32: ArrayData {}
extension Int64: ArrayData {}
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
extension Int128: ArrayData {}
extension UInt8: ArrayData {}
extension UInt16: ArrayData {}
extension UInt32: ArrayData {}
extension UInt64: ArrayData {}
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
extension UInt128: ArrayData {}
#if arch(arm64)
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension Float16: ArrayData {}
#endif
extension Float32: ArrayData {}
extension Float64: ArrayData {}

/// Stores each SIMD vector as one atomic field rather than decomposing its lanes into separate buffers.
extension SIMD2: ArrayData where Scalar: Generic, Scalar.RawRepresentation: ArrayData {}
/// Stores each SIMD vector as one atomic field rather than decomposing its lanes into separate buffers.
extension SIMD3: ArrayData where Scalar: Generic, Scalar.RawRepresentation: ArrayData {}
/// Stores each SIMD vector as one atomic field rather than decomposing its lanes into separate buffers.
extension SIMD4: ArrayData where Scalar: Generic, Scalar.RawRepresentation: ArrayData {}
/// Stores each SIMD vector as one atomic field rather than decomposing its lanes into separate buffers.
extension SIMD8: ArrayData where Scalar: Generic, Scalar.RawRepresentation: ArrayData {}
/// Stores each SIMD vector as one atomic field rather than decomposing its lanes into separate buffers.
extension SIMD16: ArrayData where Scalar: Generic, Scalar.RawRepresentation: ArrayData {}
/// Stores each SIMD vector as one atomic field rather than decomposing its lanes into separate buffers.
extension SIMD32: ArrayData where Scalar: Generic, Scalar.RawRepresentation: ArrayData {}
/// Stores each SIMD vector as one atomic field rather than decomposing its lanes into separate buffers.
extension SIMD64: ArrayData where Scalar: Generic, Scalar.RawRepresentation: ArrayData {}

public extension FixedWidthInteger {
    typealias Buffer = UnsafeMutablePointer<Self>
}

public extension BinaryFloatingPoint {
    typealias Buffer = UnsafeMutablePointer<Self>
}

public extension SIMD {
    typealias Buffer = UnsafeMutablePointer<Self>
}

// Internal helpers
//
// We could also reduce the duplication here if we could treat addresses as Ints
// and not magically unsafe entities to be scared of

// @inlinable
// @inline(__always)
// @_alwaysEmitIntoClient
@usableFromInline
internal func getRawSize<T>(for _: T.Type, count: Int, from offset: Int) -> Int {
    let padding = -offset & (MemoryLayout<T>.alignment - 1)
    let begin = offset + padding
    let end = begin + count * MemoryLayout<T>.stride
    return end
}

// @inlinable
// @inline(__always)
// @_alwaysEmitIntoClient
@usableFromInline
internal func reserveCapacity<T>(for type: T.Type, count: Int, from context: inout UnsafeMutableRawPointer) -> UnsafeMutablePointer<T> {
    let begin = context.alignedUp(for: type)
    let end = begin + count * MemoryLayout<T>.stride
    let pad = begin - context

    // Initialise any gaps between the struct-of-array chunks
    if pad > 0 {
        context.initializeMemory(as: UInt8.self, repeating: 0x00, count: pad)
    }

    context = end
    return begin.bindMemory(to: type, capacity: count)
}
