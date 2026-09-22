# Representing Custom Types

Derive or write the representation that backs a `MultiArray` element.

## Derive a representation

Apply ``Generic()`` to a struct whose stored properties conform to
``Generic``. The macro emits the conformance in an extension and preserves the
synthesized memberwise initializer. For larger structs, it creates a balanced
tree of ``Product`` values; a struct with no fields uses ``Unit``.

@Snippet(path: "Guide", slice: "generic")

Every stored property needs an explicit type annotation. Computed properties
are not part of the representation:

@Snippet(path: "Guide", slice: "computed")

Public structs may keep represented fields internal or private. In that case,
the generated conversion witnesses cannot be `@inlinable`. Because the
conformance is emitted in a file-scoped extension, a nested type annotated with
`@Generic` must be at least `fileprivate`, rather than `private`.

## Box other values

Use ``Box`` for a value that should remain part of each logical element but
cannot be decomposed into scalar storage. The ``Box()`` property macro provides
transparent access to mutable boxed properties:

@Snippet(path: "Guide", slice: "box")

Swift does not permit an accessor macro on a `let` declaration, so immutable
fields must use `Box<Value>` directly. Initializers for an `@Box` property must
initialize its underscored backing storage.

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
