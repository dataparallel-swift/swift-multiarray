# Core Architecture

`MultiArray<Element>` decomposes each element into its raw scalar fields and
stores each field in its own region of a single contiguous allocation. Two
protocols do the work: `Generic` describes *how a type decomposes*, `ArrayData`
describes *how the decomposed pieces are stored*.

```swift
public struct MultiArray<Element> where Element: Generic, Element.RawRepresentation: ArrayData
```

## The `Generic` Protocol

`Generic` is an **open** protocol: it maps a type to an isomorphic
`RawRepresentation` built from a small set of constructors, plus conversions
to and from that representation. Users can conform their own types by hand.

- **Primitives** (`Int8`–`Int128`, `UInt8`–`UInt128`, `Float16`/`Float32`/`Float64`, `SIMD2`–`SIMD64`) have `RawRepresentation = Self`. `Int`/`UInt` map to their fixed-width equivalent, and `Bool` to `UInt8`. Some conformances are platform- or availability-gated (`Float16` is arm64-only; `Int128`/`UInt128` require newer OSes).
- **`Unit`** is the zero-byte base case (empty structs).
- **`Box<T>`** wraps types such as `String` whose values must be retained rather
  than copied as raw bytes.
- **`Product<A, B>`** pairs two `Generic` types; nested products represent
  multi-field structs.
- **`RawValueRepresentation<T>`** preserves a `RawRepresentable` type's value
  domain in the representation tree while storing only its raw value.
- **`Sum<A, B>`** exists for enum-like types but has no `ArrayData` conformance (not yet stored in SoA).

The module also ships conformances for `Date` (via `TimeInterval`) and `UUID`
(via `SIMD16<UInt8>`).

### Macro derivation

For structs, the `@Generic` macro derives `RawRepresentation`,
`rawRepresentation`, and `init(from:)` together in a conformance extension, so
the original declaration retains Swift's synthesized memberwise initializer.
It maps stored, explicitly typed properties into a balanced `Product` tree,
uses `Unit` for an empty struct, and ignores static and computed properties. A
generic struct states its `Generic` constraints on the declaration itself; the
generated extension uses those constraints without repeating its `where`
clause. Swift 6.3 accepts this complete extension-only conformance without the
historical circular-reference diagnostic.

For raw-value enums without associated values, `@Generic` derives a
`RawValueRepresentation<Self>` typealias and adds the same conformance. The
shared `RawRepresentable` protocol extension supplies the conversion witnesses,
so macro-derived and hand-written conformances have identical validation.

The `@Box` property macro turns a mutable, non-`Generic` field into transparent
get/set accessors backed by `Box<T>`. It preserves a property initializer on the
generated backing field. Swift does not allow accessor macros on `let`
declarations, so immutable values must use `Box<T>` explicitly. Hand-written
`RawValueRepresentation<Self>` conformances remain useful for retroactively
conforming raw-value types declared in other modules.

Macro-generated witnesses and accessors use `@inlinable` where their referenced
storage permits it. Public conversion witnesses retain the attribute only when
every encoded field is public or `@usableFromInline`; the backing storage
generated for a public `@Box` property satisfies that requirement. Private and
fileprivate witnesses omit the attribute because Swift does not permit it.
Protocol witnesses for a file-scope private type must themselves be
`fileprivate`. A private nested type cannot be named by the generated file-scope
extension, so `@Generic` diagnoses it and requires `fileprivate` access.

The `T2`–`T16` tuple helpers in `Support/Tuple.swift` are conveniences for
hand-written conformances. `Product` can be nested directly when another shape
is preferable.

## The `ArrayData` Protocol

`ArrayData` is a **closed** protocol describing how a type manages its own
memory within the SoA buffer. Key implementations:

| Type | Buffer | Notes |
|------|--------|-------|
| Primitives (`Buffer == UnsafeMutablePointer<Self>`) | `UnsafeMutablePointer<Self>` | Typed initialization and direct indexing |
| `Unit` | `Void` | Zero-byte, all operations are no-ops |
| `Box<T>` | `UnsafeMutablePointer<T>` | Manual init/deinit (ref-counted), no memcpy |
| `Product<A, B>` | `(A.Buffer, B.Buffer)` | Recursive: reserves space for both A and B back-to-back |
| `RawValueRepresentation<T>` | `T.RawValue.Buffer` | Delegates storage to the raw value while retaining `T` as type-level validation metadata |
| `SIMD<N>` | `UnsafeMutablePointer<Self>` | Stored as atomic blobs, **not** flattened to SoA |

