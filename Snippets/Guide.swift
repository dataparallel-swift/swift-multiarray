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

// snippet.point
@Generic
struct Point {
    var x: Double
    var y: Double
}

func makePoints() -> MultiArray<Point> {
    [
        Point(x: 1, y: 2),
        Point(x: 3, y: 4),
    ]
}

// snippet.end

// snippet.generic
@Generic
struct Vec3<Element> where Element: Generic {
    let x, y, z: Element
}

@Generic
struct Zone {
    let id: Int8
    let position: Vec3<Float>
}

// snippet.end

// snippet.box
@Generic
struct Labeled {
    let label: Box<String>
    let value: Float
}

@Generic
struct LabeledWithMacro {
    @Box var label: String
    let value: Float

    init(label: String, value: Float) {
        self._label = Box(label)
        self.value = value
    }
}

// snippet.end

// snippet.computed
@Generic
struct Vec2 {
    var x: Float
    var y: Float
    var magnitude: Float { (self.x * self.x + self.y * self.y).squareRoot() }
}

// snippet.end

// snippet.status
@Generic
enum Status: UInt8 {
    case off = 0
    case on = 1
}

// snippet.end

// snippet.ordinary-construction
func ordinaryConstruction() -> MultiArray<Int32> {
    let repeated = MultiArray<Int32>(repeating: 7, count: 3)
    let generated = MultiArray<Int32>(count: 3) { Int32($0) }
    let copied = MultiArray(generated)
    precondition(Array(repeated) == [7, 7, 7])
    return copied
}

// snippet.end

// snippet.sync-construction
func makePrefix() -> MultiArray<Int32> {
    MultiArray<Int32>(unsafeUninitializedCapacity: 4) { buffer, initializedCount in
        var initialized = 0
        defer { initializedCount = initialized }
        for index in 0 ..< 3 {
            buffer.initializeElement(at: index, to: Int32(index))
            initialized += 1
        }
    }
}

// snippet.end

// snippet.async-construction
func makeInParallel() async -> MultiArray<Int32> {
    await MultiArray<Int32>(unsafeUninitializedCapacity: 4) { buffer, initializedCount async in
        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< buffer.count {
                group.addTask {
                    buffer.initializeElement(at: index, to: Int32(index))
                }
            }
        }
        initializedCount = buffer.count
    }
}

// snippet.end

// snippet.manual-representation
struct Measurement: Generic {
    var value: Double
    var label: String

    typealias RawRepresentation = Product<Double, Box<String>>

    var rawRepresentation: RawRepresentation {
        Product(self.value, Box(self.label))
    }

    init(value: Double, label: String) {
        self.value = value
        self.label = label
    }

    init(from representation: RawRepresentation) {
        self.value = representation._0
        self.label = representation._1.unbox
    }
}

// snippet.end

// snippet.collection
func copyAndTransform() -> MultiArray<Point> {
    let original = makePoints()
    var copy = original
    copy[0] = Point(x: 10, y: 20)
    precondition(original[0].x == 1)

    let shifted: MultiArray<Point> = copy.map { Point(x: $0.x + 1, y: $0.y) }
    return shifted
}

// snippet.end

// snippet.snapshot-concurrency
func independentCopies() async -> [Int32] {
    let snapshot = MultiArray<Int32>([1, 2, 3])
    let results = await withTaskGroup(of: Int32.self, returning: [Int32].self) { group in
        for increment in Int32(1) ... 2 {
            group.addTask {
                var local = snapshot
                local[0] += increment
                return local[0]
            }
        }
        var results: [Int32] = []
        for await value in group {
            results.append(value)
        }
        return results.sorted()
    }
    precondition(snapshot[0] == 1)
    return results
}

// snippet.end

// snippet.scratch
func reuseScratch() -> Int32 {
    let scratch = MultiArrayBuffer<Int32>(repeating: 0, count: 4)
    let alias = scratch
    scratch[1] = 42
    return alias[1] // Both handles refer to the same allocation.
}

// snippet.end

// snippet.codable
func codingRoundTrip() throws -> MultiArray<Int32> {
    let values = MultiArray<Int32>([1, 2, 3])
    let json = try JSONEncoder().encode(values)
    return try JSONDecoder().decode(MultiArray<Int32>.self, from: json)
}

// snippet.end

// snippet.binary-snapshot
func snapshotRoundTrip() throws -> MultiArray<Status> {
    let values = MultiArray<Status>([.off, .on])
    let data = values.encode()
    return try MultiArray<Status>(data: data)
}

// snippet.end

func guideExamples() {
    let points = makePoints()
    precondition(points.count == 2)
    precondition(points[1].x == 3)

    let zones: MultiArray<Zone> = [Zone(id: 1, position: Vec3(x: 2, y: 3, z: 4))]
    precondition(zones[0].position.z == 4)

    let labels: MultiArray<LabeledWithMacro> = [LabeledWithMacro(label: "temperature", value: 21)]
    precondition(labels[0].label == "temperature")

    let statuses: MultiArray<Status> = [.off, .on]
    precondition(statuses[1] == .on)

    precondition(Array(makePrefix()) == [0, 1, 2])
    precondition(Array(ordinaryConstruction()) == [0, 1, 2])

    let measurement = Measurement(value: 21, label: "temperature")
    let measurements = MultiArray([measurement])
    precondition(measurements[0].value == 21)
    precondition(measurements[0].label == "temperature")
    precondition(copyAndTransform()[0].x == 11)
    precondition(reuseScratch() == 42)
}

guideExamples()

let parallel = await makeInParallel()
precondition(Array(parallel) == [0, 1, 2, 3])

let independent = await independentCopies()
precondition(independent == [2, 3])
let decoded = try codingRoundTrip()
precondition(Array(decoded) == [1, 2, 3])
let restored = try snapshotRoundTrip()
precondition(Array(restored) == [.off, .on])
