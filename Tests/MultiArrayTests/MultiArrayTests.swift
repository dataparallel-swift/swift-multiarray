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

import MultiArray
import Testing

struct Point: Generic, Equatable, Randomizable {
    typealias RawRepresentation = Product<Double, Double>

    var x: Double
    var y: Double

    var rawRepresentation: Product<Double, Double> {
        .init(x, y)
    }

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(from rep: RawRepresentation) {
        self = .init(x: rep._0, y: rep._1)
    }

    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self {
        Self(
            x: Double.random(using: &generator),
            y: Double.random(using: &generator)
        )
    }
}

struct Vec3<Element>: Equatable where Element: Equatable {
    let x, y, z: Element

    init(x: Element, y: Element, z: Element) {
        self.x = x
        self.y = y
        self.z = z
    }
}

extension Vec3: Generic where Element: Generic {
    typealias RawRepresentation = T3<Element, Element, Element>.RawRepresentation

    var rawRepresentation: RawRepresentation {
        T3(self.x, self.y, self.z).rawRepresentation
    }

    init(from rep: RawRepresentation) {
        let T3 = T3<Element, Element, Element>(from: rep)
        self = Vec3(x: T3._0, y: T3._1, z: T3._2)
    }
}

extension Vec3: Randomizable where Element: Randomizable {
    static func random<T: RandomNumberGenerator>(using generator: inout T) -> Self {
        Vec3(
            x: Element.random(using: &generator),
            y: Element.random(using: &generator),
            z: Element.random(using: &generator)
        )
    }
}

struct Zone: Generic, Equatable, Randomizable {
    typealias RawRepresentation = T2<Int, Vec3<Float>>.RawRepresentation

    let id: Int
    let position: Vec3<Float>

    init(id: Int, position: Vec3<Float>) {
        self.id = id
        self.position = position
    }

    func move(dx: Float = 0, dy: Float = 0, dz: Float = 0) -> Zone {
        Zone(id: self.id, position: Vec3(x: self.position.x + dx, y: self.position.y + dy, z: self.position.z + dz))
    }

    var rawRepresentation: RawRepresentation {
        T2(self.id, self.position).rawRepresentation
    }

    init(from rep: RawRepresentation) {
        self = Zone(id: rep._0, position: .init(from: rep._1))
    }

    static func random<T: RandomNumberGenerator>(using generator: inout T) -> Self {
        Zone(
            id: Int.random(using: &generator),
            position: Vec3<Float>.random(using: &generator)
        )
    }
}

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
