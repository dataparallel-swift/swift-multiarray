# Using Collections

Read and replace values with collection semantics, or deliberately choose shared
scratch storage.

## Fixed-size value semantics

``MultiArray`` is a `RandomAccessCollection` and `MutableCollection`, with integer
indices in `0..<count`. Indexed reads reconstruct ordinary element values;
assignments replace an existing element. The collection does not support append
or resizing and does not conform to `RangeReplaceableCollection`.

Copies initially share storage. Mutating one copy detaches shared storage without
changing the other copy:

@Snippet(path: "Guide", slice: "collection")

Like `Array`, copying a boxed reference retains that reference; it does not clone
the referenced object. Element replacement has value semantics, but mutations
inside an element's reference-valued payload follow that payload's own semantics.

The specialized ``MultiArray/map(_:)`` returns another `MultiArray`. Through a
generic `Sequence` interface, the standard `map` returns an `Array` instead.
Use <doc:StorageAndVectorization> to understand the optimization opportunity;
vectorization is not guaranteed for arbitrary transforms.

Both `description` and `debugDescription` include every element. For bounded
logging, describe `Array(values.prefix(limit))` rather than the whole collection.

## Across isolation domains

A `MultiArray` is `Sendable` when both `Element` and `Element.RawRepresentation`
are `Sendable`. Immutable copies can be read concurrently; task-local mutable
copies detach when necessary:

@Snippet(path: "Guide", slice: "snapshot-concurrency")

This does not allow concurrent access to a single shared mutable variable.
Protect such a variable with actor isolation or another synchronization mechanism.
An actor is an isolation domain, not a dedicated thread. The tasks above can
share an allocation for reads while retaining separate local values for mutation.
Custom representations must also uphold the purity requirements of ``Generic``
and ``ArrayData``.

## Reusable reference-semantic scratch

``MultiArrayBuffer`` holds a fixed number of initialized elements. Assignments
write in place, and all references to the owner observe the same storage:

@Snippet(path: "Guide", slice: "scratch")

This type is not a collection and does not conform to `Sendable`. An adapter
that deliberately shares it across isolation domains must keep the owner alive
and audit synchronization: read/write pairs and multiple writes must use disjoint
logical indices, or overlapping access must be synchronized. Custom conversions
and storage operations must not introduce shared mutable state behind otherwise
disjoint indices. `@unchecked Sendable` in an adapter declares this responsibility;
it does not add synchronization. Prefer ordinary `MultiArray` snapshots unless
the algorithm specifically needs shared in-place writes.
