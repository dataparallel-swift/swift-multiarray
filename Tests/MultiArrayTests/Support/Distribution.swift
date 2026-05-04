// Copyright (c) 2026 The swift-multiarray authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Current size of the sampler in the range 0 ..< 100
typealias Size = Int64

func linear<T: BinaryInteger>(from x: T, to y: T) -> (Size) -> ClosedRange<T> {
    linear(around: x, from: x, to: y)
}

func linear<T: BinaryInteger>(around z: T, from x: T, to y: T) -> (Size) -> ClosedRange<T> {
    { sz in
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
