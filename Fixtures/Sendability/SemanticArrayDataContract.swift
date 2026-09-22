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

import MultiArray

final class HiddenBufferReference {
    var value = 0
}

struct IncidentallySendableRepresentation: ArrayData, Sendable {
    typealias Buffer = UnsafeMutablePointer<HiddenBufferReference>

    static func initialize(_ arrayData: Buffer, at index: Int, to _: Self) {
        (arrayData + index).initialize(to: HiddenBufferReference())
    }

    static func initialize(_ arrayData: Buffer, from source: Buffer, count: Int) {
        arrayData.initialize(from: source, count: count)
    }

    static func initialize(_ arrayData: Buffer, repeating _: Self, count: Int) {
        for index in 0 ..< count {
            self.initialize(arrayData, at: index, to: Self())
        }
    }

    static func deinitialize(_ arrayData: Buffer, count: Int) {
        arrayData.deinitialize(count: count)
    }

    static func read(_ arrayData: Buffer, at index: Int) -> Self {
        _ = arrayData[index].value
        return Self()
    }

    static func write(_ arrayData: Buffer, at index: Int, to _: Self) {
        arrayData[index].value += 1
    }

    static func reserve(capacity _: Int, from _: inout UnsafeMutableRawPointer) -> Buffer {
        fatalError("compile-time fixture")
    }

    static func rawSize(capacity _: Int, from offset: Int) -> Int { offset }
}

struct IncidentallySendableSurface: Generic, Sendable {
    typealias RawRepresentation = IncidentallySendableRepresentation

    var rawRepresentation: RawRepresentation { RawRepresentation() }

    init() {}
    init(from _: RawRepresentation) {}
}

// The type system accepts this because both the surface and logical
// representation values are Sendable. ArrayData's documented purity contract
// is what forbids hiding mutable non-Sendable state in Buffer like this.
func checkSemanticArrayDataContract() {
    requireTransferableRepresentation(IncidentallySendableSurface.self)
}
