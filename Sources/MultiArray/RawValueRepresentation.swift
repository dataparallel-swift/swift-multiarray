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

// Store only the raw value; the Value parameter preserves the domain
// constraint for validation without changing the physical layout.
extension RawValueRepresentation: ArrayData where Value.RawValue: ArrayData {
    public typealias Buffer = Value.RawValue.Buffer

    @inlinable
    public static func initialize(_ arrayData: Buffer, at index: Int, to value: Self) {
        Value.RawValue.initialize(arrayData, at: index, to: value.rawValue)
    }

    @inlinable
    public static func initialize(_ arrayData: Buffer, from source: Buffer, count: Int) {
        Value.RawValue.initialize(arrayData, from: source, count: count)
    }

    @inlinable
    public static func initialize(_ arrayData: Buffer, repeating value: Self, count: Int) {
        Value.RawValue.initialize(arrayData, repeating: value.rawValue, count: count)
    }

    @inlinable
    public static func deinitialize(_ arrayData: Buffer, count: Int) {
        Value.RawValue.deinitialize(arrayData, count: count)
    }

    @inlinable
    public static func read(_ arrayData: Buffer, at index: Int) -> Self {
        RawValueRepresentation(unchecked: Value.RawValue.read(arrayData, at: index))
    }

    @inlinable
    public static func write(_ arrayData: Buffer, at index: Int, to value: Self) {
        Value.RawValue.write(arrayData, at: index, to: value.rawValue)
    }

    @inlinable
    public static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Buffer {
        Value.RawValue.reserve(capacity: capacity, from: &context)
    }

    @inlinable
    public static func rawSize(capacity: Int, from offset: Int) -> Int {
        Value.RawValue.rawSize(capacity: capacity, from: offset)
    }
}

extension RawValueRepresentation: BinaryArrayData where Value.RawValue: BinaryArrayData {
    // Binary tags deliberately describe only the physical representation.
    public static var type: Type { Value.RawValue.type }
    public static var typeHead: TypeHead { Value.RawValue.typeHead }

    public static func verifyType(in data: Data, at offset: inout Int) throws {
        try Value.RawValue.verifyType(in: data, at: &offset)
    }

    public static func appendType(to data: inout Data) {
        Value.RawValue.appendType(to: &data)
    }

    public static func firstInvalidElement(in buffer: Buffer, count: Int) -> Int? {
        for index in 0 ..< count {
            let rawValue = Value.RawValue.read(buffer, at: index)
            if Value(rawValue: rawValue) == nil {
                return index
            }
        }
        return nil
    }
}
