# swift-multiarray

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdataparallel-swift%2Fswift-multiarray%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/dataparallel-swift/swift-multiarray)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdataparallel-swift%2Fswift-multiarray%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/dataparallel-swift/swift-multiarray)

An array that stores elements in unboxed struct-of-array style. This can provide
better data locality and enable efficient (automatic) vectorization.

## The `@Generic` Macro

In order to store values in unboxed struct-of-array style, array elements must
conform to the `Generic` protocol. This protocol decomposes a struct into a tree
of `Product<A, B>` pairs that eventually resolve to scalar primitives (`Int8`–`Int128`,
`UInt8`–`UInt128`, `Float16`/`Float32`/`Float64`, `Bool`, `SIMD<N>`).

Rather than writing the decomposition by hand, use the `@Generic` macro:

```swift
@Generic
struct Point {
    var x: Double
    var y: Double
}
```

The macro emits the complete conformance in an extension, preserving Swift's
synthesized memberwise initializer. For this 2-field struct it generates:

```swift
extension Point: Generic {
    typealias RawRepresentation = Product<Double.RawRepresentation, Double.RawRepresentation>

    @inlinable
    var rawRepresentation: RawRepresentation {
        Product(self.x.rawRepresentation, self.y.rawRepresentation)
    }

    @inlinable
    init(from rep: RawRepresentation) {
        self.x = Double(from: rep._0)
        self.y = Double(from: rep._1)
    }
}
```

For structs with more fields, the macro builds a balanced binary tree of nested
`Product` values. The `T2`, `T3`, ... `T16` helpers still exist for hand-written
conformances.

### More examples

**Three fields:**

```swift
@Generic
struct Vec3<Element> where Element: Generic {
    let x, y, z: Element
}
```

**Nested `Generic` types:**

```swift
@Generic
struct Zone {
    let id: Int8
    let position: Vec3<Float>
}
```

**Non-`Generic` fields (e.g. `String`):**

Wrap them in `Box<T>` manually, or use the `@Box` property macro:

```swift
@Generic
struct Labeled {
    // Manual Box wrapping
    let label: Box<String>
    let value: Float
}

@Generic
struct LabeledWithMacro {
    // @Box adds a backing _name: Box<T> and transparent get/set accessors
    @Box var label: String
    let value: Float

    // You must update any initialisers to refer to the backing store
    init(label: String, value: Float) {
        self._label = Box(label)
        self.value = value
    }
}
```

Note that Swift does not allow `@attached(accessor)` macros on `let`
declarations, so the macro can not be applied to any immutable fields you wish
to box.

**Computed properties are excluded:**

```swift
@Generic
struct Vec2 {
    var x: Float
    var y: Float
    var magnitude: Float { (x * x + y * y).squareRoot() } // excluded
}
```

Every stored property must have an explicit type annotation; `@Generic`
diagnoses inferred stored properties rather than silently omitting them.
Computed properties (getter-only or get/set) are skipped. Properties with
`willSet`/`didSet` observers are treated as stored properties and included.
Public structs may keep encoded fields internal or private; the generated
conversion witnesses omit `@inlinable` when required by that encapsulation.
Because the conformance is emitted in a file-scoped extension, a nested type
annotated with `@Generic` must be at least `fileprivate`, not `private`.

**Property count:** Any number of stored properties is supported. Zero-field
structs use `Unit` (the zero-byte base case).

### Raw-value enums

Apply `@Generic` to a raw-value enum to retain its value-domain constraint while
storing only the underlying scalar:

```swift
@Generic
enum Status: UInt8 {
    case off = 0
    case on = 1
}
```

This derives the same conformance that can be written by hand when retroactively
conforming a type from another module:

```swift
extension Status: Generic {
    typealias RawRepresentation = RawValueRepresentation<Self>
}
```

Enums with associated values are not supported.

