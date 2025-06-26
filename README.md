# swift-multiarray

An array that stores elements in unboxed struct-of-array style. This can provide
better data locality and enable efficient (automatic) vectorization.

## Example

In order to store values in unboxed struct-of-array style, array elements must
be members of the included `Generic` protocol. This currently supports regular
non-recursive product types over primitive values. Sum types could be
supported as well, but we'll defer that until we have good uses cases to
properly explore that space (see comments in the code).

Consider the following datatype:

```swift
@Generic
struct Vec3<Element> {
    let x, y, z: Element
}
```

The required instance ~is~ will eventually be provided by the `@Generic` macro,
which generates something like:

```swift
extension Vec3: Generic where Element: Generic {
    typealias Rep = P<Element.Rep, P<Element.Rep, Element.Rep>>
    static func from(_ self: Self) -> Self.Rep {
        Element.from(self.x) .*. Element.from(self.y) .*. Element.from(self.z)
    }
    static func to(_ rep: Self.Rep) -> Self {
        Vec3(x: Element.to(rep._0), y: Element.to(rep._1._0), z: Element.to(rep._1._1))
    }
}
```

Here `P` is a simple pair type, because Swift does not allow us to extend
regular tuples `(,)`. Boo.

As you can see, this is a straightforward translation over the structure of the
datatype into an isomorphic representation using (nested) pairs. As far as the
compiler is concerned, the in-memory layout of `Vec3<Float>` and
`Vec3<Float>.Rep` is identical, so in practice (i.e. with sufficient inlining)
this representation change should be a no-op.

Similarly, the following works exactly as you would expect:

```swift
@Generic
struct Zone {
    let id: Int
    let position: Vec3<Float>
}

// Generates...
extension Zone: Generic {
    typealias Rep = P<Int.Rep, Vec3<Float>.Rep>
    static func from(_ self: Self) -> Self.Rep {
        Int.from(self.id) .*. Vec3.from(self.position)
    }
    static func to(_ rep: Self.Rep) -> Self {
        Zone(id: Int.to(rep._0), position: Vec3.to(rep._1))
    }
}
```

Once the protocol instance is defined, you can use it in the usual way and have
the compiler automatically transform access to and from the underlying storage
representation.

For example, suppose we have the following function to move the position of a
`Zone` by a given x-, y-, and z-offset:

```swift
extension Zone {
    public func move(dx: Float = 0, dy: Float = 0, dz: Float = 0) -> Zone {
        Zone(id: self.id,
             position: Vec3(x: self.position.x + dx,
                            y: self.position.y + dy,
                            z: self.position.z + dz))
    }
}
```

In a regular Swift `Array` the fields of our `Zone` structure will be stored
contiguously in memory as (on a 64-bit system):

```
                            1        1        2        2        2        3
 0        4        8        2        6        0        4        8        2
+--------+--------+--------+--------+--------+--------+--------+--------+--------+
| id0             | x0     | y0     | z0     | <pad>  | id1             | x1     | ...
+--------+--------+--------+--------+--------+--------+--------+--------+--------+
```

Notice that due to alignment restricts, an extra 4 bytes padding must be added
between each array element, and wasting 16.6% of our available memory bandwidth.

If we `map` our `move(dx: 1)` function over this array and inspect the
generated code, we'll see that the core of the loop looks like this (annotated):

```llvm
10:                                               ; preds = %26, %5
  %11 = phi i64 [ %.pre, %5 ], [ %23, %26 ]                                 ; array capacity
  %12 = phi i64 [ 0, %5 ], [ %28, %26 ]                                     ; loop counter
  %13 = phi ptr [ %6, %5 ], [ %27, %26 ]                                    ; array storage
  %14 = mul nuw nsw i64 %12, 24                                             ; calculate offset to start of this element
  %15 = getelementptr inbounds i8, ptr %7, i64 %14                          ; get pointer to this element
  %16 = load i64, ptr %15, align 1                                          ; load .id
  %.position = getelementptr inbounds i8, ptr %15, i64 8                    ; get pointer to .x
  %17 = load <2 x float>, ptr %.position, align 1                           ; load .x and .y
  %.position.z = getelementptr inbounds i8, ptr %15, i64 16                 ; get pointer to .z
  %18 = load float, ptr %.position.z, align 1                               ; load .z
  %19 = fadd <2 x float> %17, <float 1.000000e+00, float 0.000000e+00>      ; compute new .x and .y
  %20 = fadd float %18, 0.000000e+00                                        ; compute new .z
  store ptr %13, ptr %1, align 8
  %._storage3._capacityAndFlags = getelementptr inbounds i8, ptr %13, i64 24
  %21 = load i64, ptr %._storage3._capacityAndFlags, align 8
  %22 = lshr i64 %21, 1
  %23 = add nuw nsw i64 %11, 1
  %.not = icmp ugt i64 %22, %11
  br i1 %.not, label %26, label %24, !prof !11
```

