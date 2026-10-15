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
/// Unlike `MultiArray`, copies of this owner refer to the same storage: indexed
/// assignments write in place and never detach. Concurrent reads are safe when
/// the element and representation obey their sendability contracts. Concurrent
/// reads and writes, or multiple writes, require disjoint logical indices;
/// overlapping access needs external synchronization. The owner does not
/// conform to `Sendable`: an adapter crossing isolation boundaries must audit
/// and uphold that disjoint-access contract itself.
///
/// Keep the owner alive for as long as an adapter endpoint accesses its storage.
/// The owner releases the allocation and its initialized elements on deinit.
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