The macro treats the first entry in an enum's inheritance clause as a possible
raw type because attached macros cannot resolve type names. A protocol-only
clause such as `enum Status: CaseIterable` therefore proceeds to normal Swift
semantic checking, which reports that the enum is not `RawRepresentable`.

Binary snapshots continue to encode only the `UInt8` representation tag. Raw
values are validated as `Status` during decoding, including when the value is a
field nested inside a product representation.

### SIMD values

SIMD values are atomic fields for SoA storage. For example, a
`MultiArray<SIMD4<Float>>` stores one contiguous buffer of `SIMD4<Float>` values;
it does not split the four lanes into four `Float` buffers. SIMD vectors already
provide the intended contiguous, vector-friendly layout.

As far as the compiler is concerned, the in-memory layout of `Point` and
`Point.RawRepresentation` are identical -- `Product` is a simple pair type, and
larger structs are represented as balanced `Product` trees. With sufficient
inlining, this representation change is a no-op.

For example, suppose we have a `move` function that shifts every `Zone` by a
given offset:

```swift
extension Zone {
    func move(dx: Float = 0, dy: Float = 0, dz: Float = 0) -> Zone {
        Zone(id: self.id,
             position: Vec3(x: self.position.x + dx,
                            y: self.position.y + dy,
                            z: self.position.z + dz))
    }
}
```

In a regular Swift `Array` the fields of `Zone` are stored contiguously as
array-of-structs (on a 64-bit system):

```
                            1        1        2        2        2        3
 0        4        8        2        6        0        4        8        2
+--------+--------+--------+--------+--------+--------+--------+--------+--------+
| id0             | x0     | y0     | z0     | <pad>  | id1             | x1     | ...
+--------+--------+--------+--------+--------+--------+--------+--------+--------+
```

Due to alignment, 4 bytes of padding per element wastes ~16% of bandwidth. The
compiler can partially vectorize (pairing `x` and `y` into a `<2 x float>` load)
but is hamstrung by the interleaved layout.

With `MultiArray`, each field gets its own contiguous buffer:

```
+--------+--------+--------+--------+--------+--------+
| id0             | id1             | id2             | ...
+--------+--------+--------+--------+--------+--------+

+--------+--------+--------+--------+--------+--------+
| x0     | x1     | x2     | x3     | x4     | x5     | ...
+--------+--------+--------+--------+--------+--------+

+--------+--------+--------+--------+--------+--------+
| y0     | y1     | y2     | y3     | y4     | y5     | ...
+--------+--------+--------+--------+--------+--------+

+--------+--------+--------+--------+--------+--------+
| z0     | z1     | z2     | z3     | z4     | z5     | ...
+--------+--------+--------+--------+--------+--------+
```

The generated loop is now 4-wide vectorized (M4 Max): each field is loaded as
`<4 x T>`, computed on SIMD vectors, and stored back:

```llvm
vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %wide.load  = load <4 x i64>,   ptr %id.ptr,   align 8
  %wide.load1 = load <4 x float>, ptr %x.ptr,    align 4
  %wide.load2 = load <4 x float>, ptr %y.ptr,    align 4
  %wide.load3 = load <4 x float>, ptr %z.ptr,    align 4
  %new.x = fadd <4 x float> %wide.load1, <1.0, 1.0, 1.0, 1.0>
  %new.y = fadd <4 x float> %wide.load2, zeroinitializer
  %new.z = fadd <4 x float> %wide.load3, zeroinitializer
  store <4 x i64>   %wide.load,  ptr %out.id, align 8
  store <4 x float> %new.x,      ptr %out.x,  align 4
  store <4 x float> %new.y,      ptr %out.y,  align 4
  store <4 x float> %new.z,      ptr %out.z,  align 4
```

This yields ~20% less memory usage and up to ~2x speedup for memory-bound
operations.


## Future Work

* Support for sum datatypes (i.e. enums). There are different ways this could be
  achieved, and the best choice may depend on the individual application, so
  punting this until we have a real use case for it.
