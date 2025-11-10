// Copyright (c) 2025 PassiveLogic, Inc.

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MultiArrayPlugins: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GenericExtensionMacro.self,
    ]
}
