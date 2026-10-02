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

@testable import MultiArray
import Testing

@_alignment(16)
private struct AlignedByte: Equatable {
    let value: UInt8
}

private struct AlignedValue: Equatable, Generic {
    let value: UInt8

    typealias RawRepresentation = Box<AlignedByte>

    var rawRepresentation: RawRepresentation {
        Box(AlignedByte(value: self.value))
    }

    init(from rep: RawRepresentation) {
        self.value = rep.unbox.value
    }

    init(_ value: UInt8) {
        self.value = value
    }
}

@Suite
struct LayoutTests {
    @Test
    func emptyLayoutHasZeroSize() {
        #expect(Unit.rawSize(capacity: 0, from: 0) == 0)
        #expect(Product<UInt8, UInt64>.rawSize(capacity: 0, from: 0) == 0)
    }

    @Test
    func maximumSafeSizeIsRepresentable() {
        #expect(UInt8.rawSize(capacity: Int.max, from: 0) == Int.max)
        #expect(UInt16.rawSize(capacity: Int.max / 2, from: 0) == Int.max - 1)
    }

    @Test
    func invalidAndOverflowingLayoutsAreRejected() {
        #expect(UInt8.rawSize(capacity: -1, from: 0) == nil)
        #expect(UInt8.rawSize(capacity: 0, from: -1) == nil)
        #expect(UInt16.rawSize(capacity: Int.max, from: 0) == nil)
        #expect(UInt16.rawSize(capacity: 0, from: Int.max) == nil)
        #expect(Product<UInt8, UInt64>.rawSize(capacity: Int.max, from: 0) == nil)
    }

    @Test
    func sizeAndReserveWalksAgreeForAlignedField() throws {
        typealias Representation = Product<Product<UInt8, UInt32>, Box<AlignedByte>>
        let count = 3
        let byteCount = try #require(Representation.rawSize(capacity: count, from: 0))
        let base = UnsafeMutableRawPointer.allocate(
            byteCount: byteCount,
            alignment: multiArrayAllocationAlignment
        )
        defer { base.deallocate() }

        var cursor = base
        let storage = Representation.reserve(capacity: count, from: &cursor)

        #expect(cursor - base == byteCount)
        #expect(Int(bitPattern: storage.1) % MemoryLayout<AlignedByte>.alignment == 0)
    }

    @Test
    func maximumSupportedAlignmentRoundtrips() {
        let values = [AlignedValue(1), AlignedValue(2), AlignedValue(3)]
        let array = MultiArray(values)

        #expect(MemoryLayout<AlignedByte>.alignment == multiArrayAllocationAlignment)
        #expect(Int(bitPattern: array.arrayData.storage) % MemoryLayout<AlignedByte>.alignment == 0)
        #expect(Array(array) == values)
    }
}
