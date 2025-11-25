// Copyright (c) 2025 PassiveLogic, Inc.

// Current size of the sampler in the range 0 ..< 100
typealias Size = Int64

func linear<T: BinaryInteger>(from x: T, to y: T) -> (Size) -> ClosedRange<T> {
    linear(around: x, from: x, to: y)
}

func linear<T: BinaryInteger>(around z: T, from x: T, to y: T) -> (Size) -> ClosedRange<T> {
    return { sz in
        let lower = clamp(x, y, scaleLinear(sz, z, x))
        let upper = clamp(x, y, scaleLinear(sz, z, y))
        return lower ... upper
    }
}

func clamp<T: Comparable>(_ minimum: T, _ maximum: T, _ value: T) -> T {
    if minimum > maximum {
        min(minimum, max(maximum, value))
    }
    else {
        min(maximum, max(minimum, value))
    }
}

func scaleLinear<T: BinaryInteger>(_ sz0: Size, _ z0: T, _ n0: T) -> T {
    let sz = max(0, min(99, sz0))
    let around = Int64(z0)
    let value = Int64(n0)

    // rng has magnitude 1 larger than the largest diff; i.e. it specifies the
    // range the diff can be in [0, rng) with the upper bound being exclusive
    let nmz = value - around
    let rng = nmz + nmz.signum()
    let diff = (rng * sz) / 100

    return T(around + diff)
}
