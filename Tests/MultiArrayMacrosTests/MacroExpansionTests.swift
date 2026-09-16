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
struct MacroExpansionTests {
    @Test
    func genericBuildsBalancedProductTree() {
        assertMacroExpansion(
            """
            @Generic
            struct Vector {
                var x: Float
                var y: Float
                var z: Float
            }
            """,
            expandedSource: """
            struct Vector {
                var x: Float
                var y: Float
                var z: Float
            }

            extension Vector: Generic {
                typealias RawRepresentation = Product<Product<Float.RawRepresentation, Float.RawRepresentation>, Float.RawRepresentation>

                @inlinable
                var rawRepresentation: RawRepresentation {
                    Product(Product(self.x.rawRepresentation, self.y.rawRepresentation), self.z.rawRepresentation)
                }

                @inlinable
                init(from rep: RawRepresentation) {
                    self.x = Float(from: rep._0._0)
                    self.y = Float(from: rep._0._1)
                    self.z = Float(from: rep._1)
                }
            }
            """,
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }

    @Test
    func genericEmitsFileprivateWitnessesWithoutInlining() {
        assertMacroExpansion(
            """
            @Generic
            private struct Value {
                var value: Double
            }
            """,
            expandedSource: """
            private struct Value {
                var value: Double
            }

            extension Value: Generic {
                fileprivate typealias RawRepresentation = Double.RawRepresentation

                fileprivate var rawRepresentation: RawRepresentation {
                    self.value.rawRepresentation
                }

                fileprivate init(from rep: RawRepresentation) {
                    self.value = Double(from: rep)
                }
            }
            """,
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }

    @Test
    func genericDiagnosesNonStructDeclaration() {
        assertMacroExpansion(
            """
            @Generic
            class Value {}
            """,
            expandedSource: """
            class Value {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Generic can only be applied to a struct",
                    line: 2,
                    column: 7
                ),
            ],
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }

    @Test
    func genericDiagnosesPrivateNestedType() {
        assertMacroExpansion(
            """
            struct Outer {
                @Generic
                private struct Value {
                    var value: Double
                }
            }
            """,
            expandedSource: """
            struct Outer {
                private struct Value {
                    var value: Double
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Generic cannot be applied to a private nested type; use fileprivate access",
                    line: 3,
                    column: 20
                ),
            ],
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }

    @Test
    func genericExtensionUsesDeclarationConstraints() {
        assertMacroExpansion(
            """
            @Generic
            struct Wrapper<Element> where Element: Generic {
                var value: Element
            }
            """,
            expandedSource: """
            struct Wrapper<Element> where Element: Generic {
                var value: Element
            }

            extension Wrapper: Generic {
                typealias RawRepresentation = Element.RawRepresentation

                @inlinable
                var rawRepresentation: RawRepresentation {
                    self.value.rawRepresentation
                }

                @inlinable
                init(from rep: RawRepresentation) {
                    self.value = Element(from: rep)
                }
            }
            """,
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }

    @Test
    func genericDiagnosesInferredStoredProperty() {
        assertMacroExpansion(
            """
            @Generic
            struct Value {
                var inferred = 1.0, explicit: Double
            }
            """,
            expandedSource: """
            struct Value {
                var inferred = 1.0, explicit: Double
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Generic requires an explicit type annotation on stored property 'inferred'",
                    line: 3,
                    column: 9
                ),
            ],
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }

    @Test
    func genericUsesSharedTrailingTypeAnnotation() {
        assertMacroExpansion(
            """
            @Generic
            struct Pair {
                var x, y: Double
            }
            """,
            expandedSource: """
            struct Pair {
                var x, y: Double
            }

            extension Pair: Generic {
                typealias RawRepresentation = Product<Double.RawRepresentation, Double.RawRepresentation>

                @inlinable
                var rawRepresentation: RawRepresentation {
                    Product(self.x.rawRepresentation, self.y.rawRepresentation)
                }

                @inlinable
                init(from rep: RawRepresentation) {
                    self.x = Double(from: rep._0)
                    self.y = Double(from: rep._1)
                }
            }
            """,
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }

    @Test
    func genericUsesSeparatelyAnnotatedBindings() {
        assertMacroExpansion(
            """
            @Generic
            struct Pair {
                var x: Float, y: Double
            }
            """,
            expandedSource: """
            struct Pair {
                var x: Float, y: Double
            }

            extension Pair: Generic {
                typealias RawRepresentation = Product<Float.RawRepresentation, Double.RawRepresentation>

                @inlinable
                var rawRepresentation: RawRepresentation {
                    Product(self.x.rawRepresentation, self.y.rawRepresentation)
                }

                @inlinable
                init(from rep: RawRepresentation) {
                    self.x = Float(from: rep._0)
                    self.y = Double(from: rep._1)
                }
            }
            """,
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }

    @Test
    func genericIgnoresComputedAndStaticProperties() {
        assertMacroExpansion(
            """
            @Generic
            struct Value {
                static var defaultValue = 1.0
                var stored: Double
                var computed: Double { stored * 2 }
            }
            """,
            expandedSource: """
            struct Value {
                static var defaultValue = 1.0
                var stored: Double
                var computed: Double { stored * 2 }
            }

            extension Value: Generic {
                typealias RawRepresentation = Double.RawRepresentation

                @inlinable
                var rawRepresentation: RawRepresentation {
                    self.stored.rawRepresentation
                }

                @inlinable
                init(from rep: RawRepresentation) {
                    self.stored = Double(from: rep)
                }
            }
            """,
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }
}
