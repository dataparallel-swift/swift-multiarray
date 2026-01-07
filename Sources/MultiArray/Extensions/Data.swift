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

extension MultiArray where Element.RawRepresentation: BinaryArrayData {
    /// Dump the given array into a Data buffer.
    ///
    /// This is statically restricted to types which we can encode fully in the
    /// struct-of-array representation (i.e. no internal pointers, no internal
    /// padding, etc.) and so serialisation and deserialisation are able to
    /// efficiently copy the underlying buffer in one go. Note that this means
    /// we do not do any endian conversion: you will get an error if you try to
    /// decode the buffer on a machine with a different endianess than which it
    /// was encoded. Thus, this is more a "memory snapshot" rather than a
    /// serialised encoding, because the layout of the data in the buffer is
    /// dependent on the host machine, library internals, etc. etc.. Still,
    /// that's what enables it to be fast, for when you know what you are doing.
    /// Caveat emptor. If this makes you anxious or you need a stable wire
    /// format, consider using the Codable instances instead, e.g.:
    ///
    /// > let encoded = try JSONEncoder().encode(array) // slow as all hell
    ///
    /// Rather than this method:
    ///
    /// > let encoded = array.encode() // footguns!
    ///
    /// Caveats aside, examples this functionality is useful for include:
    ///  - cache snapshots
    ///  - same-machine IPC
    ///  - (temporary) persistent storage where you control both ends
    ///
    /// This encoding is only guaranteed to round-trip within the same major
    /// version of this library, on ABI-compatible platforms.
    ///
    /// Currently this does not checksum the payload, but that could be added as
    /// an optional addition.
    ///
    /// The format of the underlying data is:
    ///
    ///   Bytes   Description
    ///         ┌──────────────
    ///   0...3 │ magic (0x4d415252)
    ///       4 │ encoding version
    ///       5 │ flags
    ///   6...7 │ reserved
    ///  8...15 │ array count
    /// 16...17 │ size of type encoding (t)
    ///   18... │ type encoding
    ///         ┆
    /// 18+t... │ payload
    ///         ┆
    ///         └──────────────
    ///
    public func encode() -> Data {
        let magic: UInt32 = 0x4D_41_52_52 // MARR swiftformat:disable:this numberFormatting
        let version: UInt8 = 1
        let headerSize = 18
        let typeSize = Element.RawRepresentation.type.encodedSize()
        let payloadSize = Element.RawRepresentation.rawSize(capacity: self.count, from: 0)
        var data = Data(capacity: headerSize + typeSize + payloadSize)

        // Header (18 bytes)
        data.append(UInt32(magic))
        data.append(UInt8(version))
        data.append(UInt8(0)) // flags
        data.append(UInt16(0)) // reserved
        data.append(UInt64(self.count))
        data.append(UInt16(typeSize))

        // Type encoding (typeSize bytes)
        Element.RawRepresentation.appendType(to: &data)

        // Payload (payloadSize bytes)
        data.append(self.arrayData.context.assumingMemoryBound(to: UInt8.self), count: payloadSize)

        return data
    }

    /// Create an array from a Data dump.
    ///
    /// Note that this copies the data into a freshly allocated MultiArray. If
    /// you need (or want) a zero-copy implementation please contact us on
    /// GitHub to signal your interest!
    ///
    public init(data: Data) throws {
        // Constants for this version
        let expectedMagic: UInt32 = 0x4D_41_52_52 // MARR swiftformat:disable:this numberFormatting
        let expectedVersion: UInt8 = 1
        let headerSize = 18

        // Check we have at least a complete header (based on the expected type)
        let expectedTypeSize = Element.RawRepresentation.type.encodedSize()
        guard data.count >= headerSize + expectedTypeSize else {
            throw BinaryMultiArrayError.truncated(index: 0, required: headerSize + expectedTypeSize, total: data.count)
        }

        // Start decoding the header
        let magic: UInt32 = try data.load(fromByteOffset: 0)
        if magic == expectedMagic.byteSwapped { throw BinaryMultiArrayError.endianMismatch }
        if magic != expectedMagic { throw BinaryMultiArrayError.badMagic }

        let version: UInt8 = try data.load(fromByteOffset: 4)
        guard version == expectedVersion else { throw BinaryMultiArrayError.unsupportedVersion(Int(version)) }

        _ = try data.load(fromByteOffset: 5) as UInt8 // flags
        _ = try data.load(fromByteOffset: 6) as UInt16 // reserved

        let count64: UInt64 = try data.load(fromByteOffset: 8)
        guard count64 <= UInt64(Int.max) else { throw BinaryMultiArrayError.overflow(count64) }
        let count = Int(count64)

        // Ensure we have the correct number of bytes
        let expectedByteCount = Element.RawRepresentation.rawSize(capacity: count, from: 0)
        let expectedSize = headerSize + expectedTypeSize + expectedByteCount
        guard data.count == expectedSize else {
            throw BinaryMultiArrayError.sizeMismatch(expected: expectedSize, actual: data.count)
        }

        // Decode the (variable sized) type tag
        let typeSize16: UInt16 = try data.load(fromByteOffset: 16)
        let typeSize = Int(typeSize16)
        var offset = headerSize
        try Element.RawRepresentation.verifyType(in: data, at: &offset)
        guard offset == 18 + typeSize else {
            throw BinaryMultiArrayError.malformedType(expected: typeSize, actual: offset - 18)
        }

        // Header verification is complete.
        // Allocate the buffer for the payload and memcpy dirctly into it.
        self.arrayData = .init(unsafeUninitializedCapacity: count)
        data.withUnsafeBytes {
            // This force unwrap is safe because we've already accessed the
            // underlying Data pointer many times before this point, so it can
            // not possibly be nil.
            self.arrayData.context.copyMemory(from: $0.baseAddress! + offset, byteCount: expectedByteCount)
        }
    }
}

