// Storage of datatype-generic values with an underlying struct-of-arrays
// representation. This is intended to be _closed_, as it only operates over the
// fixed set of Generic representation types.

public protocol ArrayData {
    associatedtype ArrayDataR
    static func allocate(capacity: Int, context: inout UnsafeMutableRawPointer) -> ArrayDataR
    static func deallocate(_ arrayData: ArrayDataR, capacity: Int, context: inout UnsafeMutableRawPointer)
    static func readArrayData(_ arrayData: ArrayDataR, index: Int) -> Self
    static func writeArrayData(_ arrayData: inout ArrayDataR, index: Int, value: Self)
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
    @inlinable static func allocate(capacity: Int, context: inout UnsafeMutableRawPointer) -> Self.ArrayDataR {
        .allocate(capacity: capacity)
    }
    @inlinable static func deallocate(_ arrayData: Self.ArrayDataR, capacity: Int, context: inout UnsafeMutableRawPointer) {
        arrayData.deallocate()
    }
    @inlinable static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        arrayData[index]
    }
    @inlinable static func writeArrayData(_ arrayData: inout Self.ArrayDataR, index: Int, value: Self) {
        arrayData[index] = value
    }
}

public extension BinaryFloatingPoint {
    typealias ArrayDataR = UnsafeMutablePointer<Self>
    @inlinable static func allocate(capacity: Int, context: inout UnsafeMutableRawPointer) -> Self.ArrayDataR {
        .allocate(capacity: capacity)
    }
    @inlinable static func deallocate(_ arrayData: Self.ArrayDataR, capacity: Int, context: inout UnsafeMutableRawPointer) {
        arrayData.deallocate()
    }
    @inlinable static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        arrayData[index]
    }
    @inlinable static func writeArrayData(_ arrayData: inout Self.ArrayDataR, index: Int, value: Self) {
        arrayData[index] = value
    }
}

public extension SIMD {
    typealias ArrayDataR = UnsafeMutablePointer<Self>
    @inlinable static func allocate(capacity: Int, context: inout UnsafeMutableRawPointer) -> Self.ArrayDataR {
        .allocate(capacity: capacity)
    }
    @inlinable static func deallocate(_ arrayData: Self.ArrayDataR, capacity: Int, context: inout UnsafeMutableRawPointer) {
        arrayData.deallocate()
    }
    @inlinable static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        arrayData[index]
    }
    @inlinable static func writeArrayData(_ arrayData: inout Self.ArrayDataR, index: Int, value: Self) {
        arrayData[index] = value
    }
}

// Unit
extension U: ArrayData {
    public typealias ArrayDataR = ()
    @inlinable public static func allocate(capacity: Int, context: inout UnsafeMutableRawPointer) -> Self.ArrayDataR { () }
    @inlinable public static func deallocate(_ arrayData: Self.ArrayDataR, capacity: Int, context: inout UnsafeMutableRawPointer) { }
    @inlinable public static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self { .init() }
    @inlinable public static func writeArrayData(_ arrayData: inout Self.ArrayDataR, index: Int, value: Self) { }
}

// Constant
extension K: ArrayData {
    // Is this safe for reference types? Otherwise we should use a regular array
    // as the backing storage. For reference types maybe we need to combine this
    // with Unmanaged?
    public typealias ArrayDataR = UnsafeMutableBufferPointer<A>
    @inlinable public static func allocate(capacity: Int, context: inout UnsafeMutableRawPointer) -> Self.ArrayDataR {
        .allocate(capacity: capacity)
    }
    @inlinable public static func deallocate(_ arrayData: Self.ArrayDataR, capacity: Int, context: inout UnsafeMutableRawPointer) {
        arrayData.deallocate()
    }
    @inlinable public static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        K(arrayData[index])
    }
    @inlinable public static func writeArrayData(_ arrayData: inout Self.ArrayDataR, index: Int, value: Self) {
        arrayData.initializeElement(at: index, to: value.unK)
    }
}

// Product
extension P: ArrayData where A: ArrayData, B: ArrayData {
    public typealias ArrayDataR = (A.ArrayDataR, B.ArrayDataR)
    @inlinable public static func allocate(capacity: Int, context: inout UnsafeMutableRawPointer) -> Self.ArrayDataR {
        (A.allocate(capacity: capacity, context: &context),
         B.allocate(capacity: capacity, context: &context))
    }
    @inlinable public static func deallocate(_ arrayData: Self.ArrayDataR, capacity: Int, context: inout UnsafeMutableRawPointer) {
        A.deallocate(arrayData.0, capacity: capacity, context: &context)
        B.deallocate(arrayData.1, capacity: capacity, context: &context)
    }
    @inlinable public static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        .init(A.readArrayData(arrayData.0, index: index),
              B.readArrayData(arrayData.1, index: index))
    }
    @inlinable public static func writeArrayData(_ arrayData: inout Self.ArrayDataR, index: Int, value: Self) {
        A.writeArrayData(&arrayData.0, index: index, value: value._0)
        B.writeArrayData(&arrayData.1, index: index, value: value._1)
    }
}

// TODO: Sum
//
// Punting this until we have a decent sum-of-product style generic
// representation (which we may then want to invert into a product-of-sum style
// to reuse the underlying storage for the individual fields).

