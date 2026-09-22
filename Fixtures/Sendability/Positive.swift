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

struct Pair: Generic, Sendable {
    typealias RawRepresentation = Product<Int32, Float64>

    let count: Int32
    let value: Float64

    var rawRepresentation: RawRepresentation {
        Product(self.count, self.value)
    }

    init(count: Int32, value: Float64) {
        self.count = count
        self.value = value
    }

    init(from representation: RawRepresentation) {
        self.init(count: representation._0, value: representation._1)
    }
}

struct Labeled: Generic, Sendable {
    typealias RawRepresentation = Product<Int32, Box<String>>

    let id: Int32
    let label: String

    var rawRepresentation: RawRepresentation {
        Product(self.id, Box(self.label))
    }

    init(id: Int32, label: String) {
        self.id = id
        self.label = label
    }

    init(from representation: RawRepresentation) {
        self.init(id: representation._0, label: representation._1.unbox)
    }
}

enum Status: UInt8, Generic, Sendable {
    typealias RawRepresentation = RawValueRepresentation<Self>

    case idle
    case running
}

@Generic
struct MacroLabeled: Sendable {
    let id: Int32
    @Box var label: String
}

func checkPositiveSendability() {
    requireTransferableRepresentation(Int32.self)
    requireTransferableRepresentation(Pair.self)
    requireTransferableRepresentation(Labeled.self)
    requireTransferableRepresentation(Box<String>.self)
    requireTransferableRepresentation(T3<Int32, Box<String>, Status>.self)
    requireTransferableRepresentation(Status.self)
    requireTransferableRepresentation(MacroLabeled.self)
    requireSendable(RawValueRepresentation<Status>.self)
    requireSendable(Sum<Int32, String>.self)
}
