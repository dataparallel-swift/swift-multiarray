# swift-multiarray

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdataparallel-swift%2Fswift-multiarray%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/dataparallel-swift/swift-multiarray)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdataparallel-swift%2Fswift-multiarray%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/dataparallel-swift/swift-multiarray)

`MultiArray<Element>` stores heterogeneous values in struct-of-arrays form:
each scalar field has its own contiguous buffer. The layout improves locality,
avoids per-element padding, and lets Swift vectorize suitable operations over
the collection.

Use `@Generic` to derive the representation of a struct or raw-value enum. See
the [MultiArray documentation](https://swiftpackageindex.com/dataparallel-swift/swift-multiarray/documentation/multiarray)
for a compiled introduction, custom representations, boxed fields, raw-value
enums, storage layout, and the verified vectorization example.

## Development

Linux containers are the authoritative build environment:

```sh
scripts/build-linux.sh
scripts/test-linux.sh
scripts/check-vectorization.sh
scripts/check-sendability.sh
scripts/check-concurrency-signatures.sh
scripts/test-asan-linux.sh
scripts/test-tsan-linux.sh
scripts/preflight.sh
```

Container-aware scripts use Swift 6.4 Noble by default (override with
`SWIFT_IMAGE`) and run through Podman on macOS. ASan checks memory lifetime;
TSan checks data races. TSan runs the full suite while ASan excludes the
compiler subprocess suite `MacroDiagnosticCompilationTests` because Foundation's
`Process.run()` leaks bookkeeping on Linux Swift 6.4. A sanitizer report fails
the command and is printed in the test output.

The package supports Swift 6.0 through 6.4. CI tests every minor release in
that range in debug and release with complete strict concurrency checking.
Set `SWIFT_BUILD_CONFIGURATION=debug` to use debug builds locally; ordinary
build and test scripts default to release.
Declared deployment floors are macOS 10.15, iOS 12, tvOS 12, and watchOS 9;
the async initializer requires iOS/tvOS 13. CI validates Linux and macOS,
not the other declared Apple platforms.

The [architecture notes](docs/ARCHITECTURE.md) explain decomposition, allocation,
and ownership decisions. API contracts and usage examples live in DocC and the
public source comments.

On macOS, use the native build and test entry points when checking that
platform:

```sh
scripts/build-macos.sh
scripts/test-macos.sh
```

Build or serve the documentation with DocC tools and the containerized Swift
build:

```sh
scripts/build-docs.sh
scripts/build-docs.sh --serve
```

## License

swift-multiarray is available under the Apache License 2.0. See `LICENSE` for
details.