public enum BinaryMultiArrayError: Error, Equatable, CustomStringConvertible {
    case badMagic
    case endianMismatch
    case overflow(UInt64)
    case unsupportedVersion(Int)
    case truncated(index: Int, required: Int, total: Int)
    case sizeMismatch(expected: Int, actual: Int)
    case typeMismatch(expected: UInt8, actual: UInt8)
    case malformedType(expected: Int, actual: Int)

    public var description: String {
        switch self {
            case .badMagic:
                "Incorrect magic value. Are you sure this is MultiArray data?"
            case .endianMismatch:
                "Attempt to load data that was produced on a machine of different endian-ness. This is not supported."
            case let .overflow(value):
                "Encoded value overflowed available Int range: \(value)"
            case let .unsupportedVersion(version):
                "Unknown or unsupported encoding version: \(version)"
            case let .truncated(index, required, total):
                "Ran out of data at index \(index): required \(required) bytes but only \(total - index) remain"
            case let .sizeMismatch(expected, actual):
                "Size mismatch: expected \(expected) bytes but found \(actual) instead"
            case let .typeMismatch(expected, actual):
                String(
                    format: "Type tag mismatch: expected 0x%x (%@) but found 0x%x (%@)",
                    expected,
                    TypeHead(rawValue: expected)?.description ?? "invalid",
                    actual,
                    TypeHead(rawValue: actual)?.description ?? "invalid"
                )
            case let .malformedType(expected, actual):
                "Incomplete type encoding: expected \(expected) bytes but consumed \(actual)"
        }
    }
}

extension Data {
    @inlinable
    mutating func append<T: FixedWidthInteger>(_ value: T) {
        var value = value
        Swift.withUnsafeBytes(of: &value) { self.append($0.assumingMemoryBound(to: T.self)) }
    }

    @inlinable
    func load<T: FixedWidthInteger>(fromByteOffset offset: Int) throws -> T {
        let required = MemoryLayout<T>.size
        guard offset + required <= self.count else {
            throw BinaryMultiArrayError.truncated(index: offset, required: required, total: self.count)
        }
        return self.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: T.self) }
    }
}

// The subset of ArrayData types that are safe to serialise as raw bytes. By
// "safe" we mean:
//  - no heap pointers / references embedded in the representation. This is
//    enforced by not providing a conformance to the Box escape hatch.
//  - the representation's byte layout is fully determined by the type.
//  - data written is deterministic, padding bytes included. This is true even
//    for structure types due to the aforementioned exclusion of Box, thus there
//    is no way to encode types that might include internal padding.
//
public protocol BinaryArrayData: ArrayData {
    static var type: Type { get }
    static var typeHead: TypeHead { get }

    // Match and consume this type's encoding from `data[index...]`. On success
    // the index will point to the start of the payload section.
    static func verifyType(in data: Data, at offset: inout Int) throws

    // Append the type tag into the Data buffer
    static func appendType(to data: inout Data)
}

extension BinaryArrayData {
    static func verifyByte(expecting: UInt8, in data: Data, at offset: inout Int) throws {
        guard offset < data.count else {
            throw BinaryMultiArrayError.truncated(index: offset, required: 1, total: data.count)
        }
        let found = data[offset]
        guard expecting == found else {
            throw BinaryMultiArrayError.typeMismatch(expected: expecting, actual: found)
        }
        offset += 1
    }
}

extension BinaryArrayData where Self: SignedInteger {
    public static var type: Type {
        .int(bits: UInt8(MemoryLayout<Self>.size * 8))
    }

    public static var typeHead: TypeHead {
        .int(bits: UInt8(MemoryLayout<Self>.size * 8))
    }

