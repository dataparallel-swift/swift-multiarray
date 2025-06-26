// Storage of datatype-generic values with an underlying struct-of-arrays
// representation. This is intended to be _closed_, as it only operates over the
// fixed set of Generic representation types.

public protocol ArrayData {
    associatedtype ArrayDataR
    static func allocate(capacity: Int) -> ArrayDataR
    static func deallocate(_ arrayData: ArrayDataR)
    static func readArrayData(_ arrayData: ArrayDataR, index: Int) -> Self
    static func writeArrayData(_ arrayData: ArrayDataR, index: Int, value: Self)
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
extension Float16: ArrayData {}
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
    @inlinable static func allocate(capacity: Int) -> Self.ArrayDataR {
        .allocate(capacity: capacity)
    }
    @inlinable static func deallocate(_ arrayData: Self.ArrayDataR) {
        arrayData.deallocate()
    }
    @inlinable static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        arrayData[index]
    }
    @inlinable static func writeArrayData(_ arrayData: Self.ArrayDataR, index: Int, value: Self) {
        arrayData[index] = value
    }
}

public extension BinaryFloatingPoint {
    typealias ArrayDataR = UnsafeMutablePointer<Self>
    @inlinable static func allocate(capacity: Int) -> Self.ArrayDataR {
        .allocate(capacity: capacity)
    }
    @inlinable static func deallocate(_ arrayData: Self.ArrayDataR) {
        arrayData.deallocate()
    }
    @inlinable static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        arrayData[index]
    }
    @inlinable static func writeArrayData(_ arrayData: Self.ArrayDataR, index: Int, value: Self) {
        arrayData[index] = value
    }
}

public extension SIMD {
    typealias ArrayDataR = UnsafeMutablePointer<Self>
    @inlinable static func allocate(capacity: Int) -> Self.ArrayDataR {
        .allocate(capacity: capacity)
    }
    @inlinable static func deallocate(_ arrayData: Self.ArrayDataR) {
        arrayData.deallocate()
    }
    @inlinable static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        arrayData[index]
    }
    @inlinable static func writeArrayData(_ arrayData: Self.ArrayDataR, index: Int, value: Self) {
        arrayData[index] = value
    }
}

// Unit
extension U: ArrayData {
    public typealias ArrayDataR = U
    @inlinable public static func allocate(capacity: Int) -> Self.ArrayDataR { .init() }
    @inlinable public static func deallocate(_ arrayData: Self.ArrayDataR) { }
    @inlinable public static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self { .init() }
    @inlinable public static func writeArrayData(_ arrayData: Self.ArrayDataR, index: Int, value: Self) { }
}

// Product
extension P: ArrayData where A: ArrayData, B: ArrayData {
    public typealias ArrayDataR = P<A.ArrayDataR, B.ArrayDataR>
    @inlinable public static func allocate(capacity: Int) -> Self.ArrayDataR {
        .init(A.allocate(capacity: capacity),
              B.allocate(capacity: capacity))
    }
    @inlinable public static func deallocate(_ arrayData: Self.ArrayDataR) {
        A.deallocate(arrayData._0)
        B.deallocate(arrayData._1)
    }
    @inlinable public static func readArrayData(_ arrayData: Self.ArrayDataR, index: Int) -> Self {
        .init(A.readArrayData(arrayData._0, index: index),
              B.readArrayData(arrayData._1, index: index))
    }
    @inlinable public static func writeArrayData(_ arrayData: Self.ArrayDataR, index: Int, value: Self) {
        A.writeArrayData(arrayData._0, index: index, value: value._0)
        B.writeArrayData(arrayData._1, index: index, value: value._1)
    }
}

// TODO: Sum
//
// Punting this until we have a decent sum-of-product style generic
// representation (which we man then want to invert into a product-of-sum style
// to reuse the underlying storage for the individual fields).

