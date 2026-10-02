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
import MultiArray
import Testing

private final class LiveCount: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func adjust(by delta: Int) {
        self.lock.lock()
        self.value += delta
        self.lock.unlock()
    }

    var current: Int {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.value
    }
}

private final class TrackedValue {
    let count: LiveCount

    init(_ count: LiveCount) {
        self.count = count
        count.adjust(by: 1)
    }

    deinit { self.count.adjust(by: -1) }
}

// This is the adapter boundary: its callers promise disjoint logical indices.
// The owner itself deliberately does not claim Sendable.
private struct DisjointEndpoint: @unchecked Sendable {
    let owner: MultiArrayBuffer<Product<Int, Box<String>>>

    func update(index: Int, round: Int) -> Bool {
        self.owner[index] = Product(round, Box("\(index):\(round)"))
        return self.owner[index]._0 == round
            && self.owner[index]._1.unbox == "\(index):\(round)"
    }
}

private actor ScratchHolder {
    let owner = MultiArrayBuffer<Int>(repeating: 0, count: 4)

    func update(index: Int, value: Int) async {
        await Task.yield()
        self.owner[index] = value
    }

    func read(at index: Int) -> Int { self.owner[index] }
}

@Suite
struct MultiArrayBufferTests {
    @Test
    func fixedSizeAndSharedReferenceSemantics() {
        let owner = MultiArrayBuffer<Int32>(repeating: 7, count: 3)
        let alias = owner
        #expect(owner.count == 3)
        alias[1] = 99
        #expect(owner[1] == 99)
        #expect(owner[0] == 7)
        #expect(owner[2] == 7)

        let empty = MultiArrayBuffer<Int32>(repeating: 1, count: 0)
        #expect(empty.count == 0)
    }

    @Test
    func boxedProductLifetimeAndRetainedEndpoint() {
        let count = LiveCount()
        var endpoint: (() -> Int)?
        do {
            let owner = MultiArrayBuffer<Product<Int, Box<TrackedValue>>>(
                repeating: Product(1, Box(TrackedValue(count))),
                count: 3
            )
            #expect(count.current == 1)
            owner[1] = Product(2, Box(TrackedValue(count)))
            #expect(count.current == 2)
            endpoint = { owner[1]._0 }
        }
        #expect(endpoint?() == 2)
        #expect(count.current == 2)
        endpoint = nil
        #expect(count.current == 0)
    }

    @Test
    func actorHeldBufferReusesStorage() async {
        let holder = ScratchHolder()
        for round in 1 ... 8 {
            await holder.update(index: 2, value: round)
            #expect(await holder.read(at: 2) == round)
        }
        #expect(await holder.read(at: 0) == 0)
    }

    @Test
    func concurrentDisjointIndices() async {
        let endpoint = DisjointEndpoint(owner: .init(repeating: Product(0, Box("initial")), count: 64))
        let valid = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
            for index in 0 ..< endpoint.owner.count {
                group.addTask {
                    for round in 1 ... 128 {
                        if round.isMultiple(of: 16) { await Task.yield() }
                        guard endpoint.update(index: index, round: round) else { return false }
                    }
                    return true
                }
            }
            for await result in group where !result { return false }
            return true
        }
        #expect(valid)
        for index in 0 ..< endpoint.owner.count {
            #expect(endpoint.owner[index]._0 == 128)
            #expect(endpoint.owner[index]._1.unbox == "\(index):128")
        }
    }
}
