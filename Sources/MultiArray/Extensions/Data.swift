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

private func binaryLayoutSize<A: ArrayData>(
    for _: A.Type,
    capacity: Int,
    headerSize: Int,
    typeSize: Int
) -> (payload: Int, total: Int)? {
    guard let payloadSize = A.rawSize(capacity: capacity, from: 0) else { return nil }
    let (metadataSize, metadataOverflow) = headerSize.addingReportingOverflow(typeSize)
    let (totalSize, totalOverflow) = metadataSize.addingReportingOverflow(payloadSize)
    guard !metadataOverflow, !totalOverflow else { return nil }
    return (payloadSize, totalSize)
}

extension MultiArray where Element.RawRepresentation: BinaryArrayData {
    private static var magic: UInt32 { 0x4D_41_52_52 } // MARR swiftformat:disable:this numberFormatting

    /// Encodes initialized elements as a native binary snapshot.
    ///
    /// Unused capacity is omitted. Tags describe the raw representation, not the
    /// surface element type. Snapshots round-trip within the same major library
    /// version on ABI-compatible, same-endian platforms; they are not a stable
    /// wire format and have no payload checksum. Use element-wise `Codable`
    /// encoding when an application-defined interchange format is needed.
    ///
    /// Traps if the encoded layout size is not representable.
    /// See <doc:Serialization> for examples and compatibility limits.
    public func encode() -> Data {
        // Native-endian header: magic UInt32, version UInt8, flags UInt8,
        // reserved UInt16, count UInt64, tag length UInt16; then tags and payload.
        let version: UInt8 = 1
        let headerSize = 18
        let typeSize = Element.RawRepresentation.type.encodedSize()
        guard let layout = binaryLayoutSize(
            for: Element.RawRepresentation.self,
            capacity: self.count,
            headerSize: headerSize,
            typeSize: typeSize
        ) else { preconditionFailure("MultiArray encoding size is not representable") }
        var data = Data(capacity: layout.total)

        // Header (18 bytes)
        data.append(UInt32(MultiArray.magic))
        data.append(UInt8(version))
        data.append(UInt8(0)) // flags
        data.append(UInt16(0)) // reserved
        data.append(UInt64(self.count))
        data.append(UInt16(typeSize))

        // Type encoding (typeSize bytes)
        Element.RawRepresentation.appendType(to: &data)

        // Payload (payloadSize bytes)
        if self.count == self.arrayData.capacity {
            data.append(self.arrayData.context.assumingMemoryBound(to: UInt8.self), count: layout.payload)
        }
        else {
            var offset = 0
            Element.RawRepresentation.appendPayload(
                from: self.arrayData.storage,
                count: self.count,
                to: &data,
                offset: &offset
            )
            precondition(offset == layout.payload, "Binary payload copy must agree with rawSize")
        }

        return data
    }

    /// Copies and validates a native binary snapshot into a new array.
    ///
    /// Throws `BinaryMultiArrayError` for invalid metadata, incompatible layout
    /// or endianness, or invalid raw-value domains. Matching representation tags
    /// do not establish surface-type identity; decode as the intended element
    /// type. See <doc:Serialization> for compatibility limits.
    public init(data: Data) throws {
        let expectedVersion: UInt8 = 1
        let expectedHeaderSize = 18 // of the expected version

        // Check we have at least a complete header (based on the expected type)
        let expectedTypeSize = Element.RawRepresentation.type.encodedSize()
        guard data.count >= expectedHeaderSize + expectedTypeSize else {
            throw BinaryMultiArrayError.truncated(index: 0, required: expectedHeaderSize + expectedTypeSize, total: data.count)
        }

        // Start decoding the header
        let magic: UInt32 = try data.load(fromByteOffset: 0)
        if magic == MultiArray.magic.byteSwapped { throw BinaryMultiArrayError.endianMismatch }
        if magic != MultiArray.magic { throw BinaryMultiArrayError.badMagic }

        let version: UInt8 = try data.load(fromByteOffset: 4)
        guard version == expectedVersion else { throw BinaryMultiArrayError.unsupportedVersion(Int(version)) }

        _ = try data.load(fromByteOffset: 5) as UInt8 // flags
        _ = try data.load(fromByteOffset: 6) as UInt16 // reserved

        let count64: UInt64 = try data.load(fromByteOffset: 8)
        guard count64 <= UInt64(Int.max) else { throw BinaryMultiArrayError.overflow(count64) }
        let count = Int(count64)

        // Ensure we have the correct number of bytes
        guard let layout = binaryLayoutSize(
            for: Element.RawRepresentation.self,
            capacity: count,
            headerSize: expectedHeaderSize,
            typeSize: expectedTypeSize
        ) else { throw BinaryMultiArrayError.overflow(count64) }
        guard data.count == layout.total else {
            throw BinaryMultiArrayError.sizeMismatch(expected: layout.total, actual: data.count)
        }

        // Decode the (variable sized) type tag
        let typeSize16: UInt16 = try data.load(fromByteOffset: 16)
        let typeSize = Int(typeSize16)
        var offset = expectedHeaderSize
        try Element.RawRepresentation.verifyType(in: data, at: &offset)
        guard offset == 18 + typeSize else {
            throw BinaryMultiArrayError.malformedType(expected: typeSize, actual: offset - 18)
        }

        // Header verification is complete.
        // Allocate the buffer for the payload and memcpy directly into it.
        self.arrayData = MultiArrayData<Element.RawRepresentation>(unsafeUninitializedCapacity: count)
        try data.withUnsafeBytes { ptr in
            guard let addr = ptr.baseAddress else {
                throw BinaryMultiArrayError.storageUnavailable
            }
            self.arrayData.context.copyMemory(from: addr + offset, byteCount: layout.payload)
        }
        if let index = Element.RawRepresentation.firstInvalidElement(in: self.arrayData.storage, count: count) {
            throw BinaryMultiArrayError.invalidRawRepresentation(index: index)
        }
        self.arrayData.count = count
    }
}

