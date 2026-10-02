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

/// A fixed-size, reference-semantic struct-of-arrays buffer for reusable scratch.
///
/// All handles share storage; indexed writes never detach. This owner is not
/// `Sendable`. A cross-isolation adapter must keep it alive and uphold element
/// and representation sendability contracts. Concurrent read/write pairs or
/// multiple writes require disjoint logical indices, or external synchronization
/// for overlapping access. See <doc:UsingCollections> for examples.
public final class MultiArrayBuffer<Element> where Element: Generic, Element.RawRepresentation: ArrayData {
    @usableFromInline
    internal let arrayData: MultiArrayData<Element.RawRepresentation>

    /// The fixed number of initialized elements.
    public let count: Int

    /// Allocates and initializes every element with a repeating value.
    @inlinable
    public init(repeating value: Element, count: Int) {
        precondition(count >= 0, "MultiArray capacity must be nonnegative")
        self.arrayData = .init(repeating: value.rawRepresentation, count: count)
        self.count = count
    }

    /// Reads or replaces an element without copy-on-write detachment.
    @inlinable
    public subscript(index: Int) -> Element {
        get {
            precondition(index >= 0 && index < self.count, "MultiArray index out of bounds")
            return Element(from: self.arrayData[index])
        }
        set(value) {
            precondition(index >= 0 && index < self.count, "MultiArray index out of bounds")
            self.arrayData[index] = value.rawRepresentation
        }
    }
}
