import Benchmark
import Randy
import MultiArray

extension Vec3: Randomizable where Element: Randomizable {
    public static func random<T: RandomNumberGenerator>(using generator: inout T) -> Self {
        Vec3( x: Element.random(using: &generator)
            , y: Element.random(using: &generator)
            , z: Element.random(using: &generator))
    }
}

extension Zone: Randomizable {
    public static func random<T: RandomNumberGenerator>(using generator: inout T) -> Self {
        Zone( id: Int.random(using: &generator)
            , position: Vec3<Float>.random(using: &generator)
        )
    }
}

let benchmarks : @Sendable () -> Void = {
    var gen = UniformRandomNumberGenerator()
    let configs : [(Int, BenchmarkScalingFactor)] = [
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
        (10_000_000, .one)
    ]

    func config(_ scalingFactor: BenchmarkScalingFactor) -> Benchmark.Configuration
    {
        .init(
            metrics: [.wallClock, .allocatedResidentMemory], // , .cpuTotal, .cpuSystem, .cpuUser],
            warmupIterations: 3,
            scalingFactor: scalingFactor,
            maxDuration: .seconds(10)
        )
    }

    func setup(_ n: Int) -> (Array<Zone>, MultiArray<Zone>)
    {
        let xs = Array<Zone>.random(count: n, using: &gen)
        var ys = MultiArray<Zone>.init(unsafeUninitializedCapacity: n)

        for i in 0 ..< n {
            ys[i] = xs[i]
        }

        return (xs, ys)
    }

    func bench<Input, Output>(_ function: @escaping ((Input) -> Output)) -> (Benchmark, Input) -> Void {
        return { benchmark, input in
            // for _ in benchmark.scaledIterations {
                blackHole(function(input))
            // }
        }
    }

    // We need to generate the benchmark data anew in the setup function,
    // otherwise the benchmark framework will generate all data before any
    // benchmarking starts (which consumes a lot of memory...)
    for (size, scaling) in configs {
        Benchmark.init("array/move/\(size)",       configuration: config(scaling), closure: bench(readme1_array),      setup: { setup(size).0 })
        Benchmark.init("array/unzip/\(size)",      configuration: config(scaling), closure: bench(readme2_array),      setup: { setup(size).0 })
        Benchmark.init("multiarray/move/\(size)",  configuration: config(scaling), closure: bench(readme1_multiarray), setup: { setup(size).1 })
        Benchmark.init("multiarray/unzip/\(size)", configuration: config(scaling), closure: bench(readme2_multiarray), setup: { setup(size).1 })
    }
}

