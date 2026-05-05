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

@Suite
struct RepeatingInitializationTests {
    @Test
    func repeatingScalarInt() {
        let ma = MultiArray<Int>(repeating: 42, count: 10)
        #expect(ma.count == 10)
        #expect(Array(ma) == Array(repeating: 42, count: 10))
    }

    @Test
    func repeatingScalarDouble() {
        let ma = MultiArray<Double>(repeating: 3.14, count: 5)
        #expect(ma.count == 5)
        for elem in ma {
            #expect(elem == 3.14)
        }
    }

    @Test
    func repeatingBool() {
        let ma = MultiArray<Bool>(repeating: true, count: 3)
        #expect(ma.count == 3)
        #expect(Array(ma) == [true, true, true])
    }

    @Test
    func repeatingStruct() {
        let point = Point(x: 1.0, y: 2.0)
        let ma = MultiArray<Point>(repeating: point, count: 4)
        #expect(ma.count == 4)
        #expect(Array(ma) == Array(repeating: point, count: 4))
    }

    @Test
    func repeatingNestedStruct() {
        let zone = Zone(id: 7, position: Vec3(x: 1, y: 2, z: 3))
        let ma = MultiArray<Zone>(repeating: zone, count: 3)
        #expect(ma.count == 3)
        for elem in ma {
            #expect(elem.id == 7)
            #expect(elem.position.x == 1)
            #expect(elem.position.y == 2)
            #expect(elem.position.z == 3)
        }
    }

    @Test
    func repeatingEmptyStruct() {
        let ma = MultiArray<Empty>(repeating: .init(), count: 5)
        #expect(ma.count == 5)
    }

    @Test
    func repeatingZeroCount() {
        let ma = MultiArray<Int>(repeating: 42, count: 0)
        #expect(ma.count == 0)
        #expect(Array(ma).isEmpty)
    }

    @Test
    func repeatingZeroCountStruct() {
        let ma = MultiArray<Point>(repeating: .init(x: 1, y: 2), count: 0)
        #expect(ma.count == 0)
        #expect(Array(ma).isEmpty)
    }

    @Test
    func repeatingLargeCount() {
        let count = 100_000
        let ma = MultiArray<Int>(repeating: 99, count: count)
        #expect(ma.count == count)
        #expect(ma.allSatisfy { $0 == 99 })
    }

    @Test
    func repeatingLargeCountStruct() {
        let count = 50_000
        let point = Point(x: 1.5, y: 2.5)
        let ma = MultiArray<Point>(repeating: point, count: count)
        #expect(ma.count == count)
        #expect(ma.allSatisfy { $0 == point })
    }

    @Test
    func repeatingBoxNoLeak() {
        final class Tracked {
            nonisolated(unsafe) static var liveCount: Int = 0

            init() { Tracked.liveCount += 1 }
            deinit { Tracked.liveCount -= 1 }
        }

        Tracked.liveCount = 0

        do {
            let ma = MultiArray<Box<Tracked>>(repeating: Box(Tracked()), count: 10)
            #expect(ma.count == 10)
            // All 10 elements retain the same Tracked instance.
            #expect(Tracked.liveCount == 1)
        }

        // After scope exit, the Box and its Tracked should be released.
        #expect(Tracked.liveCount == 0)
    }

    @Test
    func repeatingCOWIsolation() {
        let ma = MultiArray<Int>(repeating: 42, count: 4)
        var copy = ma

        copy[0] = 99

        #expect(ma[0] == 42)
        #expect(ma.allSatisfy { $0 == 42 })
        #expect(copy[0] == 99)
        #expect(copy[1] == 42)
    }

    @Test
    func repeatingCOWIsolationStruct() {
        let point = Point(x: 1.0, y: 2.0)
        let ma = MultiArray<Point>(repeating: point, count: 3)
        var copy = ma

        copy[0] = Point(x: 99.0, y: 88.0)

        #expect(ma[0] == point)
        #expect(copy[0] == Point(x: 99.0, y: 88.0))
    }

    @Test
    func repeatingBinaryRoundtrip() throws {
        let ma = MultiArray<Int32>(repeating: 777, count: 5)
        let encoded = ma.encode()
        let decoded = try MultiArray<Int32>(data: encoded)
        #expect(decoded == ma)
    }

    @Test
    func repeatingJSONRoundtrip() throws {
        let ma = MultiArray<Int32>(repeating: 777, count: 5)
        let data = try JSONEncoder().encode(ma)
        let decoded = try JSONDecoder().decode(MultiArray<Int32>.self, from: data)
        #expect(decoded == ma)
    }
}
