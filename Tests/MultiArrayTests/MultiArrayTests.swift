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

    // MARK: - Empty array tests

    @Suite
    struct EmptyArrayTests {
        @Test
        func emptyZoneArrayRoundtrips() {
            let ma = MultiArray<Zone>()
            #expect(ma.count == 0)
            #expect(Array(ma).isEmpty)
        }

        @Test
        func emptyVec3ArrayRoundtrips() {
            let ma = MultiArray<Vec3<Float>>()
            #expect(ma.count == 0)
            #expect(Array(ma).isEmpty)
        }

        @Test
        func emptyZoneCodableRoundtrip() throws {
            let original = MultiArray<Zone>()
            let encoder = JSONEncoder()
            let data = try encoder.encode(original)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(MultiArray<Zone>.self, from: data)
            #expect(original == decoded)
        }

        @Test
        func emptyVec3CodableRoundtrip() throws {
            let original = MultiArray<Vec3<Float>>()
            let encoder = JSONEncoder()
            let data = try encoder.encode(original)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(MultiArray<Vec3<Float>>.self, from: data)
            #expect(original == decoded)
        }

        @Test
        func emptyZoneBinaryRoundtrip() throws {
            let original = MultiArray<Zone>()
            let encoded = original.encode()
            let decoded = try MultiArray<Zone>(data: encoded)
            #expect(original == decoded)
        }

        @Test
        func emptyVec3BinaryRoundtrip() throws {
            let original = MultiArray<Vec3<Float>>()
            let encoded = original.encode()
            let decoded = try MultiArray<Vec3<Float>>(data: encoded)
            #expect(original == decoded)
        }

        @Test
        func emptyArrayIteration() {
            var zoneCount = 0
            for _ in MultiArray<Zone>() { zoneCount += 1 }
            #expect(zoneCount == 0)

            var vec3Count = 0
            for _ in MultiArray<Vec3<Float>>() { vec3Count += 1 }
            #expect(vec3Count == 0)
        }
    }

    // MARK: - Large array stress tests

    @Suite
    struct LargeArrayTests {
        @Test
        func largeIntArrayRoundtrips() {
            let count = 100_000
            var array: [Int] = []
            array.reserveCapacity(count)
            for i in 0 ..< count {
                array.append(i)
            }
            let ma = MultiArray(array)
            #expect(ma.count == count)
            let roundtrip = Array(ma)
            #expect(roundtrip == array)
        }

        @Test
        func largePointArrayRoundtrips() {
            let count = 50_000
            var array: [Point] = []
            array.reserveCapacity(count)
            for i in 0 ..< count {
                array.append(Point(x: Double(i), y: Double(i) * 2.0))
            }
            let ma = MultiArray(array)
            #expect(ma.count == count)
            let roundtrip = Array(ma)
            #expect(roundtrip == array)
        }

        @Test
        func rawSizeDoesNotOverflow() {
            let size = Int64.RawRepresentation.rawSize(capacity: 1_000_000, from: 0)
            #expect(size > 0)
            #expect(size <= Int.max)

            let productSize = Product<Int64, Double>.RawRepresentation
                .rawSize(capacity: 1_000_000, from: 0)
            #expect(productSize > 0)
            #expect(productSize <= Int.max)
        }
    }

    // MARK: - Bool field roundtrip

    @Suite
    struct BoolFieldTests {
        @Test
        func boolFieldRoundtrip() {
            let array: [FlaggedPoint] = [
                .init(active: true, x: 1.0, y: 2.0),
                .init(active: false, x: 3.0, y: 4.0),
                .init(active: true, x: 5.0, y: 6.0),
            ]
            let ma = MultiArray(array)
            let roundtrip = Array(ma)
            #expect(roundtrip == array)
        }

        @Test
        func boolFieldCodableRoundtrip() throws {
            let original: MultiArray<FlaggedPoint> = [
                .init(active: true, x: 1.0, y: 2.0),
                .init(active: false, x: 3.0, y: 4.0),
            ]
            let encoder = JSONEncoder()
            let data = try encoder.encode(original)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(MultiArray<FlaggedPoint>.self, from: data)
            #expect(decoded == original)
        }

        @Test
        func boolFieldBinaryRoundtrip() throws {
            let original: MultiArray<FlaggedPoint> = [
                .init(active: true, x: 1.0, y: 2.0),
                .init(active: false, x: 3.0, y: 4.0),
                .init(active: true, x: 5.0, y: 6.0),
                .init(active: false, x: 7.0, y: 8.0),
            ]
            let encoded = original.encode()
            let decoded = try MultiArray<FlaggedPoint>(data: encoded)
            #expect(decoded == original)
        }

        @Test
        func boolFieldMutation() {
            var ma: MultiArray<FlaggedPoint> = [
                .init(active: true, x: 1.0, y: 0.0),
                .init(active: false, x: 2.0, y: 0.0),
            ]
            ma[0] = .init(active: false, x: 99.0, y: 0.0)
            #expect(ma[0].active == false)
            #expect(ma[0].x == 99.0)
            #expect(ma[1].active == false)
            #expect(ma[1].x == 2.0)
        }
    }

    // MARK: - Throwing init error path tests

    // These tests verify that when the throwing init partially initializes
    // elements and then throws, exactly the initialized elements are
    // deinitialized -- no leaks (liveCount > 0) and no UB (crash from
    // deinitializing garbage memory).

    @Suite
    struct ThrowingInitTests {
        struct PartialInitError: Error {}

        @Test
        func throwingInitWithTrivialType() throws {
            #expect(throws: PartialInitError.self) {
                _ = try MultiArray<Int>(unsafeUninitializedCapacity: 10) { buffer, _ in
                    buffer.initializeElement(at: 0, to: 1)
                    buffer.initializeElement(at: 1, to: 2)
                    throw PartialInitError()
                }
            }
        }

        @Test
        func throwingInitWithBoxType() throws {
            #expect(throws: PartialInitError.self) {
                _ = try MultiArray<Box<String>>(unsafeUninitializedCapacity: 10) { buffer, initializedCount in
                    buffer.initializeElement(at: 0, to: Box("hello"))
                    buffer.initializeElement(at: 1, to: Box("world"))
                    initializedCount = 2
                    throw PartialInitError()
                }
            }
        }

        @Test
        func partialInitDeinitializesExactlyInitializedElements() throws {
            // Tracked class counts live instances to verify no leaks
            final class Tracked {
                nonisolated(unsafe) static var liveCount: Int = 0

                init() { Tracked.liveCount += 1 }
                deinit { Tracked.liveCount -= 1 }
            }

            Tracked.liveCount = 0
            let toInitialize = 3

            #expect(throws: PartialInitError.self) {
                _ = try MultiArray<Box<Tracked>>(unsafeUninitializedCapacity: 10) { buffer, initializedCount in
                    var initialized = 0
                    defer { initializedCount = initialized }

                    for i in 0 ..< toInitialize {
                        buffer.initializeElement(at: i, to: Box(Tracked()))
                        initialized += 1
                    }

                    // At this point we've initialized `toInitialize` elements
                    #expect(Tracked.liveCount == toInitialize)

                    throw PartialInitError()
                }
            }

            // After the throw, the local arrayData is deallocated. Its deinit
            // should deinitialize exactly `toInitialize` elements. If it
            // deinitializes fewer, liveCount > 0 (leak). If it deinitializes
            // more, we get UB/crash from calling deinit on garbage memory.
            #expect(Tracked.liveCount == 0, "all \(toInitialize) initialized elements should be deinitialized after throw")
        }
    }

    // MARK: - Roundtrip tests

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
