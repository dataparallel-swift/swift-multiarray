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
struct MultiArrayTests {
    @Test
    func test1() {
        let array: [Point] = [.init(x: 1.0, y: 2.0), .init(x: 3.0, y: 4.0)]
        let multiArray = MultiArray(array)
        let newArray = array.map { $0.x + 1.0 }
        let newMultiArray = multiArray.map { $0.x + 1.0 }
        #expect(newArray == Array(newMultiArray))
    }

    @Suite
    struct RoundTripTests {
        @Suite
        struct ScalarTests {
            @Test func testInt() { roundtripTest(Int.self) }
            @Test func testInt8() { roundtripTest(Int8.self) }
            @Test func testInt16() { roundtripTest(Int16.self) }
            @Test func testInt32() { roundtripTest(Int32.self) }
            @Test func testInt64() { roundtripTest(Int64.self) }
            @available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
            @Test func testInt128() { roundtripTest(Int128.self) }
            @Test func testUInt() { roundtripTest(UInt.self) }
            @Test func testUInt8() { roundtripTest(UInt8.self) }
            @Test func testUInt16() { roundtripTest(UInt16.self) }
            @Test func testUInt32() { roundtripTest(UInt32.self) }
            @Test func testUInt64() { roundtripTest(UInt64.self) }
            @available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
            @Test func testUInt128() { roundtripTest(UInt128.self) }
            #if arch(arm64)
            @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
            @Test func testFloat16() { roundtripTest(Float16.self) }
            #endif
            @Test func testFloat32() { roundtripTest(Float32.self) }
            @Test func testFloat64() { roundtripTest(Float64.self) }
            @Test func testBool() { roundtripTest(Bool.self) }
        }

        @Suite
        struct StructTests {
            @Test func testPoint() { roundtripTest(Point.self) }
            @Test func testZone() { roundtripTest(Zone.self) }
            @Test func testUUID() { roundtripTest(UUID.self) }
            @Test func testDate() { roundtripTest(Date.self) }
        }

        @Suite
        struct SIMD2Tests {
            @Test func testSIMD2Int() { roundtripTest(SIMD2<Int>.self) }
            @Test func testSIMD2Int8() { roundtripTest(SIMD2<Int8>.self) }
            @Test func testSIMD2Int16() { roundtripTest(SIMD2<Int16>.self) }
            @Test func testSIMD2Int32() { roundtripTest(SIMD2<Int32>.self) }
            @Test func testSIMD2Int64() { roundtripTest(SIMD2<Int64>.self) }
            @Test func testSIMD2UInt() { roundtripTest(SIMD2<UInt>.self) }
            @Test func testSIMD2UInt8() { roundtripTest(SIMD2<UInt8>.self) }
            @Test func testSIMD2UInt16() { roundtripTest(SIMD2<UInt16>.self) }
            @Test func testSIMD2UInt32() { roundtripTest(SIMD2<UInt32>.self) }
            @Test func testSIMD2UInt64() { roundtripTest(SIMD2<UInt64>.self) }
            #if arch(arm64)
            @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
            @Test func testSIMD2Float16() { roundtripTest(SIMD2<Float16>.self) }
            #endif
            @Test func testSIMD2Float32() { roundtripTest(SIMD2<Float32>.self) }
            @Test func testSIMD2Float64() { roundtripTest(SIMD2<Float64>.self) }
        }

        @Suite
        struct SIMD3Tests {
            @Test func testSIMD3Int() { roundtripTest(SIMD3<Int>.self) }
            @Test func testSIMD3Int8() { roundtripTest(SIMD3<Int8>.self) }
            @Test func testSIMD3Int16() { roundtripTest(SIMD3<Int16>.self) }
            @Test func testSIMD3Int32() { roundtripTest(SIMD3<Int32>.self) }
            @Test func testSIMD3Int64() { roundtripTest(SIMD3<Int64>.self) }
            @Test func testSIMD3UInt() { roundtripTest(SIMD3<UInt>.self) }
            @Test func testSIMD3UInt8() { roundtripTest(SIMD3<UInt8>.self) }
            @Test func testSIMD3UInt16() { roundtripTest(SIMD3<UInt16>.self) }
            @Test func testSIMD3UInt32() { roundtripTest(SIMD3<UInt32>.self) }
            @Test func testSIMD3UInt64() { roundtripTest(SIMD3<UInt64>.self) }
            #if arch(arm64)
            @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
            @Test func testSIMD3Float16() { roundtripTest(SIMD3<Float16>.self) }
            #endif
            @Test func testSIMD3Float32() { roundtripTest(SIMD3<Float32>.self) }
            @Test func testSIMD3Float64() { roundtripTest(SIMD3<Float64>.self) }
        }
    }

