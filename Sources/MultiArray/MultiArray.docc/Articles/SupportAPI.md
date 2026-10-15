# Representation Support API

Choose the representation API deliberately when writing a `MultiArray` element
by hand.

## Public element and storage API

``Generic`` and the ``Generic()`` macro define ordinary element types.
``Product``, ``Unit``, ``Box``, and ``RawValueRepresentation`` are public
representation constructors, useful when a derived representation is not
appropriate. ``Box()`` derives storage for a mutable boxed property. See
<doc:RepresentingCustomTypes> for examples and limitations.

``UninitializedMultiArrayData`` is the buffer passed to the synchronous
``MultiArray/init(unsafeUninitializedCapacity:initializingWith:)``. It is an
advanced construction API: initialize only the reported prefix and report its
length even if the closure throws.

## Advanced protocols and helpers

``ArrayData`` defines storage operations for raw representations. To store a new
application type, conform it to ``Generic`` and decompose it into the supplied
representations; do not add an `ArrayData` conformance just to make it
storable. A custom conformance is a low-level escape hatch for a specialized
physical layout, such as a bit-packed column, and incorrect memory management
can violate memory safety. ``BinaryArrayData`` is a further opt-in for
representations that can be safely encoded and decoded as a native binary
snapshot. ``BinaryMultiArrayError`` reports snapshot decoding failures.

The `T2` through `T16` tuple-like types help write representations with
multiple fields manually. They remain public and usable, though `@Generic`
normally generates a balanced ``Product`` tree without them.

``Sum`` is public and can model a choice between two `Generic` values, but it
does **not** conform to `ArrayData`. Consequently it cannot yet be used as a
`MultiArray` element's stored raw representation.
