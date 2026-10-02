# Representing Custom Types

Derive or write the representation that backs a `MultiArray` element.

## Derive a representation

Apply ``Generic()`` to a struct whose stored properties conform to
``Generic``. The macro emits the conformance in an extension and preserves the
synthesized memberwise initializer. For larger structs, it creates a balanced
tree of ``Product`` values; a struct with no fields uses ``Unit``.

@Snippet(path: "Guide", slice: "generic")

Stored properties inside `#if` blocks are unsupported (including inactive
clauses), as are stored `let` properties initialized at their declaration.
Initialize immutable fields in an initializer instead; defaulted `var` fields
remain supported. Conditional methods and computed properties are allowed.
For conditional stored properties, write the `Generic` conformance by hand
instead of applying the macro.

Every stored property needs an explicit type annotation. Computed and static
properties are not part of the representation:

@Snippet(path: "Guide", slice: "computed")

Public structs may keep represented fields internal or private. In that case,
the generated conversion witnesses cannot be `@inlinable`. Because the
conformance is emitted in a file-scoped extension, a nested type annotated with
`@Generic` must be at least `fileprivate`, rather than `private`.

For generic structs, constrain represented type parameters to `Generic` on the
original declaration, as in `Vec3` above. The macro does not generate a conditional
conformance for otherwise unconstrained type parameters.

## Box other values

Use ``Box`` for a value that should remain part of each logical element but
cannot be decomposed into scalar storage. The ``Box()`` property macro provides
transparent access to mutable boxed properties:

@Snippet(path: "Guide", slice: "box")

Swift does not permit an accessor macro on a `let` declaration, so immutable
fields must use `Box<Value>` directly. Initializers for an `@Box` property must
initialize its underscored backing storage unless the property already has a
default value. Apply `@Box` to one explicitly typed stored `var` at a time,
not a multi-binding declaration such as `var a, b: String`.

## Represent raw-value enums

Apply `@Generic` to an enum backed by a supported integer or floating-point raw
type:

@Snippet(path: "Guide", slice: "status")

The derived representation is ``RawValueRepresentation``. Binary decoding
validates each stored raw value against the enum's domain. The storage format
contains only the raw representation tag, not the enum's surface type, so
applications must still decode a snapshot as the type that originally encoded
it.

Enums with associated values are not supported. The macro treats the first
inheritance entry as a possible raw type because attached macros cannot resolve
type names. A protocol-only declaration such as `enum E: CaseIterable`
therefore reaches normal Swift semantic checking and fails its generated
`RawRepresentable` requirement.

## Write a conformance by hand

Use an equivalent representation built from the supplied constructors and
provide conversions in both directions:

@Snippet(path: "Guide", slice: "manual-representation")

The conversion must preserve each logical value. Use `Unit` for no fields,
`Product` or the `T2`–`T16` helpers for multiple fields, and `Box` for values that
should not be decomposed. The module supplies representations for machine
integers and floating-point values, `Bool`, SIMD vectors, `Date`, and `UUID`.
`Float16` support is ARM64-only; `Int128`, `UInt128`, and `Float16` also have
platform availability requirements recorded on their conformances.

For a hand-written raw-value conformance, set
`RawRepresentation = RawValueRepresentation<Self>` to obtain the default
conversion witnesses and domain validation. This also works for retroactive
conformances of raw-value types declared in another module.
