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

// Preserve deliberately escaped non-keyword identifiers in the compiler fixture.
// swiftformat:disable redundantBackticks
@Generic
struct MacroQualifiedEscapedBox {
    @MultiArray.Box var `class`: String = "default"
    @Box var `ordinary`: String = "default"
}

struct MacroStandaloneEscapedBox {
    @Box var `class`: String = "default"
    @Box var `ordinary`: String = "default"
}

// swiftformat:enable redundantBackticks

#if compiler(>=6.2)
@Generic
struct MacroRawIdentifierBox {
    @MultiArray.Box var `my value`: String = "default"
    @Box var `model & test`: String = "default"
}

struct MacroStandaloneRawIdentifierBox {
    @Box var `my value`: String = "default"
}
#endif

@Suite
struct MacroBoxRegressionTests {
    #if compiler(>=6.2)
    @Test
    func rawIdentifierBoxesRoundtrip() {
        var original = MacroRawIdentifierBox()
        original.`my value` = "changed"
        original.`model & test` = "also changed"
        let restored = MultiArray([original])[0]
        #expect(restored.`my value` == "changed")
        #expect(restored.`model & test` == "also changed")
        var standalone = MacroStandaloneRawIdentifierBox()
        standalone.`my value` = "standalone"
        #expect(standalone.`my value` == "standalone")
    }
    #endif
    @Test
    func qualifiedAndEscapedBoxesRoundtrip() {
        var original = MacroQualifiedEscapedBox()
        original.class = "changed"
        original.ordinary = "also changed"
        let restored = MultiArray([original])[0]
        #expect(restored.class == "changed")
        #expect(restored.ordinary == "also changed")
        var standalone = MacroStandaloneEscapedBox()
        standalone.class = "keyword"
        standalone.ordinary = "identifier"
        #expect(standalone.class == "keyword")
        #expect(standalone.ordinary == "identifier")
    }
}
