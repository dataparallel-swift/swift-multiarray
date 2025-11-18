// Copyright (c) 2025 PassiveLogic, Inc.

protocol Randomizable {
    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self
}

extension Int: Randomizable {}
extension Int16: Randomizable {}
extension Int32: Randomizable {}
extension Int64: Randomizable {}
extension Float32: Randomizable {}
extension Float64: Randomizable {}

extension FixedWidthInteger {
    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self {
        Self.random(in: Self.min ... Self.max, using: &generator)
    }
}

extension BinaryFloatingPoint where RawSignificand: FixedWidthInteger {
    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self {
        Self.random(in: -1 ... 1, using: &generator)
    }
}

func randomArray<R: RandomNumberGenerator, Element: Randomizable>(
    count: Int,
    using generator: inout R
) -> Array<Element> {
    (0 ..< count).map { _ in Element.random(using: &generator) }
}
