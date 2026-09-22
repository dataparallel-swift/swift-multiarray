# Storage and Vectorization

Understand how field-wise storage changes memory traffic and generated code.

## Struct of arrays

A conventional `[Particle]` interleaves every field of one value before the
fields of the next value:

```text
| id0 | x0 | y0 | z0 | padding | id1 | x1 | y1 | z1 | padding | ...
```

``MultiArray`` instead gives every scalar field a contiguous buffer:

```text
| id0 | id1 | id2 | id3 | ...
|  x0 |  x1 |  x2 |  x3 | ...
|  y0 |  y1 |  y2 |  y3 | ...
|  z0 |  z1 |  z2 |  z3 | ...
```

This avoids padding between fields and gives a loop contiguous inputs that are
friendlier to caches and the compiler's loop vectorizer. SIMD values remain
atomic fields: `MultiArray<SIMD4<Float>>` stores one buffer of `SIMD4<Float>`
values rather than four `Float` buffers.

## A checked vectorization example

The following model and transform are compiled as part of the package tests:

@Snippet(path: "Vectorization", slice: "model")

@Snippet(path: "Vectorization", slice: "move")

The project's `scripts/check-vectorization.sh` also compiles this exact source
as a release client and inspects only the `move` function's LLVM IR. Local
ARM64 Linux runs and x86-64 Linux CI verify Swift 6.0 through 6.4. Each contains
a vector loop with matching float loads, additions, and stores. The chosen
vector width is target-dependent: the same loop may, for example, use four-wide
operations on ARM64 and two-wide operations on x86-64.

LLVM also emits a scalar remainder and a runtime-alias fallback. Their presence
is expected and does not mean that the primary loop failed to vectorize.

The representation conversion is intended to disappear after inlining. A
public type with non-public represented fields prevents the generated
conversion witnesses from being `@inlinable`; consider that tradeoff when the
type is used in performance-sensitive cross-module loops.