The swift compiler does a good job to turn the individual load of `x` and `y`
into a single vectorised load, but is otherwise hamstrung by the underlying data
layout and unable to optimise the code further.

Using `MultiArray`, each of the individual fields of the structure are stored in
their own individual memory regions:

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

And the core loop of the generated code now looks like this:

```llvm
vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %25 = getelementptr inbounds %TSi, ptr %19, i64 %index
  %wide.load = load <4 x i64>, ptr %25, align 8, !alias.scope !13
  %26 = getelementptr inbounds %TSf, ptr %20, i64 %index
  %wide.load100 = load <4 x float>, ptr %26, align 4, !alias.scope !16
  %27 = getelementptr inbounds %TSf, ptr %21, i64 %index
  %wide.load101 = load <4 x float>, ptr %27, align 4, !alias.scope !18
  %28 = getelementptr inbounds %TSf, ptr %22, i64 %index
  %wide.load102 = load <4 x float>, ptr %28, align 4, !alias.scope !20
  %29 = fadd <4 x float> %wide.load100, <float 1.000000e+00, float 1.000000e+00, float 1.000000e+00, float 1.000000e+00>
  %30 = fadd <4 x float> %wide.load101, zeroinitializer
  %31 = fadd <4 x float> %wide.load102, zeroinitializer
  %32 = getelementptr inbounds %TSi, ptr %8, i64 %index
  store <4 x i64> %wide.load, ptr %32, align 8, !alias.scope !22, !noalias !24
  %33 = getelementptr inbounds %TSf, ptr %10, i64 %index
  store <4 x float> %29, ptr %33, align 4, !alias.scope !28, !noalias !29
  %34 = getelementptr inbounds %TSf, ptr %11, i64 %index
  store <4 x float> %30, ptr %34, align 4, !alias.scope !30, !noalias !31
  %35 = getelementptr inbounds %TSf, ptr %12, i64 %index
  store <4 x float> %31, ptr %35, align 4, !alias.scope !32, !noalias !33
  %index.next = add nuw i64 %index, 4
  %36 = icmp eq i64 %index.next, %n.vec
  br i1 %36, label %middle.block, label %vector.body, !llvm.loop !34
```

Immediately we can see that this loop has been 4-wide vectorized: each field is
read 4-elements at a time, and computations are done on 4-wide SIMD vectors (M4
Max).

(A very observant viewer might also note that this loop branches directly to the
top of the basic block, compared to the previous version which did not. Indeed
that version requires a "cleanup" step after each iteration to update the stored
size of the array and grow its capacity if necessary, but that's out of scope
for this discussion).

Benchmarking the above yields a 20% reduction in memory usage and 1.4x to 1.8x
performance improvement (which is not bad given this benchmark is purely memory
bound).

<details>

