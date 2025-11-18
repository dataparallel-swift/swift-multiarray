// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-multiarray-benchmarks",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
    ],
    targets: [
        .executableTarget(
            name: "Benchmarks",
            dependencies: [
                .product(name: "MultiArray", package: "swift-multiarray"),
                .product(name: "Benchmark", package: "package-benchmark"),
            ],
            path: "Benchmarks",
            swiftSettings: [
                .unsafeFlags([
                    // "-Rpass-missed=specialize"
                ]),
            ],
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
    ]
)
