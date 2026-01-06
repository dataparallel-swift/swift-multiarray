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

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct GenericExtensionMacro: ExtensionMacro {
    public static func expansion(
        of _: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let genericExtension = try ExtensionDeclSyntax("""
            extension \(type.trimmed): Generic {
                public typealias RawRepresentation = Unit

                @inlinable
                @_alwaysEmitIntoClient
                public static func from(_ x: Self) -> Self.RawRepresentation { fatalError("from") }

                @inlinable
                @_alwaysEmitIntoClient
                public static func to(_ x: Self.RawRepresentation) -> Self { fatalError("to") }
            }
            """
        )

        return [genericExtension]
    }
}
