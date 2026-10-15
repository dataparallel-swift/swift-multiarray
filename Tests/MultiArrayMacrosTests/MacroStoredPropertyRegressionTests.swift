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

import MultiArrayMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite
struct MacroStoredPropertyRegressionTests {
    @Test
    func conditionalPropertiesAreDiagnosedInEveryClause() {
        assertMacroExpansion(
            """
            @Generic
            struct Conditional {
                #if os(Linux)
                var active: Int32 = 3
                #else
                var inactive: Int32
                #if DEBUG
                var nested: Int32 = 4
                #endif
                #endif
            }
            """,
            expandedSource: """
            struct Conditional {
                #if os(Linux)
                var active: Int32 = 3
                #else
                var inactive: Int32
                #if DEBUG
                var nested: Int32 = 4
                #endif
                #endif
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Generic does not support conditionally compiled stored property 'active'", line: 4, column: 9),
                DiagnosticSpec(message: "@Generic does not support conditionally compiled stored property 'inactive'", line: 6, column: 9),
                DiagnosticSpec(message: "@Generic does not support conditionally compiled stored property 'nested'", line: 8, column: 9),
            ],
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }

    @Test
    func defaultedImmutablePropertyIsDiagnosed() {
        assertMacroExpansion(
            """
            @Generic
            struct DefaultLet {
                let value: Int32 = 7
            }
            """,
            expandedSource: """
            struct DefaultLet {
                let value: Int32 = 7
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Generic does not support declaration-initialized let property 'value'; " +
                        "initialize it in an initializer instead",
                    line: 3,
                    column: 9
                ),
            ],
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }
}
