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
struct SanitizerSmokeTests {
    @Test
    func concurrentIndependentBoxedProducts() async {
        let total = await withTaskGroup(of: Int.self, returning: Int.self) { group in
            for i in 0 ..< 8 {
                group.addTask {
                    let original: MultiArray<Product<Int, Box<String>>> = [
                        Product(i, Box("original")),
                        Product(i + 1, Box("second")),
                    ]
                    var copy = original
                    copy[0] = Product(i + 10, Box("changed"))
                    #expect(original[0]._0 == i)
                    #expect(original[0]._1.unbox == "original")
                    #expect(copy[1]._1.unbox == "second")
                    return copy[0]._0
                }
            }

            var sum = 0
            for await value in group { sum += value }
            return sum
        }
        #expect(total == 108)
    }
}
