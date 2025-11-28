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

// An array where the elements are stored in struct-of-array style. This
// can provide better data locality and enable efficient (automatic)
// vectorisation.
//
public struct MultiArray<Element> where Element: Generic, Element.RawRepresentation: ArrayData {
    @usableFromInline
    let arrayData: MultiArrayData<Element.RawRepresentation>

    @inlinable
    public var count: Int { arrayData.capacity }

    @inlinable
    public init(unsafeUninitializedCapacity count: Int) {
        self.arrayData = .init(unsafeUninitializedCapacity: count)
    }

    @inlinable
    @_alwaysEmitIntoClient
    public subscript(index: Int) -> Element {
        get {
            Element.to(self.arrayData[index])
        }
        set(value) {
            self.arrayData[index] = Element.from(value)
        }
    }
}

extension MultiArray {
    @inlinable
    public func map<B: Generic>(_ transform: (Element) -> B) -> MultiArray<B> {
        var result = MultiArray<B>(unsafeUninitializedCapacity: self.count)
        for index in 0 ..< self.count {
            result[index] = transform(self[index])
        }
        return result
    }
}

extension MultiArray {
    @inlinable
    public func toArray() -> Array<Element> {
        .init(unsafeUninitializedCapacity: self.count, initializingWith: { buffer, initializedCount in
            for index in 0 ..< self.count {
                buffer.initializeElement(at: index, to: self[index])
            }
            initializedCount = self.count
        })
    }
}

extension Array where Element: Generic, Element.RawRepresentation: ArrayData {
    @inlinable
    public func toMultiArray() -> MultiArray<Element> {
        var multiArray = MultiArray<Element>(unsafeUninitializedCapacity: self.count)
        for index in 0 ..< self.count {
            multiArray[index] = self[index]
        }
        return multiArray
    }
}

// TODO: It would be better if this is generic over the underlying storage
// method. Then, we can specialise it for raw pointers on the heap (as we have
// now), or as pointers into GPU memory, or some other format such as
// individually GC-ed arrays so that we can support O(1) zip and unzip.
//
@usableFromInline
final class MultiArrayData<A: ArrayData> {
    @usableFromInline
    let capacity: Int

    @usableFromInline
    var storage: A.Buffer // storing the internal pointers for speed(?), but we could also recompute them from the base context

    @usableFromInline
    var context: UnsafeMutableRawPointer

    @inlinable
    public init(unsafeUninitializedCapacity count: Int) {
        var context = UnsafeMutableRawPointer.allocate(byteCount: A.rawSize(capacity: count, from: 0), alignment: 16)
        self.capacity = count
        self.context = context
        self.storage = A.reserve(capacity: count, from: &context)
    }

    @inlinable
    @_alwaysEmitIntoClient
    public subscript(index: Int) -> A {
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
