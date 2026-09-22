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

// Unit: constructors without arguments and no in-memory representation.
public struct Unit {
    @inlinable
    public init() {}
}

extension Unit: Sendable {}

extension Unit: Generic {
    public typealias RawRepresentation = Self
}

extension Unit: ArrayData {
    public typealias Buffer = Void

    @inlinable
    public static func initialize(_: Self.Buffer, at _: Int, to _: Self) { /* no-op */ }

    @inlinable
    public static func initialize(_: Self.Buffer, from _: Self.Buffer, count _: Int) { /* no-op */ }

    @inlinable
    public static func initialize(_: Self.Buffer, repeating _: Self, count _: Int) { /* no-op */ }

    @inlinable
    public static func deinitialize(_: Self.Buffer, count _: Int) { /* no-op */ }

    @inlinable
    public static func read(_: Self.Buffer, at _: Int) -> Self { Unit() }

    @inlinable
    public static func write(_: Self.Buffer, at _: Int, to _: Self) { /* no-op */ }

    @inlinable
    public static func reserve(capacity _: Int, from _: inout UnsafeMutableRawPointer) -> Self.Buffer { () }

    @inlinable
    public static func rawSize(capacity _: Int, from offset: Int) -> Int { offset }
}

extension Unit: BinaryArrayData {
    public static var type: Type { .unit }
    public static var typeHead: TypeHead { .unit }

    public static func verifyType(in data: Data, at offset: inout Int) throws {
        try verifyByte(expecting: Self.typeHead.rawValue, in: data, at: &offset)
    }

    public static func appendType(to data: inout Data) {
        data.append(Self.typeHead.rawValue)
    }
}
