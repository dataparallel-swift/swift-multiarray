// Copyright (c) 2025 PassiveLogic, Inc.

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
                public typealias Rep = Unit
                @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep { fatalError("from") }
                @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self { fatalError("to") }
            }
            """
        )

        return [genericExtension]
    }
}
