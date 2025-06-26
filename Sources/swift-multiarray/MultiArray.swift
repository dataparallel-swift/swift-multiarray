
// An array where the elements are stored in struct-of-array style. This
// can provide better data locality and enable efficient (automatic)
// vectorisation.
//
public struct MultiArray<A> where A: Generic, A.Rep: ArrayData {
    public let count: Int
    @usableFromInline let arrayData : MultiArrayData<A.Rep>

    public init(unsafeUninitializedCapacity count: Int) {
        self.count = count
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

// TODO: It would be better if this is generic over the underlying storage
// method. Then, we can specialise it for raw pointers on the heap (as we have
// now), or as pointers into GPU memory, or some other format such as
// individually GC-ed arrays so that we can support O(1) zip and unzip.
//
@usableFromInline final class MultiArrayData<A: ArrayData> {
    @usableFromInline let payload : A.ArrayDataR

    public init(unsafeUninitializedCapacity count: Int) {
        self.payload = A.allocate(capacity: count)
    }

    @inlinable
    public subscript(index: Int) -> A {
        get {
            A.readArrayData(self.payload, index: index)
        }
        set(value) {
            A.writeArrayData(self.payload, index: index, value: value)
        }
    }

    deinit {
        A.deallocate(self.payload)
    }
}