### Cross-module specialization

Public representation conversions, `ArrayData` witnesses, and collection
operations on the element-access path are `@inlinable`. This exposes their
bodies to optimized clients so Swift can specialize the recursive
representation operations and reduce an element transformation to direct SoA
buffer accesses. Small forwarding constructors and accessors follow the same
rule. The project uses `@inlinable`, rather than the underscored
`@_alwaysEmitIntoClient`, as the ordinary cross-module optimization contract.

Inlining is not part of the policy for binary encoding and decoding, textual
descriptions, or other once-per-array control paths. In particular,
`firstInvalidElement` may scan decoded storage, but it is a safety check at the
binary I/O boundary rather than an element-processing primitive. The internal
layout helpers `getRawSize` and `reserveCapacity` are also intentionally opaque:
they run once per allocation, while their `ArrayData` callers remain
`@inlinable`.

`@inline(__always)` is reserved for a measured compiler workaround. Swift 6.2
requires it on `MultiArray.init(count:with:)` to expose the loop generated by
`map`; `scripts/check-vectorization.sh` compiles an optimized external client
and verifies the resulting vector IR. Any future exception to the general rule
must likewise name the check or measurement that requires it.

## Binary snapshots and representation validation

Binary type tags describe only the physical `RawRepresentation`, never the
surface Swift type. Consequently a `UInt8` snapshot and a snapshot of a
`UInt8`-backed enum have identical tags and layouts. This is intentional: the
format is a representation-level memory snapshot rather than a nominal schema.

`RawValueRepresentation<T>` prevents that choice from compromising safety. Its
`BinaryArrayData` conformance delegates the type tag and buffer layout to
`T.RawValue`, but validates each raw value with `T(rawValue:)` after the payload
copy. `Product` composes this validation recursively, so a constrained enum
nested inside a product is validated without help from the surface type or a
macro. The decoder publishes the element count only after validation succeeds;
an invalid value throws `BinaryMultiArrayError.invalidRawRepresentation` at the
decode boundary.

## Storage Layout

```
MultiArray<Element>
  └── arrayData: MultiArrayData<Element.RawRepresentation>  (reference-counted class)
        ├── count: Int
        ├── context: UnsafeMutableRawPointer  (single heap allocation)
        └── storage: A.Buffer  (tuple of typed pointers into context)

Single allocation (context):
  [Field_A_data...][padding?][Field_B_data...][padding?][Field_C_data...]
```

The layout is computed by walking the `Product` tree twice, and the two walks
must agree: `rawSize(capacity:from:)` accumulates alignment padding and strides
to size the allocation up front, then `reserve(capacity:from:)` walks it again
to carve out the aligned regions and hand back the tuple of typed pointers.
Padding between regions is zero-initialized.

## Mutation and ownership

`MultiArrayData` is a class, so assigning a `MultiArray` shares the buffer.
`MultiArray` nevertheless has value semantics: before indexed mutation,
`_prepareForMutation()` checks whether the buffer is uniquely referenced and
deep-copies every field buffer when it is shared. Scalar fields are copied as
bytes, while `Box` fields are initialized as values so their payloads are
retained correctly. All current and future operations that write to
`arrayData` must route through this helper.

Storage is allocated for exactly `count` elements and the collection is
currently fixed-size.

`MultiArray` does not conform to `Sendable`; an instance must remain within one
concurrency isolation domain.

## Uninitialized construction

`init(unsafeUninitializedCapacity:initializingWith:)` supports bulk construction
by handing its closure an `UninitializedMultiArrayData<Element>` view over the
raw storage, typed in terms of the surface `Element` rather than its
`RawRepresentation`. The closure initializes a prefix of that storage and
reports its length through an `inout` count. It must report the initialized
prefix even when it throws, normally with `defer`; `MultiArrayData.deinit` uses
that count to destroy exactly the initialized elements. Reporting too few
elements leaks their resources, while reporting too many deinitializes
uninitialized memory and is undefined behaviour.
