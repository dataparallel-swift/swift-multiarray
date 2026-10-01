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

import Foundation

extension BinaryArrayData where Buffer == UnsafeMutablePointer<Self> {
    public static func appendPayload(from storage: Buffer, count: Int, to data: inout Data, offset: inout Int) {
        // The allocation base is 16-byte aligned and supported field alignments
        // divide 16. Aligning a payload-relative offset therefore gives the same
        // padding as aligning an address during reservation, even when the
        // source allocation has different (capacity-sized) field offsets.
        guard let layout = getRawFieldLayout(for: Self.self, count: count, from: offset) else {
            preconditionFailure("MultiArray encoding size is not representable")
        }
        data.append(contentsOf: repeatElement(UInt8(0), count: layout.begin - offset))
        let byteCount = layout.end - layout.begin
        if byteCount > 0 {
            data.append(UnsafeRawPointer(storage).assumingMemoryBound(to: UInt8.self), count: byteCount)
        }
        offset = layout.end
    }
}

extension Unit {
    public static func appendPayload(from _: Buffer, count _: Int, to _: inout Data, offset _: inout Int) { /* no-op */ }
}

extension Product where A: BinaryArrayData, B: BinaryArrayData {
    public static func appendPayload(from storage: Buffer, count: Int, to data: inout Data, offset: inout Int) {
        A.appendPayload(from: storage.0, count: count, to: &data, offset: &offset)
        B.appendPayload(from: storage.1, count: count, to: &data, offset: &offset)
    }
}
