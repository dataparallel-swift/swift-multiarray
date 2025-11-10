// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-multiarray-benchmarks",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
        .package(url: "git@gitlab.com:PassiveLogic/Randy.git", from: "0.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "Benchmarks",
            dependencies: [
                "Randy",
                .product(name: "MultiArray", package: "swift-multiarray"),
                .product(name: "Benchmark", package: "package-benchmark")
            ],
            path: "Benchmarks",
            swiftSettings: [
                .unsafeFlags([
                    // "-Rpass-missed=specialize"
                ])
            ],
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
    ]
)
