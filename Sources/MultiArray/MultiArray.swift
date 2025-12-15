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

/// An array where the elements are stored in struct-of-array style. This
/// can provide better data locality and enable efficient (automatic)
/// vectorisation.
public struct MultiArray<Element> where Element: Generic, Element.RawRepresentation: ArrayData {
    @usableFromInline
    internal let arrayData: MultiArrayData<Element.RawRepresentation>

    /// The number of elements in the array.
    @inlinable
    public var count: Int { arrayData.count }

    /// Create a new array containing the specified number of a single,
    /// repeating value.
    @inlinable
    public init(repeating: Element, count: Int) {
        self.init(count: count) { _ in repeating }
    }

    /// Create a new MultiArray by applying the given function to each index to
    /// produce each value.
    @inlinable
    public init(count: Int, with generator: (Int) throws -> Element) rethrows {
        precondition(count >= 0)
        self.arrayData = .init(unsafeUninitializedCapacity: count)
        for i in 0 ..< count {
            self[i] = try generator(i)
        }
    }

    /// Creates a MultiArray containing the elements of a collection.
    @inlinable
    public init<C: Collection>(_ elements: C) where Self.Element == C.Element {
        self.init(count: elements.count) { i in
            elements[elements.index(elements.startIndex, offsetBy: i)]
        }
    }

    /// Creates a MultiArray containing the elements of a sequence.
    @inlinable
    public init<S: Sequence>(_ elements: S) where Self.Element == S.Element {
        if #available(macOS 13.0.0, *), let c = elements as? any Collection<Self.Element> {
            self.init(c)
        }
        else {
            // Sequence does not provide an exact count of the number of
            // elements, so we can't directly create a MultiArray that is
            // guaranteed to contain all of the elements of the sequence in a
            // single pass. So, first buffer the sequence into a normal Array
            // (which has an optimised implementation already) and then convert
            // into a MultiArray from there (via the Collection initialiser).
            self.init(Array(elements))
        }
    }
}

// TODO: It would be better if this is generic over the underlying storage
// method. Then, we can specialise it for raw pointers on the heap (as we have
// now), or as pointers into GPU memory, or some other format such as
// individually GC-ed arrays so that we can support O(1) zip and unzip.
//
@usableFromInline
internal final class MultiArrayData<A: ArrayData> {
    @usableFromInline
    let count: Int

    @usableFromInline
    var context: UnsafeMutableRawPointer

    // Storing the internal pointers for speed(?), but we could also recompute
    // them from the base context.
    @usableFromInline
    var storage: A.Buffer

    @inlinable
    init(unsafeUninitializedCapacity count: Int) {
        var context = UnsafeMutableRawPointer.allocate(byteCount: A.rawSize(capacity: count, from: 0), alignment: 16)
        self.count = count
        self.context = context
        self.storage = A.reserve(capacity: count, from: &context)
    }

    @inlinable
    @_alwaysEmitIntoClient
    subscript(index: Int) -> A {
        get {
            A.readArrayData(self.storage, index: index)
        }
        set(value) {
            A.writeArrayData(&self.storage, index: index, value: value)
        }
    }

    deinit {
        self.context.deallocate()
    }
}
