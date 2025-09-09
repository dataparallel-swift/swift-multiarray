
// An array where the elements are stored in struct-of-array style. This
// can provide better data locality and enable efficient (automatic)
// vectorisation.
//
public struct MultiArray<A> where A: Generic, A.Rep: ArrayData {
    @usableFromInline let arrayData : MultiArrayData<A.Rep>

    public var count: Int {
        get { arrayData.capacity }
    }

    public init(unsafeUninitializedCapacity count: Int) {
        self.arrayData = .init(unsafeUninitializedCapacity: count)
    }

    @inlinable
    public subscript(index: Int) -> A {
        get {
            A.to(self.arrayData[index])
        }
        set(value) {
            self.arrayData[index] = A.from(value)
        }
    }
}

extension MultiArray {
    @inlinable
    public func map<B: Generic>(_ transform: (A) -> B) -> MultiArray<B> {
        var result = MultiArray<B>.init(unsafeUninitializedCapacity: self.count)
        for i in 0 ..< self.count {
            result[i] = transform(self[i])
        }
        return result
    }
}

extension MultiArray {
    @inlinable
    public func toArray() -> Array<A> {
        .init(unsafeUninitializedCapacity: self.count, initializingWith: { buffer, initializedCount in
            for i in 0 ..< self.count {
                buffer.initializeElement(at: i, to: self[i])
            }
            initializedCount = self.count
        })
    }
}

extension Array where Element: Generic, Element.Rep: ArrayData {
    @inlinable
    public func toMultiArray() -> MultiArray<Element> {
        var marr = MultiArray<Element>.init(unsafeUninitializedCapacity: self.count)
        for i in 0 ..< self.count {
            marr[i] = self[i]
        }
        return marr
    }
}

// TODO: It would be better if this is generic over the underlying storage
// method. Then, we can specialise it for raw pointers on the heap (as we have
// now), or as pointers into GPU memory, or some other format such as
// individually GC-ed arrays so that we can support O(1) zip and unzip.
//
@usableFromInline final class MultiArrayData<A: ArrayData> {
    @usableFromInline let capacity: Int
    @usableFromInline var storage: A.ArrayDataR
    @usableFromInline var context: UnsafeMutableRawPointer

    public init(unsafeUninitializedCapacity count: Int) {
        var context = UnsafeMutableRawPointer.allocate(byteCount: A.rawsize(capacity: count, from: 0), alignment: 16)
        self.capacity = count
        self.context  = context
        self.storage  = A.reserve(capacity: count, from: &context)
    }

    @inlinable
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