    public static func verifyType(in data: Data, at offset: inout Int) throws {
        try verifyByte(expecting: Self.typeHead.rawValue, in: data, at: &offset)
    }

    public static func appendType(to data: inout Data) {
        data.append(Self.typeHead.rawValue)
    }
}

extension BinaryArrayData where Self: UnsignedInteger {
    public static var type: Type {
        .uint(bits: UInt8(MemoryLayout<Self>.size * 8))
    }

    public static var typeHead: TypeHead {
        .uint(bits: UInt8(MemoryLayout<Self>.size * 8))
    }

    public static func verifyType(in data: Data, at offset: inout Int) throws {
        try verifyByte(expecting: Self.typeHead.rawValue, in: data, at: &offset)
    }

    public static func appendType(to data: inout Data) {
        data.append(Self.typeHead.rawValue)
    }
}

extension BinaryArrayData where Self: BinaryFloatingPoint {
    public static var type: Type {
        .float(bits: UInt8(MemoryLayout<Self>.size * 8))
    }

    public static var typeHead: TypeHead {
        .float(bits: UInt8(MemoryLayout<Self>.size * 8))
    }

    public static func verifyType(in data: Data, at offset: inout Int) throws {
        try verifyByte(expecting: Self.typeHead.rawValue, in: data, at: &offset)
    }

    public static func appendType(to data: inout Data) {
        data.append(Self.typeHead.rawValue)
    }
}

extension BinaryArrayData where Self: SIMD, Self.Scalar: Generic, Self.Scalar.RawRepresentation: BinaryArrayData {
    public static var type: Type {
        .simd(lanes: UInt8(Self.scalarCount), element: Self.Scalar.RawRepresentation.type)
    }

    public static var typeHead: TypeHead {
        .simd(lanes: UInt8(Self.scalarCount))
    }

    public static func verifyType(in data: Data, at offset: inout Int) throws {
        try verifyByte(expecting: Self.typeHead.rawValue, in: data, at: &offset)
        try Self.Scalar.RawRepresentation.verifyType(in: data, at: &offset)
    }

    public static func appendType(to data: inout Data) {
        data.append(Self.typeHead.rawValue)
        Self.Scalar.RawRepresentation.appendType(to: &data)
    }
}

// Primal types. MemoryLayout<T>.size == MemoryLayout<T>.stride
extension Int8: BinaryArrayData {}
extension Int16: BinaryArrayData {}
extension Int32: BinaryArrayData {}
extension Int64: BinaryArrayData {}
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
extension Int128: BinaryArrayData {}
extension UInt8: BinaryArrayData {}
extension UInt16: BinaryArrayData {}
extension UInt32: BinaryArrayData {}
extension UInt64: BinaryArrayData {}
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
extension UInt128: BinaryArrayData {}
#if arch(arm64)
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension Float16: BinaryArrayData {}
#endif
extension Float32: BinaryArrayData {}
extension Float64: BinaryArrayData {}

extension SIMD2: BinaryArrayData where Scalar: Generic, Scalar.RawRepresentation: BinaryArrayData {}
extension SIMD3: BinaryArrayData where Scalar: Generic, Scalar.RawRepresentation: BinaryArrayData {}
extension SIMD4: BinaryArrayData where Scalar: Generic, Scalar.RawRepresentation: BinaryArrayData {}
extension SIMD8: BinaryArrayData where Scalar: Generic, Scalar.RawRepresentation: BinaryArrayData {}
extension SIMD16: BinaryArrayData where Scalar: Generic, Scalar.RawRepresentation: BinaryArrayData {}
extension SIMD32: BinaryArrayData where Scalar: Generic, Scalar.RawRepresentation: BinaryArrayData {}
extension SIMD64: BinaryArrayData where Scalar: Generic, Scalar.RawRepresentation: BinaryArrayData {}

// Datatype-generic markers
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

// extension Box: BinaryArrayData { } -- not allowed; may include pointers, etc.

extension Product: BinaryArrayData where A: BinaryArrayData, B: BinaryArrayData {
    public static var type: Type {
        .product(lhs: A.type, rhs: B.type)
    }

    public static var typeHead: TypeHead {
        .product
    }

    public static func verifyType(in data: Data, at offset: inout Int) throws {
        try verifyByte(expecting: Self.typeHead.rawValue, in: data, at: &offset)
        try A.verifyType(in: data, at: &offset)
        try B.verifyType(in: data, at: &offset)
    }

    public static func appendType(to data: inout Data) {
        data.append(Self.typeHead.rawValue)
        A.appendType(to: &data)
        B.appendType(to: &data)
    }
}

