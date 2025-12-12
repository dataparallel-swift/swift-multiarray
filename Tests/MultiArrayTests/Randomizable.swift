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

import Foundation

protocol Randomizable {
    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self
}

extension Int: Randomizable {}
extension Int8: Randomizable {}
extension Int16: Randomizable {}
extension Int32: Randomizable {}
extension Int64: Randomizable {}
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
extension Int128: Randomizable {}
extension UInt: Randomizable {}
extension UInt8: Randomizable {}
extension UInt16: Randomizable {}
extension UInt32: Randomizable {}
extension UInt64: Randomizable {}
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
extension UInt128: Randomizable {}
#if arch(arm64)
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
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

extension UUID: Randomizable {
    static func random<R: RandomNumberGenerator>(using _: inout R) -> Self {
        UUID() // use internal randomizer
    }
}

func randomArray<R: RandomNumberGenerator, Element: Randomizable>(
    count: Int,
    using generator: inout R
) -> Array<Element> {
    (0 ..< count).map { _ in Element.random(using: &generator) }
}
