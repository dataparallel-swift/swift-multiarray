import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MultiArrayPlugins: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GenericExtensionMacro.self,
    ]
}