// A representation of types for our tiny closed universe
public indirect enum Type: Equatable, CustomStringConvertible {
    case unit
    case int(bits: UInt8) // 8, 16, 32, 64, 128
    case uint(bits: UInt8) // 8, 16, 32, 64, 128
    case float(bits: UInt8) // 16, 32, 64
    case simd(lanes: UInt8, element: Type)
    case product(lhs: Type, rhs: Type)

    public var description: String {
        switch self {
            case .unit: "Unit"
            case let .int(bits): "Int\(bits)"
            case let .uint(bits): "UInt\(bits)"
            case let .float(bits): "Float\(bits)"
            case let .simd(lanes, element): "SIMD\(lanes)<\(element)>"
            case let .product(lhs, rhs): "Product<\(lhs), \(rhs)>"
        }
    }

    func encodedSize() -> Int {
        switch self {
            case .unit, .int, .uint, .float:
                return 1
            case let .simd(_, scalar):
                return 1 + scalar.encodedSize()
            case let .product(lhs, rhs):
                return 1 + lhs.encodedSize() + rhs.encodedSize()
        }
    }
}

// A partial type fragment (the non-recursive head of the type)
public enum TypeHead: RawRepresentable, Equatable, CustomStringConvertible {
    case unit
    case product
    case int(bits: UInt8) // 8, 16, 32, 64, 128
    case uint(bits: UInt8) // 8, 16, 32, 64, 128
    case float(bits: UInt8) // 16, 32, 64
    case simd(lanes: UInt8) // 2, 3, 4, 8, 16, 32, 64

    public var description: String {
        switch self {
            case .unit: "Unit"
            case .product: "Product<...>"
            case let .int(bits): "Int\(bits)"
            case let .uint(bits): "UInt\(bits)"
            case let .float(bits): "Float\(bits)"
            case let .simd(lanes): "SIMD\(lanes)<...>"
        }
    }

    public typealias RawValue = UInt8
    public var rawValue: UInt8 {
        switch self {
            case .unit:
                Self.encode(kind: .unit, parameter: 0)
            case .product:
                Self.encode(kind: .product, parameter: 0)
            case let .int(bits):
                Self.encode(kind: .int, parameter: Self.encode(bits: bits))
            case let .uint(bits):
                Self.encode(kind: .uint, parameter: Self.encode(bits: bits))
            case let .float(bits):
                Self.encode(kind: .float, parameter: Self.encode(bits: bits))
            case let .simd(lanes):
                Self.encode(kind: .simd, parameter: Self.encode(lanes: lanes))
        }
    }

    public init?(rawValue: UInt8) {
        let opcode = rawValue >> 4
        let parameter = rawValue & 0x0f

        if let kind = Kind(rawValue: opcode) {
            switch (kind, parameter) {
                case (.unit, 0):
                    self = .unit

                case (.product, 0):
                    self = .product

                case let (.int, bits):
                    self = .int(bits: Self.decode(bits: bits))

                case let (.uint, bits):
                    self = .uint(bits: Self.decode(bits: bits))

                case let (.float, bits):
                    self = .float(bits: Self.decode(bits: bits))

                case let (.simd, lanes):
                    self = .simd(lanes: Self.decode(lanes: lanes))

                default:
                    return nil
            }
        }
        else {
            return nil
        }
    }

    enum Kind: UInt8 {
        case unit = 0
        case int = 1
        case uint = 2
        case float = 3
        case simd = 4
        case product = 5
    }

    // Encode type kind and parameter as high and low nibble of a byte
    static func encode(kind: Kind, parameter: UInt8) -> UInt8 {
        precondition(parameter < 16)
        precondition(kind.rawValue < 16)
        return (kind.rawValue << 4) | (parameter & 0x0f)
    }

    // Encode log2(bits) as a nibble
    static func encode(bits: UInt8) -> UInt8 {
        precondition(bits > 0 && (bits & (bits - 1) == 0), "must be a power-of-two")
        return UInt8(bits.trailingZeroBitCount)
    }

    // Encode SIMD lane count as a nibble
    // Uses log2(lanes) for power-of-two lane counts, and 0 for lanes=3 (this
    // bit is free because SIMD1 is dumb and not present in the Swift language).
    static func encode(lanes: UInt8) -> UInt8 {
        precondition(lanes > 1)
        switch lanes {
            case 3:
                return 0
            default:
                precondition(lanes & (lanes - 1) == 0, "must be a power-of-two")
                return UInt8(lanes.trailingZeroBitCount)
        }
    }

    static func decode(bits: UInt8) -> UInt8 {
        precondition(bits < 16)
        return 1 << bits
    }

    static func decode(lanes: UInt8) -> UInt8 {
        precondition(lanes < 16)
        return switch lanes {
            case 0: 3
            default: 1 << lanes
        }
    }
}
