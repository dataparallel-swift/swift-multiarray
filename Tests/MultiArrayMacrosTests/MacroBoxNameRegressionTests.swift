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

@testable import MultiArrayMacros
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite
struct MacroBoxNameRegressionTests {
    @Test
    func boxNamesAndAttributeRecognition() {
        #expect(boxBackingName("`class`") == "_class")
        #expect(boxBackingName("`ordinary`") == "_ordinary")
        #expect(boxBackingName("ordinary") == "_ordinary")
        #expect(boxBackingName("`my value`") == "`_my value`")
        #expect(boxBackingName("`model & test`") == "`_model & test`")
        #expect(boxBackingName("`100`") == "_100")
        #expect(isBoxAttribute(TypeSyntax(stringLiteral: "Box")))
        #expect(isBoxAttribute(TypeSyntax(stringLiteral: "MultiArray.Box")))
        #expect(!isBoxAttribute(TypeSyntax(stringLiteral: "OtherModule.Box")))
    }

    @Test(arguments: ["`class`", "`ordinary`", "ordinary", "`my value`", "`model & test`", "`100`"])
    func escapedBackingExpansion(name: String) {
        let backing = boxBackingName(name)
        assertMacroExpansion(
            """
            struct S {
                @Box var \(name): String = "hello"
            }
            """,
            expandedSource: """
            struct S {
                var \(name): String {
                    @inlinable get {
                        \(backing).unbox
                    }
                    @inlinable set {
                        \(backing) = Box(newValue)
                    }
                }

                var \(backing): Box<String> = Box("hello")
            }
            """,
            macros: ["Box": BoxPropertyMacro.self]
        )
    }

    @Test(arguments: ["Box", "MultiArray.Box"])
    func genericRecognizesSuppliedBox(attribute: String) {
        assertMacroExpansion(
            """
            @Generic
            struct S {
                @\(attribute) var `class`: String = "hello"
            }
            """,
            expandedSource: """
            struct S {
                @\(attribute) var `class`: String = "hello"
            }

            extension S: Generic {
                typealias RawRepresentation = Box<String>.RawRepresentation

                @inlinable
                var rawRepresentation: RawRepresentation {
                    self._class.rawRepresentation
                }

                @inlinable
                init(from rep: RawRepresentation) {
                    self._class = Box<String>(from: rep)
                }
            }
            """,
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }
}
