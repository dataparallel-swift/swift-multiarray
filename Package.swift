// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-multiarray",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "MultiArray", targets: ["MultiArray"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0" ..< "603.0.0"),
    ],
    targets: [
        .target(
            name: "MultiArray",
            dependencies: [
                "MultiArrayMacros",
            ]
        ),
        .macro(
            name: "MultiArrayMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "MultiArrayTests",
            dependencies: [
                "MultiArray",
            ]
        ),
    ]
)
