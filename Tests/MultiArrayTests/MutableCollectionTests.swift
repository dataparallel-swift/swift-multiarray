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
import Testing

@Suite
struct MutableCollectionTests {
    @Test
    func copyIsolation() {
        var a = MultiArray([1, 2, 3])
        var b = a
        a[2] = 300
        b[0] = 99
        #expect(a[0] == 1, "modifying copy should not affect original")
        #expect(b[2] == 3, "modifying original should not affect copy")
    }

    @Test
    func originalIsolation() {
        var a = MultiArray([1, 2, 3])
        var b = a
        a[0] = 42
        b[2] = 300
        #expect(b[0] == 1, "modifying original should not affect copy")
        #expect(a[2] == 3, "modifying copy should not affect original")
    }

    @Test
    func copyIsolationWithStruct() {
        var a: MultiArray<Point> = [.init(x: 1.0, y: 2.0), .init(x: 3.0, y: 4.0)]
        var b = a
        a[1] = .init(x: 88.0, y: 88.0)
        b[0] = .init(x: 99.0, y: 99.0)
        #expect(a[0].x == 1.0, "modifying copy should not affect original")
        #expect(a[0].y == 2.0)
        #expect(b[1].x == 3.0, "modifying original should not affect copy")
        #expect(b[1].y == 4.0)
    }

    @Test
    func copyIsolationWithBox() {
        let original: MultiArray<Box<String>> = [Box("one"), Box("two")]
        var copy = original

        copy[0] = Box("changed")

        #expect(original[0].unbox == "one")
        #expect(original[1].unbox == "two")
        #expect(copy[0].unbox == "changed")
        #expect(copy[1].unbox == "two")
    }

    @Test
    func multipleCopiesIsolation() {
        var original = MultiArray([10, 20, 30])
        var copy1 = original
        var copy2 = original
        original[2] = 300
        copy1[0] = 100
        copy2[1] = 200
        #expect(original[0] == 10, "copy1 mutation should not affect original")
        #expect(original[1] == 20, "copy2 mutation should not affect original")
        #expect(copy1[1] == 20, "copy2 mutation should not affect copy1")
        #expect(copy2[0] == 10, "copy1 mutation should not affect copy2")
    }
}
