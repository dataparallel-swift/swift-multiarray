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

extension MultiArray: Equatable where Element: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.count == rhs.count else { return false }
        // Identical storage implies equal contents, and this stays sound under
        // copy-on-write. `context` is a `let` holding the base address of the
        // allocation the instance owns and deallocates, so two live instances
        // cannot share one: equal pointers mean the same MultiArrayData, hence
        // the same elements. When COW splits a copy, `init(from:)` allocates a
        // fresh block, so the copy gets a different `context` and correctly
        // falls through to the element-wise comparison below.
        if lhs.arrayData.context == rhs.arrayData.context { return true }
        return lhs.elementsEqual(rhs)
    }
}
