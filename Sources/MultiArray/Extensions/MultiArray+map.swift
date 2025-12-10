// Copyright (c) 2025 The swift-multiarray authors. All rights reserved.
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

extension MultiArray {
    /// Returns an array containing the results of mapping the given closure
    /// over the array's elements.
    ///
    /// Shadows the implementation provided by Sequence.map with a
    /// MultiArray-specific overload that returns MultiArray<B> instead of [B].
    /// The implementation provided through Sequence does not optimise (inline?)
    /// enough to enable vectorisation. Note that this overload will only be
    /// picked up when the type is statically known to be MultiArray.
    @inlinable
    public func map<B: Generic>(_ transform: (Self.Element) throws -> B) rethrows -> MultiArray<B> {
        try .init(count: self.count) { i in
            try transform(self[i])
        }
    }
}
