# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [next]

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

[next]: https://github.com/dataparallel-swift/swift-multiarray/compare/2.1.0...HEAD
[2.1.0]: https://github.com/dataparallel-swift/swift-multiarray/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/dataparallel-swift/swift-multiarray/compare/1.0.0...2.0.0
[1.0.0]: https://github.com/dataparallel-swift/swift-multiarray/releases/tag/1.0.0