    @Suite
    struct CodableTests {
        @Test
        func testStructure() throws {
            let array: MultiArray<Int> = [10, 20, 30]

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]

            let data = try encoder.encode(array)

            // Inspect the shape of the JSON dictionary
            let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            // Keys exist
            #expect(jsonObject?["version"] != nil)
            #expect(jsonObject?["count"] != nil)
            #expect(jsonObject?["values"] != nil)

            // Values have expected contents
            #expect(jsonObject?["version"] as? Int == 1)
            #expect(jsonObject?["count"] as? Int == 3)
            #expect(jsonObject?["values"] as? [Int] == [10, 20, 30])
        }

        @Test
        func decodeWithoutVersion() throws {
            let json = """
            {
                "count": 3,
                "values": [1, 2, 3]
            }
            """

            let data = Data(json.utf8)
            let decoder = JSONDecoder()

            let decoded = try decoder.decode(MultiArray<Int>.self, from: data)
            #expect(decoded == MultiArray<Int>([1, 2, 3]))
        }

        @Test
        func failNotEnoughValues() throws {
            let json = """
            {
                "count": 4,
                "values": [1, 2, 3]
            }
            """

            let data = Data(json.utf8)
            let decoder = JSONDecoder()

            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(MultiArray<Int>.self, from: data)
            }
        }

        @Test
        func failTooManyValues() throws {
            let json = """
            {
                "count": 2,
                "values": [1, 2, 3]
            }
            """

            let data = Data(json.utf8)
            let decoder = JSONDecoder()

            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(MultiArray<Int>.self, from: data)
            }
        }

        @Test
        func failUnsupportedVersion() throws {
            let json = """
            {
                "version": 999,
                "count": 3,
                "values": [1, 2, 3]
            }
            """

            let data = Data(json.utf8)
            let decoder = JSONDecoder()

            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(MultiArray<Int>.self, from: data)
            }
        }

        @Suite
        struct RoundTripTests {
            @Suite
            struct ScalarTests {
                @Test func testCodableInt() throws { try roundtripCodableTest(Int.self) }
                @Test func testCodableInt8() throws { try roundtripCodableTest(Int8.self) }
                @Test func testCodableInt16() throws { try roundtripCodableTest(Int16.self) }
                @Test func testCodableInt32() throws { try roundtripCodableTest(Int32.self) }
                @Test func testCodableInt64() throws { try roundtripCodableTest(Int64.self) }
                @available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
                @Test func testCodableInt128() throws { try roundtripCodableTest(Int128.self) }
                @Test func testCodableUInt() throws { try roundtripCodableTest(UInt.self) }
                @Test func testCodableUInt8() throws { try roundtripCodableTest(UInt8.self) }
                @Test func testCodableUInt16() throws { try roundtripCodableTest(UInt16.self) }
                @Test func testCodableUInt32() throws { try roundtripCodableTest(UInt32.self) }
                @Test func testCodableUInt64() throws { try roundtripCodableTest(UInt64.self) }
                @available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
                @Test func testCodableUInt128() throws { try roundtripCodableTest(UInt128.self) }
                #if arch(arm64)
                @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
                @Test func testCodableFloat16() throws { try roundtripCodableTest(Float16.self) }
                #endif
                @Test func testCodableFloat32() throws { try roundtripCodableTest(Float32.self) }
                @Test func testCodableFloat64() throws { try roundtripCodableTest(Float64.self) }
                @Test func testCodableBool() throws { try roundtripCodableTest(Bool.self) }
            }

            @Suite
            struct StructTests {
                @Test func testCodablePoint() throws { try roundtripCodableTest(Point.self) }
                @Test func testCodableZone() throws { try roundtripCodableTest(Zone.self) }
            }

            @Suite
            struct SIMD2Tests {
                @Test func testCodableSIMD2Int() throws { try roundtripCodableTest(SIMD2<Int>.self) }
                @Test func testCodableSIMD2Int8() throws { try roundtripCodableTest(SIMD2<Int8>.self) }
                @Test func testCodableSIMD2Int16() throws { try roundtripCodableTest(SIMD2<Int16>.self) }
                @Test func testCodableSIMD2Int32() throws { try roundtripCodableTest(SIMD2<Int32>.self) }
                @Test func testCodableSIMD2Int64() throws { try roundtripCodableTest(SIMD2<Int64>.self) }
                @Test func testCodableSIMD2UInt() throws { try roundtripCodableTest(SIMD2<UInt>.self) }
                @Test func testCodableSIMD2UInt8() throws { try roundtripCodableTest(SIMD2<UInt8>.self) }
                @Test func testCodableSIMD2UInt16() throws { try roundtripCodableTest(SIMD2<UInt16>.self) }
                @Test func testCodableSIMD2UInt32() throws { try roundtripCodableTest(SIMD2<UInt32>.self) }
                @Test func testCodableSIMD2UInt64() throws { try roundtripCodableTest(SIMD2<UInt64>.self) }
                #if arch(arm64)
                @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
                @Test func testCodableSIMD2Float16() throws { try roundtripCodableTest(SIMD2<Float16>.self) }
                #endif
                @Test func testCodableSIMD2Float32() throws { try roundtripCodableTest(SIMD2<Float32>.self) }
                @Test func testCodableSIMD2Float64() throws { try roundtripCodableTest(SIMD2<Float64>.self) }
            }

            @Suite
            struct SIMD3Tests {
                @Test func testCodableSIMD3Int() throws { try roundtripCodableTest(SIMD3<Int>.self) }
                @Test func testCodableSIMD3Int8() throws { try roundtripCodableTest(SIMD3<Int8>.self) }
                @Test func testCodableSIMD3Int16() throws { try roundtripCodableTest(SIMD3<Int16>.self) }
                @Test func testCodableSIMD3Int32() throws { try roundtripCodableTest(SIMD3<Int32>.self) }
                @Test func testCodableSIMD3Int64() throws { try roundtripCodableTest(SIMD3<Int64>.self) }
                @Test func testCodableSIMD3UInt() throws { try roundtripCodableTest(SIMD3<UInt>.self) }
                @Test func testCodableSIMD3UInt8() throws { try roundtripCodableTest(SIMD3<UInt8>.self) }
                @Test func testCodableSIMD3UInt16() throws { try roundtripCodableTest(SIMD3<UInt16>.self) }
                @Test func testCodableSIMD3UInt32() throws { try roundtripCodableTest(SIMD3<UInt32>.self) }
                @Test func testCodableSIMD3UInt64() throws { try roundtripCodableTest(SIMD3<UInt64>.self) }
                #if arch(arm64)
                @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
                @Test func testCodableSIMD3Float16() throws { try roundtripCodableTest(SIMD3<Float16>.self) }
                #endif
                @Test func testCodableSIMD3Float32() throws { try roundtripCodableTest(SIMD3<Float32>.self) }
                @Test func testCodableSIMD3Float64() throws { try roundtripCodableTest(SIMD3<Float64>.self) }
            }
        }
    }

    @Test
    func boxDoesNotLeak() {
        final class Tracked {
            nonisolated(unsafe) static var liveCount: Int = 0

            init() { Tracked.liveCount += 1 }
            deinit { Tracked.liveCount -= 1 }
        }

        // Make sure ARC actually tears everything down
        do {
            // Tracked has copy-on-write semantics, so we should have 4
            // references to the same object
            var arr = MultiArray<Box<Tracked>>(repeating: Box(Tracked()), count: 4)
            #expect(Tracked.liveCount == 1)

            // Overwrite the slots a bunch of times to stress replacement
            // semantics. Each overwrite should release the old object.
            for i in 0 ..< 100 {
                arr[i % 4] = Box(Tracked())
            }

            // We should now have exactly 4 copies
            #expect(Tracked.liveCount == 4)
        }

        // Leaving the do scope should drop arr and release everything it owns
        #expect(Tracked.liveCount == 0)
    }

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
}

