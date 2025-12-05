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

import Benchmark
import MultiArray

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration = .init(
        metrics: [.wallClock, .allocatedResidentMemory], // , .cpuTotal, .cpuSystem, .cpuUser],
        warmupIterations: 3,
        maxDuration: .seconds(10)
    )

    var gen = SystemRandomNumberGenerator()
    let configs: [(Int, BenchmarkScalingFactor)] = [
        // (100, .one),
        // (1000, .one),
        (10_000, .one),
        // (25_000, .one),
        // (50_000, .one),
        // (75_000, .one),
        (100_000, .one),
        // (250_000, .one),
        // (500_000, .one),
        // (750_000, .one),
        (1_000_000, .one),
        // (2_500_000, .one),
        // (5_000_000, .one),
        // (7_500_000, .one),
        (10_000_000, .one),
    ]

    // We need to generate the benchmark data anew in the setup function,
    // otherwise the benchmark framework will generate all data before any
    // benchmarking starts (which consumes a lot of memory...)
    for (size, scaling) in configs {
        Benchmark(
            "array/move/\(size)",
            configuration: .init(scalingFactor: scaling),
            closure: { _, input in
                blackHole(input.map { $0.move(dx: 1) })
            },
            setup: { setupArray(size: size) }
        )
        Benchmark(
            "array/unzip/\(size)",
            configuration: .init(scalingFactor: scaling),
            closure: { _, input in
                blackHole(input.map(\.position.x))
            },
            setup: { setupArray(size: size) }
        )
        Benchmark(
            "multiarray/move/\(size)",
            configuration: .init(scalingFactor: scaling),
            closure: { _, input in
                blackHole(input.map { $0.move(dx: 1) })
            },
            setup: { setupMultiArray(size: size) }
        )
        Benchmark(
            "multiarray/unzip/\(size)",
            configuration: .init(scalingFactor: scaling),
            closure: { _, input in
                blackHole(input.map(\.position.x))
            },
            setup: { setupMultiArray(size: size) }
        )
    }

    func setupArray(size: Int) -> Array<Zone> {
        randomArray(count: size, using: &gen)
    }

    func setupMultiArray(size: Int) -> MultiArray<Zone> {
        let array = setupArray(size: size)
        let multiArray = array.toMultiArray()
        return multiArray
    }
}

struct Vec3<Element> {
    @usableFromInline
    let x, y, z: Element

    @inlinable
    @_alwaysEmitIntoClient
    public init(x: Element, y: Element, z: Element) {
        self.x = x
        self.y = y
        self.z = z
    }
}

extension Vec3: Generic where Element: Generic {
    typealias Representation = T3<Element, Element, Element>.Representation

    @inlinable
    @_alwaysEmitIntoClient
    static func from(_ self: Self) -> Self.Representation {
        T3.from(T3(self.x, self.y, self.z))
    }

    @inlinable
    @_alwaysEmitIntoClient
    static func to(_ rep: Self.Representation) -> Self {
        let T3 = T3<Element, Element, Element>.to(rep)
        return Vec3(x: T3._0, y: T3._1, z: T3._2)
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

struct Zone: Randomizable & Generic {
    typealias Representation = T2<Int, Vec3<Float>>.Representation

    @usableFromInline
    let id: Int

    @usableFromInline
    let position: Vec3<Float>

    @inlinable
    @_alwaysEmitIntoClient
    public init(id: Int, position: Vec3<Float>) {
        self.id = id
        self.position = position
    }

    @inlinable
    @_alwaysEmitIntoClient
    func move(dx: Float = 0, dy: Float = 0, dz: Float = 0) -> Zone {
        Zone(id: self.id, position: Vec3(x: self.position.x + dx, y: self.position.y + dy, z: self.position.z + dz))
    }

    static func random<T: RandomNumberGenerator>(using generator: inout T) -> Self {
        Zone(
            id: Int.random(using: &generator),
            position: Vec3<Float>.random(using: &generator)
        )
    }

    @inlinable
    @_alwaysEmitIntoClient
    static func from(_ self: Self) -> Self.Representation {
        T2.from(T2(self.id, self.position))
    }

    @inlinable
    @_alwaysEmitIntoClient
    static func to(_ rep: Self.Representation) -> Self {
        let T2 = T2<Int, Vec3<Float>>.to(rep)
        return Zone(id: T2._0, position: T2._1)
    }
}
