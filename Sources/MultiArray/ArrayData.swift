// Copyright (c) 2025 PassiveLogic, Inc.

// Storage of datatype-generic values with an underlying struct-of-arrays
// representation. This is intended to be _closed_, as it only operates over the
// fixed set of Generic representation types.
public protocol ArrayData {
    associatedtype ArrayDataR
    static func readArrayData(_ arrayData: ArrayDataR, index: Int) -> Self
    static func writeArrayData(_ arrayData: inout ArrayDataR, index: Int, value: Self)

    static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> ArrayDataR
    static func rawSize(capacity: Int, from offset: Int) -> Int
}

// Primal types
extension Int: ArrayData {}
extension Int8: ArrayData {}
extension Int16: ArrayData {}
extension Int32: ArrayData {}
extension Int64: ArrayData {}
extension Int128: ArrayData {}
extension UInt: ArrayData {}
extension UInt8: ArrayData {}
extension UInt16: ArrayData {}
extension UInt32: ArrayData {}
extension UInt64: ArrayData {}
extension UInt128: ArrayData {}
#if arch(arm64)
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
    typealias ArrayDataR = UnsafeMutablePointer<Self>
    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        arrayData[index]
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    static func writeArrayData(_ arrayData: inout Self.ArrayDataR, index: Int, value: Self) {
        arrayData[index] = value
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Self.ArrayDataR {
        reserveCapacity(for: Self.self, count: capacity, from: &context)
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    static func rawSize(capacity: Int, from offset: Int) -> Int {
        getRawSize(for: Self.self, count: capacity, from: offset)
    }
}

public extension BinaryFloatingPoint {
    typealias ArrayDataR = UnsafeMutablePointer<Self>
    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        arrayData[index]
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    static func writeArrayData(_ arrayData: inout Self.ArrayDataR, index: Int, value: Self) {
        arrayData[index] = value
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Self.ArrayDataR {
        reserveCapacity(for: Self.self, count: capacity, from: &context)
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    static func rawSize(capacity: Int, from offset: Int) -> Int {
        getRawSize(for: Self.self, count: capacity, from: offset)
    }
}

public extension SIMD {
    typealias ArrayDataR = UnsafeMutablePointer<Self>
    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        arrayData[index]
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    static func writeArrayData(_ arrayData: inout Self.ArrayDataR, index: Int, value: Self) {
        arrayData[index] = value
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Self.ArrayDataR {
        reserveCapacity(for: Self.self, count: capacity, from: &context)
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    static func rawSize(capacity: Int, from offset: Int) -> Int {
        getRawSize(for: Self.self, count: capacity, from: offset)
    }
}

// Unit
extension U: ArrayData {
    public typealias ArrayDataR = Void
    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func readArrayData(_: Self.ArrayDataR, index _: Int) -> Self { .init() }
    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func writeArrayData(_: inout Self.ArrayDataR, index _: Int, value _: Self) {}
    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func reserve(capacity _: Int, from _: inout UnsafeMutableRawPointer) -> Self.ArrayDataR { () }
    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func rawSize(capacity _: Int, from offset: Int) -> Int { offset }
}

// Constant
extension K: ArrayData {
    // // Using a full Array here seems wasteful; surely we can do better by
    // // stuffing values into a buffer? See also Unmanaged.
    // public typealias ArrayDataR = Array<A>
    // @inlinable
    // // @inline(__always)
    // // @_alwaysEmitIntoClient
    // public static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
    //     K(arrayData[index])
    // }
    // @inlinable
    // // @inline(__always)
    // // @_alwaysEmitIntoClient
    // public static func writeArrayData(_ arrayData: inout Self.ArrayDataR, index: Int, value: Self) {
    //     arrayData.withUnsafeMutableBufferPointer{ buffer in
    //         buffer.initializeElement(at: index, to: value.unK)
    //     }
    // }

    // @inlinable
    // // @inline(__always)
    // // @_alwaysEmitIntoClient
    // public static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Self.ArrayDataR {
    //     .init(unsafeUninitializedCapacity: capacity, initializingWith: { buffer, initializedCount in
    //         initializedCount = capacity
    //     })
    // }
    // @inlinable
    // // @inline(__always)
    // // @_alwaysEmitIntoClient
    // public static func rawSize(capacity: Int, from offset: Int) -> Int { offset }

    public typealias ArrayDataR = UnsafeMutablePointer<A>
    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        K(arrayData[index])
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func writeArrayData(_ arrayData: inout Self.ArrayDataR, index: Int, value: Self) {
        (arrayData + index).initialize(to: value.unK)
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Self.ArrayDataR {
        reserveCapacity(for: A.self, count: capacity, from: &context)
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func rawSize(capacity: Int, from offset: Int) -> Int {
        getRawSize(for: A.self, count: capacity, from: offset)
    }
}

// Product
extension Product: ArrayData where A: ArrayData, B: ArrayData {
    public typealias ArrayDataR = (A.ArrayDataR, B.ArrayDataR)
    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        .init(
            A.readArrayData(arrayData.0, index: index),
            B.readArrayData(arrayData.1, index: index)
        )
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func writeArrayData(_ arrayData: inout Self.ArrayDataR, index: Int, value: Self) {
        A.writeArrayData(&arrayData.0, index: index, value: value._0)
        B.writeArrayData(&arrayData.1, index: index, value: value._1)
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Self.ArrayDataR {
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
@usableFromInline
// @inlinable
// @inline(__always)
// @_alwaysEmitIntoClient
internal func getRawSize<T>(for _: T.Type, count: Int, from offset: Int) -> Int {
    let padding = -offset & (MemoryLayout<T>.alignment - 1)
    let begin = offset + padding
    let end = begin + count * MemoryLayout<T>.stride
    return end
}

@usableFromInline
// @inlinable
// @inline(__always)
// @_alwaysEmitIntoClient
internal func reserveCapacity<T>(for type: T.Type, count: Int, from context: inout UnsafeMutableRawPointer) -> UnsafeMutablePointer<T> {
    let begin = context.alignedUp(for: type)
    let end = begin + count * MemoryLayout<T>.stride
    context = end
    return begin.bindMemory(to: type, capacity: count)
}
