// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-multiarray",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "MultiArray", targets: ["MultiArray"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1-latest"),
        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
        .package(url: "git@gitlab.com:PassiveLogic/Randy.git", from: "0.4.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "MultiArrayMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/swift-multiarray-macros"
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(
            name: "MultiArray",
            dependencies: [
                "MultiArrayMacros"
            ],
            path: "Sources/swift-multiarray"
        ),

        // Benchmarks
        .target(
            name: "BenchmarkFunctions",
            dependencies: [
                "MultiArray"
            ],
            path: "Benchmarks/benchmark-functions",
            swiftSettings: [
                .unsafeFlags([
                    "-O",
                    // "-emit-ir"
                ])
            ]
        ),
        .executableTarget(
            name: "bench-readme",
            dependencies: [
                "Randy",
                "BenchmarkFunctions",
                .product(name: "Benchmark", package: "package-benchmark")
            ],
            path: "Benchmarks/readme",
            swiftSettings: [
                .unsafeFlags([
                    // "-Rpass-missed=specialize"
                ])
            ],
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),

        // A test target used to develop the macro implementation.
        // .testTarget(
        //     name: "swift-multiarray-tests",
        //     dependencies: [
        //         "swift-multiarray-macros",
        //         .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
        //     ]
        // ),
    ]
)
