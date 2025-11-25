// Copyright (c) 2025 PassiveLogic, Inc.

protocol Randomizable {
    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self
}

extension Int: Randomizable {}
extension Int8: Randomizable {}
extension Int16: Randomizable {}
extension Int32: Randomizable {}
extension Int64: Randomizable {}
extension Int128: Randomizable {}
extension UInt: Randomizable {}
extension UInt8: Randomizable {}
extension UInt16: Randomizable {}
extension UInt32: Randomizable {}
extension UInt64: Randomizable {}
extension UInt128: Randomizable {}
#if arch(arm64)
extension Float16: Randomizable {}
#endif
extension Float32: Randomizable {}
extension Float64: Randomizable {}

extension FixedWidthInteger {
    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self {
        Self.random(in: Self.min ... Self.max, using: &generator)
    }
}

extension BinaryFloatingPoint where RawSignificand: FixedWidthInteger {
    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self {
        Self.random(in: 0 ... 1, using: &generator)
    }
}

extension SIMD2: Randomizable where Scalar: Randomizable {
    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self {
        Self(
            Scalar.random(using: &generator),
            Scalar.random(using: &generator)
        )
    }
}

extension SIMD3: Randomizable where Scalar: Randomizable {
    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self {
        Self(
            Scalar.random(using: &generator),
            Scalar.random(using: &generator),
            Scalar.random(using: &generator)
        )
    }
}

extension Bool: Randomizable {
    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self {
        UInt.random(using: &generator) % 2 == 0
    }
}

func randomArray<R: RandomNumberGenerator, Element: Randomizable>(
    count: Int,
    using generator: inout R
) -> Array<Element> {
    (0 ..< count).map { _ in Element.random(using: &generator) }
}