```
Host 'bc1192120c71' with 16 'aarch64' processors with 43 GB memory, running:
#1 SMP PREEMPT_DYNAMIC Fri Dec 27 17:14:27 UTC 2024

============
bench-readme
============

array/10000
╒════════════════════════════════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╕
│ Metric                             │        p0 │       p25 │       p50 │       p75 │       p90 │       p99 │      p100 │   Samples │
╞════════════════════════════════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╡
│ Memory (allocated resident) (M)    │        13 │        13 │        13 │        13 │        13 │        13 │        13 │     10000 │
├────────────────────────────────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
│ Time (wall clock) (μs) *           │         8 │         8 │         9 │         9 │         9 │        12 │        51 │     10000 │
╘════════════════════════════════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╛

array/100000
╒════════════════════════════════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╕
│ Metric                             │        p0 │       p25 │       p50 │       p75 │       p90 │       p99 │      p100 │   Samples │
╞════════════════════════════════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╡
│ Memory (allocated resident) (M)    │        20 │        20 │        20 │        20 │        20 │        20 │        20 │     10000 │
├────────────────────────────────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
│ Time (wall clock) (μs) *           │        73 │        78 │        82 │        83 │        86 │        97 │       198 │     10000 │
╘════════════════════════════════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╛

array/1000000
╒════════════════════════════════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╕
│ Metric                             │        p0 │       p25 │       p50 │       p75 │       p90 │       p99 │      p100 │   Samples │
╞════════════════════════════════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╡
│ Memory (allocated resident) (M)    │        37 │        37 │        45 │        50 │        50 │        50 │        50 │      2885 │
├────────────────────────────────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
│ Time (wall clock) (μs) *           │      3313 │      3412 │      3441 │      3471 │      3504 │      3693 │      4172 │      2885 │
╘════════════════════════════════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╛

array/10000000
╒════════════════════════════════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╕
│ Metric                             │        p0 │       p25 │       p50 │       p75 │       p90 │       p99 │      p100 │   Samples │
╞════════════════════════════════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╡
│ Memory (allocated resident) (M)    │       280 │       281 │       281 │       281 │       281 │       281 │       281 │       290 │
├────────────────────────────────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
│ Time (wall clock) (μs) *           │     33123 │     34079 │     34472 │     34832 │     35291 │     37028 │     37905 │       290 │
╘════════════════════════════════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╛

multiarray/10000
╒════════════════════════════════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╕
│ Metric                             │        p0 │       p25 │       p50 │       p75 │       p90 │       p99 │      p100 │   Samples │
╞════════════════════════════════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╡
│ Memory (allocated resident) (M)    │        13 │        13 │        14 │        14 │        14 │        14 │        14 │     10000 │
├────────────────────────────────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
│ Time (wall clock) (μs) *           │         5 │         5 │         5 │         5 │         6 │         7 │        22 │     10000 │
╘════════════════════════════════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╛

multiarray/100000
╒════════════════════════════════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╕
│ Metric                             │        p0 │       p25 │       p50 │       p75 │       p90 │       p99 │      p100    Samples │
╞════════════════════════════════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╡
│ Memory (allocated resident) (M)    │        17 │        17 │        17 │        17 │        17 │        17 │        17 │     10000 │
├────────────────────────────────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
│ Time (wall clock) (μs) *           │        39 │        45 │        47 │        50 │        52 │        61 │       242 │     10000 │
╘════════════════════════════════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╛

multiarray/1000000
╒════════════════════════════════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╕
│ Metric                             │        p0 │       p25 │       p50 │       p75 │       p90 │       p99 │      p100 │   Samples │
╞════════════════════════════════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╡
│ Memory (allocated resident) (M)    │        32 │        36 │        36 │        37 │        38 │        40 │        40 │      4825 │
├────────────────────────────────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
│ Time (wall clock) (μs) *           │      1930 │      2029 │      2053 │      2076 │      2097 │      2175 │      2735 │      4825 │
╘════════════════════════════════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╛

multiarray/10000000
╒════════════════════════════════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╤═══════════╕
│ Metric                             │        p0 │       p25 │       p50 │       p75 │       p90 │       p99 │      p100 │   Samples │
╞════════════════════════════════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╪═══════════╡
│ Memory (allocated resident) (M)    │       221 │       221 │       222 │       222 │       222 │       222 │       222 │       410 │
├────────────────────────────────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
│ Time (wall clock) (μs) *           │     23625 │     24166 │     24379 │     24560 │     24691 │     25641 │     27065 │       410 │
╘════════════════════════════════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╛
```

</details>


## TODO

* Implement `@Generic` macro

* Support for sum datatypes (i.e. enums). There are different ways this could be
  achieved, and the best choice may depend on the individual application, so
  punting this until we have a real use case for it.

