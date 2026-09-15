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
struct GenericTests {
    @Test
    func platformSizedIntegerRepresentationLayoutsMatch() {
        #expect(MemoryLayout<Int>.size == MemoryLayout<Int.RawRepresentation>.size)
        #expect(MemoryLayout<Int>.stride == MemoryLayout<Int.RawRepresentation>.stride)
        #expect(MemoryLayout<UInt>.size == MemoryLayout<UInt.RawRepresentation>.size)
        #expect(MemoryLayout<UInt>.stride == MemoryLayout<UInt.RawRepresentation>.stride)
    }
}
