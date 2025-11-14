// Copyright (c) 2025 PassiveLogic, Inc.

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
                blackHole(input.map { $0.position.x })
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
                blackHole(input.map { $0.position.x })
            },
            setup: { setupMultiArray(size: size) }
        )
    }

    func setupArray(size: Int) -> Array<Zone> {
        return randomArray(count: size, using: &gen)
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
    @inline(__always)
    public init(x: Element, y: Element, z: Element) {
        self.x = x
        self.y = y
        self.z = z
    }
}

extension Vec3: Generic where Element: Generic {
    typealias Rep = T3<Element, Element, Element>.Rep

    @inlinable
    @inline(__always)
    static func from(_ self: Self) -> Self.Rep {
        T3.from(T3(self.x, self.y, self.z))
    }

    @inlinable
    @inline(__always)
    static func to(_ rep: Self.Rep) -> Self {
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
    typealias Rep = T2<Int, Vec3<Float>>.Rep

    @usableFromInline
    let id: Int

    @usableFromInline
    let position: Vec3<Float>

    @inlinable
    @inline(__always)
    public init(id: Int, position: Vec3<Float>) {
        self.id = id
        self.position = position
    }

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
    @inline(__always)
    static func from(_ self: Self) -> Self.Rep {
        T2.from(T2(self.id, self.position))
    }

    @inlinable
    @inline(__always)
    static func to(_ rep: Self.Rep) -> Self {
        let T2 = T2<Int, Vec3<Float>>.to(rep)
        return Zone(id: T2._0, position: T2._1)
    }
}
