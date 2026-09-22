# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Architecture documentation
- Developer scripts for Linux and macOS builds, tests, formatting, and preflight checks
- `Generic` witnesses and structurally validated storage for `RawRepresentable` types
- `@Generic` derivation for structs: balanced tree representation with no property count limit, preserved memberwise initializers, and non-public encoded fields; stored properties without an explicit type annotation and private nested types are diagnosed
- `@Generic` derivation for raw-value enums; enums with associated values or with no possible raw type are diagnosed
- `@Box` for transparently storing mutable non-`Generic` properties, including default values; stored properties without an explicit type annotation are diagnosed, and an invalid `@Box` declaration does not cascade into `@Generic` errors
- `Box: Equatable` conformance
- Checked conditional `Sendable` conformances for the representation constructors
- DocC guides with compiler-checked examples and a cross-version automatic-vectorization regression check

### Changed

- Update the project's lint and formatting rules
- Support SwiftSyntax releases from 600 through 603
- Reorganize the test suite and expand coverage for empty arrays, Boolean fields, and large arrays
- **Breaking:** Change `init(unsafeUninitializedCapacity:initializingWith:)` to report the number of initialized elements, preventing undefined behaviour and leaks when initialization throws
- Improve `init(repeating:count:)` by decomposing the repeated value only once
- Remove redundant per-element platform integer layout assertions

### Fixed

- Avoid force-unwrapping unavailable `Data` storage during binary decoding
- Reject out-of-domain `RawRepresentable` values during binary decoding
- Preserve `MultiArray` value semantics by copying shared storage before indexed mutation
- Remove unstable raw storage addresses from `MultiArray.debugDescription`
- Restore automatic vectorization of `MultiArray.map` with Swift 6.2 and later

## [2.1.0] - 2025-12-16

### Added

- Generic conformance for (unboxed) UUID and Date
- Explicit version tag in Codable instances

### Changed

- Box's type parameter from `A` to `Element`

### Fixed

- Box's payloads are correctly initialised and deinitialised

## [2.0.0] - 2025-12-10

### Added

- Protocol conformances to:
    - Equatable
    - Hashable
    - Encodable
    - Decodable
    - CustomStringConvertible
    - CustomDebugStringConvertible
    - ExpressibleByArrayLiteral
    - MutableCollection
    - RandomAccessCollection

### Changed

- Rename `Generic.Representation` to `Generic.RawRepresentation`
- Convert `Generic.from` from static function to computed property
- Convert `Generic.to` from static function to type initialiser

## [1.0.0] - 2025-11-25

### Added

- Initial release

[Unreleased]: https://github.com/dataparallel-swift/swift-multiarray/compare/2.1.0...HEAD
[2.1.0]: https://github.com/dataparallel-swift/swift-multiarray/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/dataparallel-swift/swift-multiarray/compare/1.0.0...2.0.0
[1.0.0]: https://github.com/dataparallel-swift/swift-multiarray/releases/tag/1.0.0
