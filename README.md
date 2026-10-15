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
scripts/test-asan-linux.sh --filter 'SanitizerSmokeTests|MutableCollectionTests|ThrowingInitTests|RepeatingInitializationTests|PartialInitializationArrayDataTests|AsyncInitializationTests|MultiArrayBufferTests|boxDoesNotLeak'
scripts/test-tsan-linux.sh --filter 'SanitizerSmokeTests|MutableCollectionTests|ThrowingInitTests|RepeatingInitializationTests|PartialInitializationArrayDataTests|AsyncInitializationTests|MultiArrayBufferTests|boxDoesNotLeak'
scripts/preflight.sh
```

Container-aware scripts use Swift 6.4 Noble by default (override with
`SWIFT_IMAGE`) and run through Podman on macOS. ASan checks memory lifetime;
TSan checks data races. Omit `--filter` to run all sanitizer-enabled tests. ASan
excludes the compiler subprocess suite `MacroDiagnosticCompilationTests` because
Foundation's `Process.run()` leaks bookkeeping on Linux Swift 6.4; those tests
remain enabled in normal debug/release runs. A sanitizer report fails the command
and is printed in the test output. CI runs the sanitizer suites on Linux x86-64.

The package supports Swift 6.0 through 6.4. CI tests every minor release in
that range with complete strict concurrency checking.

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
