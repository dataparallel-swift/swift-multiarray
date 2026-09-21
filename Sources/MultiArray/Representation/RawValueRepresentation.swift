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

/// A storage representation that preserves the domain constraint of a
/// `RawRepresentable` type while storing its raw value's `Generic` representation.
/// Storage requires `Value.RawValue: Generic` and an `ArrayData` representation;
/// binary snapshots additionally require that representation to be `BinaryArrayData`.
///
/// This allows binary validation to distinguish a constrained raw-value field
/// from an unconstrained scalar without encoding surface-type information.
/// Use it as the representation of a raw-value type to obtain the default
/// `Generic` witnesses:
///
/// ```swift
/// extension Status: Generic {
///     typealias RawRepresentation = RawValueRepresentation<Self>
/// }
/// ```
public struct RawValueRepresentation<Value: RawRepresentable> {
    @usableFromInline
    internal let rawValue: Value.RawValue

    @inlinable
    internal init(unchecked rawValue: Value.RawValue) {
        self.rawValue = rawValue
    }
}

extension Generic where Self: RawRepresentable, RawRepresentation == RawValueRepresentation<Self> {
    @inlinable
    public var rawRepresentation: RawRepresentation {
        RawValueRepresentation(unchecked: self.rawValue)
    }

    @inlinable
    public init(from rep: RawRepresentation) {
        guard let value = Self(rawValue: rep.rawValue) else {
            preconditionFailure("Invalid raw value for \(Self.self): \(rep.rawValue)")
        }
        self = value
    }
}

// Store the raw value's representation; the Value parameter preserves the domain
// constraint for validation without changing the physical layout.
extension RawValueRepresentation: ArrayData where Value.RawValue: Generic, Value.RawValue.RawRepresentation: ArrayData {
    public typealias Buffer = Value.RawValue.RawRepresentation.Buffer

    @inlinable
    public static func initialize(_ arrayData: Buffer, at index: Int, to value: Self) {
        Value.RawValue.RawRepresentation.initialize(arrayData, at: index, to: value.rawValue.rawRepresentation)
    }

    @inlinable
    public static func initialize(_ arrayData: Buffer, from source: Buffer, count: Int) {
        Value.RawValue.RawRepresentation.initialize(arrayData, from: source, count: count)
    }

    @inlinable
    public static func initialize(_ arrayData: Buffer, repeating value: Self, count: Int) {
        Value.RawValue.RawRepresentation.initialize(arrayData, repeating: value.rawValue.rawRepresentation, count: count)
    }

    @inlinable
    public static func deinitialize(_ arrayData: Buffer, count: Int) {
        Value.RawValue.RawRepresentation.deinitialize(arrayData, count: count)
    }

    @inlinable
    public static func read(_ arrayData: Buffer, at index: Int) -> Self {
        RawValueRepresentation(unchecked: Value.RawValue(from: Value.RawValue.RawRepresentation.read(arrayData, at: index)))
    }

    @inlinable
    public static func write(_ arrayData: Buffer, at index: Int, to value: Self) {
        Value.RawValue.RawRepresentation.write(arrayData, at: index, to: value.rawValue.rawRepresentation)
    }

    @inlinable
    public static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Buffer {
        Value.RawValue.RawRepresentation.reserve(capacity: capacity, from: &context)
    }

    @inlinable
    public static func rawSize(capacity: Int, from offset: Int) -> Int? {
        Value.RawValue.RawRepresentation.rawSize(capacity: capacity, from: offset)
    }
}

extension RawValueRepresentation: BinaryArrayData where Value.RawValue: Generic, Value.RawValue.RawRepresentation: BinaryArrayData {
    public static func appendPayload(from storage: Buffer, count: Int, to data: inout Data, offset: inout Int) {
        Value.RawValue.RawRepresentation.appendPayload(from: storage, count: count, to: &data, offset: &offset)
    }

    // Binary tags deliberately describe only the physical representation.
    public static var type: Type { Value.RawValue.RawRepresentation.type }
    public static var typeHead: TypeHead { Value.RawValue.RawRepresentation.typeHead }

    public static func verifyType(in data: Data, at offset: inout Int) throws {
        try Value.RawValue.RawRepresentation.verifyType(in: data, at: &offset)
    }

    public static func appendType(to data: inout Data) {
        Value.RawValue.RawRepresentation.appendType(to: &data)
    }

    public static func firstInvalidElement(in buffer: Buffer, count: Int) -> Int? {
        // Validate before conversion: a custom Generic raw value may require
        // a structurally valid representation to reconstruct safely.
        let invalidRepresentation = Value.RawValue.RawRepresentation.firstInvalidElement(in: buffer, count: count)
        for index in 0 ..< count {
            if index == invalidRepresentation { return index }
            let rawValue = Value.RawValue(from: Value.RawValue.RawRepresentation.read(buffer, at: index))
            if Value(rawValue: rawValue) == nil {
                return index
            }
        }
        return nil
    }
}
