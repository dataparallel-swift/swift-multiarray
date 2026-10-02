# Core Architecture

This document explains the storage design and why it takes this shape. Public
contracts and examples belong in the [DocC catalog](../Sources/MultiArray/MultiArray.docc/MultiArray.md)
and API comments; local unsafe-memory proofs belong beside their implementations.
Compiler support and development commands are listed in [README.md](../README.md).

## Representation decomposition

`Generic` separates an element's surface type from its storage representation.
Conversions map values to and from an equivalent `RawRepresentation` tree;
`ArrayData` interprets that tree as field-wise storage. Keeping these roles
separate lets a small set of constructors support arbitrary application types
without giving each type its own memory manager.

- Machine scalars terminate decomposition. `Int` and `UInt` use fixed-width
  representations; `Bool` uses `UInt8`.
- `Product<A, B>` combines fields recursively, avoiding opaque Swift struct
  padding. `Unit` is the zero-byte base case.
- `Box<T>` retains an ordinary Swift value instead of decomposing it. Its column
  uses typed initialization, assignment, and destruction to preserve ownership.
- `RawValueRepresentation<T>` stores the raw value while retaining the surface
  domain as type-level validation metadata.
- SIMD vectors remain single fields rather than becoming separate lane columns.
- `Sum` describes alternatives but does not yet implement `ArrayData`.

`@Generic` derives a balanced product tree and emits its conformance in an
extension, preserving the original struct's memberwise initializer. `@Box`
supplies boxed backing storage and transparent accessors. Derivation shares the
same storage operations as hand-written conformances; it is not a second memory
model. See [Representing Custom Types](../Sources/MultiArray/MultiArray.docc/Articles/RepresentingCustomTypes.md)
for supported declarations and manual conformance examples.

`ArrayData` is public and supports specialized physical layouts, but application
types should normally decompose into the supplied constructors instead. Custom
storage must preserve the allocation, lifetime, and concurrency invariants of
its callers.

## Allocation layout

```text
MultiArray<Element>
  └── MultiArrayData<Element.RawRepresentation> (reference-counted owner)
        ├── count: initialized prefix length
        ├── capacity: allocation extent
        ├── context: one heap allocation
        └── storage: typed field pointers into context

context: [field A × capacity][alignment gap][field B × capacity]...
```

Two recursive walks must agree: `rawSize(capacity:from:)` calculates the end
offset, and `reserve(capacity:from:)` carves out the corresponding typed regions.
Both follow scalar fields, not the size of an opaque nested product. The base
allocation is 16-byte aligned; field alignment must not exceed that alignment.
Sizing validates nonnegative inputs and representable arithmetic before memory
is reserved. Inter-column alignment gaps are zeroed.

The central invariant is `0 <= count <= capacity`. **Count controls collection
bounds and destruction; capacity controls field offsets.** A partially filled
allocation cannot be interpreted using count-sized offsets. Publishing a prefix
therefore changes count without relocating fields or reducing capacity.

## Ownership and publication

`MultiArray` has value semantics over a reference-counted allocation. Copies
initially share storage; all mutations must pass through `_prepareForMutation()`.
Shared storage detaches by copying each initialized field into a new allocation
with `capacity == count`. Scalar columns use bulk byte copies; boxed columns use
typed copies that retain their values. Uniquely owned storage keeps its capacity.
The collection is fixed-size even when its allocation has unused capacity.

Unfinished storage has a distinct cleanup owner until it can publish a valid
prefix. Prefix construction can use count-based destruction. Arbitrary-order
construction needs per-index tracking only for representations that require
destruction: `Box` does, and `Product` composes that requirement. Trivial scalar
storage can be abandoned without element cleanup. Keeping this capability in
`PartialInitializationArrayData` avoids imposing it on existing `ArrayData`
conformers. The async owner keeps the storage count at zero until publication,
so scattered cleanup and ordinary prefix destruction cannot both release the
same element. Caller obligations are documented in
[Constructing Arrays](../Sources/MultiArray/MultiArray.docc/Articles/ConstructingArrays.md).

`MultiArrayBuffer` deliberately has reference semantics and no CoW. This keeps
reusable scratch storage separate from value-semantic snapshots. Retaining its
owner keeps the allocation and boxed values alive; sharing raw pointers alone
does not. There is no zero-copy conversion between these owners while mutable
aliases can exist.

### Transferability

A transferable snapshot requires both `Element: Sendable` and
`Element.RawRepresentation: Sendable`. The surface condition covers reconstructed
values; the representation condition covers stored logical values. An open
`Generic` conformance can otherwise hide non-sendable state in its representation.
Neither condition makes raw pointers sendable. The owner or scoped view still
needs audited lifetime and synchronization guarantees.

Standard `Sendable` constraints are used rather than a new representation
protocol: Swift does not allow a conditional conformance to a non-marker protocol
to depend on the marker protocol `Sendable`. That would prevent the desired
`Box<T>` refinement for all sendable payloads. The remaining operational purity
obligations belong to the `Generic` and `ArrayData` contracts.

`BinaryArrayData` is orthogonal to transferability: it excludes boxed values,
including sendable payloads such as `String`, and cannot prove that an external
conversion or storage implementation is safe for concurrent reads. See
[Using Collections](../Sources/MultiArray/MultiArray.docc/Articles/UsingCollections.md)
for isolation and shared-scratch usage.

## Native snapshots

Binary tags describe the physical representation, not the surface Swift type.
This permits representation-compatible snapshots without a nominal schema.
`RawValueRepresentation<T>` preserves domain validation despite delegating tags
and layout to the raw value; `Product` composes validation. Decoding publishes
count only after validation, so invalid representations never become live
collection elements.

Snapshots use a canonical count-sized layout independent of unused capacity.
Exact-count storage can be copied directly; partially filled storage requires
field-wise prefix copies and zeroed alignment gaps. This pays for normalization
only at the serialization boundary, not during construction. Decoding allocates
exact-count storage. Compatibility limits and failure behavior belong in
[Serialization](../Sources/MultiArray/MultiArray.docc/Articles/Serialization.md).

## Cross-module specialization

Public representation conversions, `ArrayData` witnesses, and element-processing
operations are generally `@inlinable`. Optimized clients can then specialize the
representation tree into direct field accesses. Binary I/O, textual descriptions,
and once-per-allocation layout helpers are intentionally outside that policy.

`@inline(__always)` is reserved for measured compiler workarounds:
`MultiArray.init(count:with:)` needs it to expose the map loop to Swift 6.2's
vectorizer. `scripts/check-vectorization.sh` verifies an optimized external
client; future exceptions should likewise have a check or measurement. The
ordinary policy uses `@inlinable`, not `@_alwaysEmitIntoClient`. See
[Storage and Vectorization](../Sources/MultiArray/MultiArray.docc/Articles/StorageAndVectorization.md)
for the executable example and target-dependent SIMD widths.
