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
            setup: { setup(size: size) }
        )
        Benchmark(
            "array/unzip/\(size)",
            configuration: .init(scalingFactor: scaling),
            closure: { _, input in
                blackHole(input.map(\.position.x))
            },
            setup: { setup(size: size) }
        )
        Benchmark(
            "multiarray/move/\(size)",
            configuration: .init(scalingFactor: scaling),
            closure: { _, input in
                blackHole(input.map { $0.move(dx: 1) })
            },
            setup: { MultiArray(setup(size: size)) }
        )
        Benchmark(
            "multiarray/unzip/\(size)",
            configuration: .init(scalingFactor: scaling),
            closure: { _, input in
                blackHole(input.map(\.position.x))
            },
            setup: { MultiArray(setup(size: size)) }
        )
    }

    func setup(size: Int) -> Array<Zone> {
        randomArray(count: size, using: &gen)
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
    typealias RawRepresentation = T3<Element, Element, Element>.RawRepresentation

    @inlinable
    var rawRepresentation: RawRepresentation {
        T3(x, y, z).rawRepresentation
    }

    @inlinable
    init(from rep: RawRepresentation) {
        let tup = T3<Element, Element, Element>(from: rep)
        self.x = tup._0
        self.y = tup._1
        self.z = tup._2
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
    typealias RawRepresentation = T2<Int, Vec3<Float>>.RawRepresentation

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
    var rawRepresentation: RawRepresentation {
        T2(self.id, self.position).rawRepresentation
    }

    @inlinable
    init(from rep: RawRepresentation) {
        self.id = rep._0
        self.position = Vec3<Float>(from: rep._1)
    }
}
