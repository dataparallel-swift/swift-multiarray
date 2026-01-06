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

protocol Randomizable {
    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self
}

extension Int: Randomizable {}
extension Float32: Randomizable {}

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
