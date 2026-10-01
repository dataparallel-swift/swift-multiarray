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

import struct Foundation.Data
@testable import MultiArray
import Testing

// Deliberately violates appendPayload's offset contract without accessing
// invalid memory, to check the encoding boundary in both debug and release.
private struct InvalidPayloadOffset: Generic, BinaryArrayData {
    typealias RawRepresentation = Self
    typealias Buffer = UnsafeMutablePointer<Self>

    var value: UInt8

    static var type: Type { UInt8.type }
    static var typeHead: TypeHead { UInt8.typeHead }

    static func verifyType(in data: Data, at offset: inout Int) throws {
        try UInt8.verifyType(in: data, at: &offset)
    }

    static func appendType(to data: inout Data) {
        UInt8.appendType(to: &data)
    }

    static func appendPayload(from storage: Buffer, count: Int, to data: inout Data, offset _: inout Int) {
        for index in 0 ..< count {
            data.append(storage[index].value)
        }
        // Do not advance offset: encoding must reject this broken conformer.
    }
}

@Suite
struct PartialPrefixSnapshotTests {
    #if compiler(>=6.2)
    @Test
    func encodingRejectsInvalidPayloadOffset() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            let array = MultiArray<InvalidPayloadOffset>(unsafeUninitializedCapacity: 2) { buffer, count in
                buffer.initializeElement(at: 0, to: InvalidPayloadOffset(value: 42))
                count = 1
            }
            _ = array.encode()
        }
        #if DEBUG
        let output = String(bytes: result?.standardErrorContent ?? [], encoding: .utf8) ?? ""
        #expect(output.contains("Binary payload copy must agree with rawSize"))
        #else
        // Optimized preconditions can trap without rendering their message.
        _ = result
        #endif
    }
    #endif

    private func checkCanonicalPrefix<E>(
        _ values: [E],
        capacity: Int,
        equal: (E, E) -> Bool
    ) throws where E: Generic, E.RawRepresentation: BinaryArrayData {
        let partial = MultiArray<E>(unsafeUninitializedCapacity: capacity) { buffer, count in
            for (index, value) in values.enumerated() {
                buffer.initializeElement(at: index, to: value)
                count += 1
            }
        }
        let exact = MultiArray(values)
        #expect(partial.arrayData.capacity == capacity)
        #expect(partial.count == values.count)
        #expect(partial.encode() == exact.encode())
        let decoded = try MultiArray<E>(data: partial.encode())
        #expect(decoded.count == values.count)
        for index in values.indices {
            #expect(equal(partial[index], values[index]))
            #expect(equal(decoded[index], values[index]))
        }
    }

    @Test(arguments: [0, 1, 2, 3, 8, 16], [0, 1, 2, 3])
    func partialPrefixesHaveCanonicalSnapshots(capacity: Int, count: Int) throws {
        guard count <= capacity else { return }
        let pairs: [Product<UInt8, UInt64>] = (0 ..< count).map { Product(UInt8($0 + 1), UInt64(($0 + 1) * 111)) }
        let nested: [Product<Product<UInt8, UInt64>, Product<Unit, UInt16>>] = (0 ..< count).map {
            Product(Product(UInt8($0), UInt64($0 + 10)), Product(Unit(), UInt16($0 + 20)))
        }
        let simd: [Product<UInt8, SIMD4<Float>>] = (0 ..< count).map {
            Product(UInt8($0), SIMD4<Float>(repeating: Float($0 + 1)))
        }
        try self.checkCanonicalPrefix(
            pairs,
            capacity: capacity,
            equal: { $0._0 == $1._0 && $0._1 == $1._1 }
        )
        try self.checkCanonicalPrefix(
            nested,
            capacity: capacity,
            equal: { $0._0._0 == $1._0._0 && $0._0._1 == $1._0._1 && $0._1._1 == $1._1._1 }
        )
        try self.checkCanonicalPrefix(
            simd,
            capacity: capacity,
            equal: { $0._0 == $1._0 && $0._1 == $1._1 }
        )
        try self.checkCanonicalPrefix(Array(repeating: Unit(), count: count), capacity: capacity, equal: { _, _ in true })
        try self.checkCanonicalPrefix((0 ..< count).map { Int32($0) }, capacity: capacity, equal: ==)
    }

    @Test
    func partiallyInitializedSnapshotReflectsMutation() throws {
        var array = MultiArray<Product<UInt8, UInt64>>(unsafeUninitializedCapacity: 16) { buffer, count in
            buffer.initializeElement(at: 0, to: Product(1, 111))
            buffer.initializeElement(at: 1, to: Product(2, 222))
            count = 2
        }
        array[1] = Product(3, 333)
        let expected: MultiArray<Product<UInt8, UInt64>> = [Product(1, 111), Product(3, 333)]
        #expect(array.encode() == expected.encode())
        let decoded = try MultiArray<Product<UInt8, UInt64>>(data: array.encode())
        #expect(decoded.count == 2)
        #expect(decoded[0]._0 == 1 && decoded[0]._1 == 111)
        #expect(decoded[1]._0 == 3 && decoded[1]._1 == 333)
    }
}
