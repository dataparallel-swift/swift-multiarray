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
import MultiArray
import Testing

@Suite
struct DataTests {
    @Test
    func failMagic() throws {
        let array: MultiArray<Int> = [1, 2, 3]
        var encoded = array.encode()
        encoded[0] ^= 0xff

        #expect(throws: BinaryMultiArrayError.badMagic) {
            _ = try MultiArray<Int>(data: encoded)
        }
    }

    @Test
    func failVersion() throws {
        let array: MultiArray<Int> = [1, 2, 3]
        var encoded = array.encode()
        encoded[4] = 99

        #expect(throws: BinaryMultiArrayError.unsupportedVersion(99)) {
            _ = try MultiArray<Int>(data: encoded)
        }
    }

    @Test
    func failTruncated() throws {
        let array: MultiArray<Float> = []
        let encoded = array.encode()

        // Ensure we truncate into the payload
        #expect(encoded.count == 19)

        let truncated = encoded.prefix(encoded.count - 1)
        #expect(throws: BinaryMultiArrayError.truncated(index: 0, required: 19, total: 18)) {
            _ = try MultiArray<Float>(data: truncated)
        }
    }

    @Test
    func failCountMismatch() throws {
        let array: MultiArray<Int32> = [10, 20, 30]
        var encoded = array.encode()

        // count field offset (8 ..< 16)
        let count = encoded.withUnsafeBytes { $0.load(fromByteOffset: 8, as: UInt64.self) }
        #expect(count == 3)

        encoded[8] ^= 0x01
        #expect(throws: BinaryMultiArrayError.self) {
            _ = try MultiArray<Int32>(data: encoded)
        }
    }

    @Test
    func failTypeMismatch() throws {
        let array: MultiArray<Int32> = [1, 2, 3]
        let encoded = array.encode()

        #expect(throws: BinaryMultiArrayError.typeMismatch(expected: 0x35, actual: 0x15)) {
            _ = try MultiArray<Float32>(data: encoded)
        }
    }

    @Test
    func rawRepresentableEnumRoundtrips() throws {
        let original: MultiArray<Status> = [.off, .on, .unknown]
        let encoded = original.encode()
        #expect(encoded == MultiArray<UInt8>([0, 2, 255]).encode())

        let decoded = try MultiArray<Status>(data: encoded)
        #expect(decoded == original)
    }

    @Test
    func rawRepresentableNewtypeRoundtrips() throws {
        let original: MultiArray<Identifier> = [.init(rawValue: 0), .init(rawValue: 42), .init(rawValue: .max)]
        let decoded = try MultiArray<Identifier>(data: original.encode())
        #expect(decoded == original)
    }

    @Test
    func rejectsInvalidRawRepresentableValue() throws {
        let encoded = MultiArray<UInt8>([Status.off.rawValue, Status.on.rawValue, 42]).encode()

        #expect(throws: BinaryMultiArrayError.invalidRawRepresentation(index: 2)) {
            _ = try MultiArray<Status>(data: encoded)
        }
    }

    @Test
    func rejectsInvalidNestedRawRepresentableValue() throws {
        let encoded = MultiArray([
            Product(Status.off.rawValue, UInt16(10)),
            Product(UInt8(42), UInt16(20)),
        ]).encode()

        #expect(throws: BinaryMultiArrayError.invalidRawRepresentation(index: 1)) {
            _ = try MultiArray<StatusRecord>(data: encoded)
        }
    }

    @Suite
    struct RoundTripTests {
        @Suite
        struct ScalarTests {
            @Test func testDataInt() throws { try roundtripDataTest(Int.self) }
            @Test func testDataInt8() throws { try roundtripDataTest(Int8.self) }
            @Test func testDataInt16() throws { try roundtripDataTest(Int16.self) }
            @Test func testDataInt32() throws { try roundtripDataTest(Int32.self) }
            @Test func testDataInt64() throws { try roundtripDataTest(Int64.self) }
            @available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
            @Test func testDataInt128() throws { try roundtripDataTest(Int128.self) }
            @Test func testDataUInt() throws { try roundtripDataTest(UInt.self) }
            @Test func testDataUInt8() throws { try roundtripDataTest(UInt8.self) }
            @Test func testDataUInt16() throws { try roundtripDataTest(UInt16.self) }
            @Test func testDataUInt32() throws { try roundtripDataTest(UInt32.self) }
            @Test func testDataUInt64() throws { try roundtripDataTest(UInt64.self) }
            @available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
            @Test func testDataUInt128() throws { try roundtripDataTest(UInt128.self) }
            #if arch(arm64)
            @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
            @Test func testDataFloat16() throws { try roundtripDataTest(Float16.self) }
            #endif
            @Test func testDataFloat32() throws { try roundtripDataTest(Float32.self) }
            @Test func testDataFloat64() throws { try roundtripDataTest(Float64.self) }
            @Test func testDataBool() throws { try roundtripDataTest(Bool.self) }
        }

        @Suite
        struct StructTests {
            @Test func testDataPoint() throws { try roundtripDataTest(Point.self) }
            @Test func testDataZone() throws { try roundtripDataTest(Zone.self) }
            @Test func testDataUUID() throws { try roundtripDataTest(UUID.self) }
            @Test func testDataDate() throws { try roundtripDataTest(Date.self) }
        }

        @Suite
        struct SIMD2Tests {
            @Test func testDataSIMD2Int() throws { try roundtripDataTest(SIMD2<Int>.self) }
            @Test func testDataSIMD2Int8() throws { try roundtripDataTest(SIMD2<Int8>.self) }
            @Test func testDataSIMD2Int16() throws { try roundtripDataTest(SIMD2<Int16>.self) }
            @Test func testDataSIMD2Int32() throws { try roundtripDataTest(SIMD2<Int32>.self) }
            @Test func testDataSIMD2Int64() throws { try roundtripDataTest(SIMD2<Int64>.self) }
            @Test func testDataSIMD2UInt() throws { try roundtripDataTest(SIMD2<UInt>.self) }
            @Test func testDataSIMD2UInt8() throws { try roundtripDataTest(SIMD2<UInt8>.self) }
            @Test func testDataSIMD2UInt16() throws { try roundtripDataTest(SIMD2<UInt16>.self) }
            @Test func testDataSIMD2UInt32() throws { try roundtripDataTest(SIMD2<UInt32>.self) }
            @Test func testDataSIMD2UInt64() throws { try roundtripDataTest(SIMD2<UInt64>.self) }
            #if arch(arm64)
            @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
            @Test func testDataSIMD2Float16() throws { try roundtripDataTest(SIMD2<Float16>.self) }
            #endif
            @Test func testDataSIMD2Float32() throws { try roundtripDataTest(SIMD2<Float32>.self) }
            @Test func testDataSIMD2Float64() throws { try roundtripDataTest(SIMD2<Float64>.self) }
        }

        @Suite
        struct SIMD3Tests {
            @Test func testDataSIMD3Int() throws { try roundtripDataTest(SIMD3<Int>.self) }
            @Test func testDataSIMD3Int8() throws { try roundtripDataTest(SIMD3<Int8>.self) }
            @Test func testDataSIMD3Int16() throws { try roundtripDataTest(SIMD3<Int16>.self) }
            @Test func testDataSIMD3Int32() throws { try roundtripDataTest(SIMD3<Int32>.self) }
            @Test func testDataSIMD3Int64() throws { try roundtripDataTest(SIMD3<Int64>.self) }
            @Test func testDataSIMD3UInt() throws { try roundtripDataTest(SIMD3<UInt>.self) }
            @Test func testDataSIMD3UInt8() throws { try roundtripDataTest(SIMD3<UInt8>.self) }
            @Test func testDataSIMD3UInt16() throws { try roundtripDataTest(SIMD3<UInt16>.self) }
            @Test func testDataSIMD3UInt32() throws { try roundtripDataTest(SIMD3<UInt32>.self) }
            @Test func testDataSIMD3UInt64() throws { try roundtripDataTest(SIMD3<UInt64>.self) }
            #if arch(arm64)
            @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
            @Test func testDataSIMD3Float16() throws { try roundtripDataTest(SIMD3<Float16>.self) }
            #endif
            @Test func testDataSIMD3Float32() throws { try roundtripDataTest(SIMD3<Float32>.self) }
            @Test func testDataSIMD3Float64() throws { try roundtripDataTest(SIMD3<Float64>.self) }
        }
    }
}

func roundtripDataTest<T: Randomizable & Equatable & Generic>(_: T.Type, iterations: Int = 1000) throws
    where T.RawRepresentation: BinaryArrayData
{
    var generator = SystemRandomNumberGenerator()
    let step = 100 / Double(iterations)

    for i in 0 ..< iterations {
        let size: Int64 = min(99, Int64((Double(i) * step).rounded(.towardZero)))
        let length = Int.random(in: linear(from: 0, to: 1024)(size), using: &generator)
        let original: MultiArray<T> = MultiArray(randomArray(count: length, using: &generator))

        let encoded = original.encode()
        let decoded = try MultiArray<T>(data: encoded)

        #expect(original == decoded)
    }
}
