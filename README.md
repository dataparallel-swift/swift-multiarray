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
scripts/preflight.sh
```

The package supports Swift 6.0 through 6.4. CI tests every minor release in
that range with complete strict concurrency checking.

On macOS, build or serve the documentation with Xcode's DocC tools and the
containerized Swift build:

```sh
scripts/build-docs.sh
scripts/build-docs.sh --serve
```

## License

swift-multiarray is available under the Apache License 2.0. See `LICENSE` for
details.