func roundtripTest<T: Randomizable & Equatable & Generic>(_: T.Type, iterations: Int = 1000)
    where T.RawRepresentation: ArrayData
{
    var generator = SystemRandomNumberGenerator()
    let step = 100 / Double(iterations)

    for i in 0 ..< iterations {
        let size: Int64 = min(99, Int64((Double(i) * step).rounded(.towardZero)))
        let length = Int.random(in: linear(from: 0, to: 1024)(size), using: &generator)
        let scalarArray: [T] = randomArray(count: length, using: &generator)
        let multiArray = MultiArray(scalarArray)
        let roundtripArray = Array(multiArray)

        #expect(scalarArray == roundtripArray)
    }
}

func roundtripCodableTest<T: Randomizable & Equatable & Generic & Codable>(_: T.Type, iterations: Int = 100) throws
    where T.RawRepresentation: ArrayData
{
    var generator = SystemRandomNumberGenerator()
    let step = 100 / Double(iterations)

    for i in 0 ..< iterations {
        let size: Int64 = min(99, Int64((Double(i) * step).rounded(.towardZero)))
        let length = Int.random(in: linear(from: 0, to: 1024)(size), using: &generator)
        let original: MultiArray<T> = MultiArray(randomArray(count: length, using: &generator))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MultiArray<T>.self, from: data)

        #expect(original == decoded)
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
