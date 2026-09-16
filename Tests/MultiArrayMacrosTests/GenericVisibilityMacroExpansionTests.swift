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
struct GenericVisibilityMacroExpansionTests {
    @Test
    func genericEmitsPublicWitnessesWithStandardInlining() {
        assertMacroExpansion(
            """
            @Generic
            public struct Value {
                public var value: Double
            }
            """,
            expandedSource: """
            public struct Value {
                public var value: Double
            }

            extension Value: Generic {
                public typealias RawRepresentation = Double.RawRepresentation

                @inlinable
                public var rawRepresentation: RawRepresentation {
                    self.value.rawRepresentation
                }

                @inlinable
                public init(from rep: RawRepresentation) {
                    self.value = Double(from: rep)
                }
            }
            """,
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }

    @Test
    func genericOmitsInliningForEncapsulatedPublicStorage() {
        assertMacroExpansion(
            """
            @Generic
            public struct Value {
                var internalValue: Double
                private var privateValue: Int32
            }
            """,
            expandedSource: """
            public struct Value {
                var internalValue: Double
                private var privateValue: Int32
            }

            extension Value: Generic {
                public typealias RawRepresentation = Product<Double.RawRepresentation, Int32.RawRepresentation>

                public var rawRepresentation: RawRepresentation {
                    Product(self.internalValue.rawRepresentation, self.privateValue.rawRepresentation)
                }

                public init(from rep: RawRepresentation) {
                    self.internalValue = Double(from: rep._0)
                    self.privateValue = Int32(from: rep._1)
                }
            }
            """,
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }

    @Test
    func genericPreservesInliningForUsableFromInlineStorage() {
        assertMacroExpansion(
            """
            @Generic
            public struct Value {
                @usableFromInline var value: Double
            }
            """,
            expandedSource: """
            public struct Value {
                @usableFromInline var value: Double
            }

            extension Value: Generic {
                public typealias RawRepresentation = Double.RawRepresentation

                @inlinable
                public var rawRepresentation: RawRepresentation {
                    self.value.rawRepresentation
                }

                @inlinable
                public init(from rep: RawRepresentation) {
                    self.value = Double(from: rep)
                }
            }
            """,
            macros: ["Generic": GenericExtensionMacro.self]
        )
    }
}
