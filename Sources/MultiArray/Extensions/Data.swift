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

public enum MultiArrayBinaryError: Error, Equatable {
    case badMagic
    case truncated
    case endianMismatch
    case unsupportedVersion(Int)
    case sizeMismatch(expected: Int, actual: Int)
}

extension MultiArray where Element.RawRepresentation: BinaryArrayData {
    public init(data: Data) throws {
        let expectedMagic: UInt32 = 0x4D_41_52_52 // MARR swiftformat:disable:this numberFormatting
        let expectedVersion: UInt8 = 1

        let magic: UInt32 = try data.load(fromByteOffset: 0)
        if magic == expectedMagic.byteSwapped { throw MultiArrayBinaryError.endianMismatch }
        guard magic == expectedMagic else { throw MultiArrayBinaryError.badMagic }

        let version: UInt8 = try data.load(fromByteOffset: 4)
        guard version == expectedVersion else { throw MultiArrayBinaryError.unsupportedVersion(Int(version)) }

        _ = try data.load(fromByteOffset: 5) as UInt8 // flags
        _ = try data.load(fromByteOffset: 6) as UInt16 // reserved

        let count64: UInt64 = try data.load(fromByteOffset: 8)
        let byteCount64: UInt64 = try data.load(fromByteOffset: 16)

        guard count64 <= UInt64(Int.max) else { throw MultiArrayBinaryError.truncated }
        guard byteCount64 <= UInt64(Int.max) else { throw MultiArrayBinaryError.truncated }

        let count = Int(count64)
        let byteCount = Int(byteCount64)

        // Expected byte count for the given element type. We aren't encoding
        // the type in the binary protocol, so this is a sanity check.
        let expectedByteCount = Element.RawRepresentation.rawSize(capacity: count, from: 0)
        guard byteCount == expectedByteCount else {
            throw MultiArrayBinaryError.sizeMismatch(
                expected: expectedByteCount,
                actual: byteCount
            )
        }

        // Ensure we have the bytes
        let headerSize = 24
        let expectedSize = headerSize + byteCount
        guard data.count == expectedSize else {
            throw MultiArrayBinaryError.sizeMismatch(
                expected: expectedSize,
                actual: data.count
            )
        }

        // Allocate the buffer for the payload and memcpy dirctly into it
        self.arrayData = .init(unsafeUninitializedCapacity: count)
        data.withUnsafeBytes {
            self.arrayData.context.copyMemory(from: $0.baseAddress! + headerSize, byteCount: byteCount)
        }
    }

    public func encode() -> Data {
        let magic: UInt32 = 0x4D_41_52_52 // MARR swiftformat:disable:this numberFormatting
        let version: UInt8 = 1
        let headerSize = 24
        let payloadSize = Element.RawRepresentation.rawSize(capacity: self.count, from: 0)
        var data = Data(capacity: headerSize + payloadSize)

        // Header (adds up to 24 bytes)
        data.append(magic)
        data.append(version)
        data.append(UInt8(0)) // flags
        data.append(UInt16(0)) // reserved
        data.append(UInt64(self.count))
        data.append(UInt64(payloadSize))

        // Payload
        data.append(self.arrayData.context.assumingMemoryBound(to: UInt8.self), count: payloadSize)

        return data
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
        guard offset + MemoryLayout<T>.size <= self.count else { throw MultiArrayBinaryError.truncated }
        return self.withUnsafeBytes { $0.load(fromByteOffset: offset, as: T.self) }
    }
}
