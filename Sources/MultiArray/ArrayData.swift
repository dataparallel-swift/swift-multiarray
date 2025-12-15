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

// Storage of datatype-generic values with an underlying struct-of-arrays
// representation. This is intended to be _closed_, as it only operates over the
// fixed set of Generic representation types.
public protocol ArrayData {
    associatedtype Buffer

    static func read(_ arrayData: Buffer, at index: Int) -> Self
    static func write(_ arrayData: Buffer, at index: Int, to value: Self)
    static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Buffer
    static func rawSize(capacity: Int, from offset: Int) -> Int
}

extension ArrayData where Buffer == UnsafeMutablePointer<Self> {
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
extension Int: ArrayData {}
extension Int8: ArrayData {}
extension Int16: ArrayData {}
extension Int32: ArrayData {}
extension Int64: ArrayData {}
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
extension Int128: ArrayData {}
extension UInt: ArrayData {}
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

extension SIMD2: ArrayData {}
extension SIMD3: ArrayData {}
extension SIMD4: ArrayData {}
extension SIMD8: ArrayData {}
extension SIMD16: ArrayData {}
extension SIMD32: ArrayData {}
extension SIMD64: ArrayData {}

public extension FixedWidthInteger {
    typealias Buffer = UnsafeMutablePointer<Self>
}

public extension BinaryFloatingPoint {
    typealias Buffer = UnsafeMutablePointer<Self>
}

public extension SIMD {
    typealias Buffer = UnsafeMutablePointer<Self>
}

// Unit
extension Unit: ArrayData {
    public typealias Buffer = Void

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func read(_: Self.Buffer, at _: Int) -> Self { Unit() }

    @inlinable
    // @_alwaysEmitIntoClient
    public static func write(_: Self.Buffer, at _: Int, to _: Self) { /* no-op */ }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func reserve(capacity _: Int, from _: inout UnsafeMutableRawPointer) -> Self.Buffer { () }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func rawSize(capacity _: Int, from offset: Int) -> Int { offset }
}

// Constant
extension Box: ArrayData {
    public typealias Buffer = UnsafeMutablePointer<Element>

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func read(_ arrayData: Self.Buffer, at index: Int) -> Self {
        Box(arrayData[index])
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func write(_ arrayData: Self.Buffer, at index: Int, to value: Self) {
        (arrayData + index).initialize(to: value.unbox)
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Self.Buffer {
        reserveCapacity(for: Element.self, count: capacity, from: &context)
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func rawSize(capacity: Int, from offset: Int) -> Int {
        getRawSize(for: Element.self, count: capacity, from: offset)
    }
}

// Product
extension Product: ArrayData where A: ArrayData, B: ArrayData {
    public typealias Buffer = (A.Buffer, B.Buffer)

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func read(_ arrayData: Self.Buffer, at index: Int) -> Self {
        .init(
            A.read(arrayData.0, at: index),
            B.read(arrayData.1, at: index)
        )
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func write(_ arrayData: Self.Buffer, at index: Int, to value: Self) {
        A.write(arrayData.0, at: index, to: value._0)
        B.write(arrayData.1, at: index, to: value._1)
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Self.Buffer {
        let aR = A.reserve(capacity: capacity, from: &context)
        let bR = B.reserve(capacity: capacity, from: &context)
        return (aR, bR)
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func rawSize(capacity: Int, from offset: Int) -> Int {
        getRawSize(for: B.self, count: capacity, from: getRawSize(for: A.self, count: capacity, from: offset))
    }
}

// TODO: Sum
//
// Punting this until we have a decent sum-of-product style generic
// representation (which we may then want to invert into a product-of-sum style
// to reuse the underlying storage for the individual fields).

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
    context = end
    return begin.bindMemory(to: type, capacity: count)
}