/// A failure to validate or read a native binary snapshot.
public enum BinaryMultiArrayError: Error, Equatable, CustomStringConvertible {
    /// The input does not begin with the expected snapshot magic.
    case badMagic
    /// The snapshot was encoded with incompatible byte order.
    case endianMismatch
    /// The encoded `Data` did not expose its underlying bytes.
    case storageUnavailable
    /// An element's raw value is outside its surface type's domain.
    case invalidRawRepresentation(index: Int)
    /// The count or derived layout size cannot be represented.
    case overflow(UInt64)
    /// The encoding version is not supported.
    case unsupportedVersion(Int)
    /// A metadata read requires bytes beyond the input's extent.
    case truncated(index: Int, required: Int, total: Int)
    /// The byte count does not match the expected snapshot layout.
    case sizeMismatch(expected: Int, actual: Int)
    /// A representation tag differs from the expected tag.
    case typeMismatch(expected: UInt8, actual: UInt8)
    /// The consumed tag length differs from the header's declared length.
    case malformedType(expected: Int, actual: Int)

    public var description: String {
        switch self {
            case .badMagic:
                "Incorrect magic value. Are you sure this is MultiArray data?"
            case .endianMismatch:
                "Attempt to load data that was produced on a machine of different endian-ness. This is not supported."
            case .storageUnavailable:
                "Unable to access the encoded Data's underlying storage."
            case let .invalidRawRepresentation(index):
                "Invalid raw representation for element at index \(index)."
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
        guard offset >= 0, required <= self.count, offset <= self.count - required else {
            throw BinaryMultiArrayError.truncated(index: offset, required: required, total: self.count)
        }
        return self.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: T.self) }
    }
}

/// A raw representation that can be encoded as a native binary snapshot.
///
/// Storage must contain no references and have a type-determined layout with
/// fully initialized, deterministic bytes, including padding. Payloads copied
/// into reserved storage must be safe to validate and destroy on decode failure
/// while its published count is zero. The tags describe the representation,
/// not the surface element type; snapshots are not a stable wire format.
public protocol BinaryArrayData: ArrayData {
    /// The complete representation tag.
    static var type: Type { get }
    /// The outermost representation tag.
    static var typeHead: TypeHead { get }

    /// Verifies and consumes this representation's tags, advancing `offset`.
    static func verifyType(in data: Data, at offset: inout Int) throws

    /// Appends the complete representation tag.
    static func appendType(to data: inout Data)

    /// Appends only initialized field prefixes in the count-sized layout.
    /// `offset` is relative to the payload start, not the start of `data`.
    /// Implementations must match `rawSize`, zero alignment gaps, and never
    /// read unused capacity. Products recursively append their children.
    static func appendPayload(from storage: Buffer, count: Int, to data: inout Data, offset: inout Int)

    /// Returns the first element whose representation cannot be reconstructed,
    /// or `nil` when every representation is valid.
    static func firstInvalidElement(in buffer: Buffer, count: Int) -> Int?
}

extension BinaryArrayData {
    public static func firstInvalidElement(in _: Buffer, count _: Int) -> Int? {
        nil
    }

    static func verifyByte(expecting: UInt8, in data: Data, at offset: inout Int) throws {
        let found: UInt8 = try data.load(fromByteOffset: offset)
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

/// The recursive representation tag used by native binary snapshots.
///
/// This is exposed by `BinaryArrayData` but is a format implementation detail,
/// not a surface-type identifier or a stable wire-format guarantee.
@_documentation(visibility: internal)
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

/// The nonrecursive head of a native binary snapshot's representation tag.
///
/// This is exposed by `BinaryArrayData` for compatibility with custom
/// conformances; it does not identify the original Swift element type.
@_documentation(visibility: internal)
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
