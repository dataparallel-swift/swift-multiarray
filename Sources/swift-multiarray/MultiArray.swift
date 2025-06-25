
// An array where the elements are stored in struct-of-array style. This
// can provide better data locality and enable efficient (automatic)
// vectorisation.
//
public struct MultiArray<A> where A: Generic, A.Rep: ArrayData {
    public let count: Int
    private let arrayData : MultiArrayData<A.Rep>

    public init(unsafeUninitializedCapacity count: Int) {
        self.count = count
        self.arrayData = .init(unsafeUninitializedCapacity: count)
    }

    subscript(index: Int) -> A {
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
private final class MultiArrayData<A: ArrayData> {
    let payload : A.ArrayDataR

    public init(unsafeUninitializedCapacity count: Int) {
        self.payload = A.allocate(capacity: count)
    }

    subscript(index: Int) -> A {
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

