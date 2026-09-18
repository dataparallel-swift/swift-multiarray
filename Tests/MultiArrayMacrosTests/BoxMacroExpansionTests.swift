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
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite
struct BoxMacroExpansionTests {
    @Test
    func boxPreservesDefaultValueOnBackingStorage() {
        assertMacroExpansion(
            """
            struct Labeled {
                @Box var label: String = "guest"
            }
            """,
            expandedSource: """
            struct Labeled {
                var label: String {
                    @inlinable get {
                        _label.unbox
                    }
                    @inlinable set {
                        _label = Box(newValue)
                    }
                }

                var _label: Box<String> = Box("guest")
            }
            """,
            macros: ["Box": BoxPropertyMacro.self]
        )
    }

    @Test
    func boxEmitsPublicAccessorsWithStandardInlining() {
        assertMacroExpansion(
            """
            public struct Labeled {
                @Box public var label: String
            }
            """,
            expandedSource: """
            public struct Labeled {
                public var label: String {
                    @inlinable get {
                        _label.unbox
                    }
                    @inlinable set {
                        _label = Box(newValue)
                    }
                }

                @usableFromInline var _label: Box<String>
            }
            """,
            macros: ["Box": BoxPropertyMacro.self]
        )
    }

    @Test
    func genericPreservesInliningForPublicBoxStorage() {
        assertMacroExpansion(
            """
            @Generic
            public struct Labeled {
                @Box public var label: String
            }
            """,
            expandedSource: """
            public struct Labeled {
                public var label: String {
                    @inlinable get {
                        _label.unbox
                    }
                    @inlinable set {
                        _label = Box(newValue)
                    }
                }

                @usableFromInline var _label: Box<String>
            }

            extension Labeled: Generic {
                public typealias RawRepresentation = Box<String>.RawRepresentation

                @inlinable
                public var rawRepresentation: RawRepresentation {
                    self._label.rawRepresentation
                }

                @inlinable
                public init(from rep: RawRepresentation) {
                    self._label = Box<String>(from: rep)
                }
            }
            """,
            macros: [
                "Box": BoxPropertyMacro.self,
                "Generic": GenericExtensionMacro.self,
            ]
        )
    }

    @Test
    func boxDiagnosesInferredStoredPropertyWithoutPartialExpansion() {
        assertMacroExpansion(
            """
            @Box var label = "guest"
            """,
            expandedSource: """
            var label = "guest"
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Box requires an explicit type annotation on stored property 'label'",
                    line: 1,
                    column: 10
                ),
            ],
            macros: ["Box": BoxPropertyMacro.self]
        )
    }

    @Test
    func genericAndBoxDiagnoseInferredPropertyOnlyOnce() {
        assertMacroExpansion(
            """
            @Generic
            struct Labeled {
                @Box var label = "guest"
            }
            """,
            expandedSource: """
            struct Labeled {
                var label = "guest"
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Box requires an explicit type annotation on stored property 'label'",
                    line: 3,
                    column: 14
                ),
            ],
            macros: [
                "Box": BoxPropertyMacro.self,
                "Generic": GenericExtensionMacro.self,
            ]
        )
    }

    @Test
    func genericDoesNotCascadeAfterBoxRejectsMultipleBindings() {
        assertMacroExpansion(
            """
            @Generic
            struct Labeled {
                @Box var first, second: String
            }
            """,
            expandedSource: """
            struct Labeled {
                var first, second: String
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "accessor macro can only be applied to a single variable",
                    line: 3,
                    column: 5
                ),
                DiagnosticSpec(
                    message: "peer macro can only be applied to a single variable",
                    line: 3,
                    column: 5
                ),
            ],
            macros: [
                "Box": BoxPropertyMacro.self,
                "Generic": GenericExtensionMacro.self,
            ]
        )
    }

    @Test
    func boxDiagnosesUnsupportedPropertyPattern() {
        assertMacroExpansion(
            """
            @Box
            var (first, second): (Int, Int)
            """,
            expandedSource: """
            var (first, second): (Int, Int)
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Box can only be applied to a stored property",
                    line: 1,
                    column: 1
                ),
            ],
            macros: ["Box": BoxPropertyMacro.self]
        )
    }
}
