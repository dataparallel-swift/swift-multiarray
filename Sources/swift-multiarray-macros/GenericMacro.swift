import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct GenericExtensionMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
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

