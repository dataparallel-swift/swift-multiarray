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

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct StoredProperty {
    let name: String
    let type: TypeSyntax
    let isUsableFromInline: Bool
}

struct UntypedStoredProperty {
    let pattern: IdentifierPatternSyntax
    let isBoxed: Bool
}

struct StoredPropertyExtraction {
    let properties: [StoredProperty]
    let untypedProperties: [UntypedStoredProperty]
    let hasInvalidBoxDeclaration: Bool

    var isValid: Bool { untypedProperties.isEmpty && !hasInvalidBoxDeclaration }
}

enum AccessLevel {
    case `public`, `private`, `internal`, `fileprivate`, package

    var description: String {
        switch self {
            case .public: "public"
            case .private: "private"
            case .internal: "internal"
            case .fileprivate: "fileprivate"
            case .package: "package"
        }
    }
}

func extractAccessLevel(_ declaration: some DeclGroupSyntax) -> AccessLevel {
    for modifier in declaration.modifiers {
        switch modifier.name.text {
            case "public": return .public
            case "private": return .private
            case "internal": return .internal
            case "fileprivate": return .fileprivate
            case "package": return .package
            default: break
        }
    }
    return .internal
}

public struct GenericExtensionMacro: ExtensionMacro {
    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declGroup: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        if diagnosePrivateNestedType(declGroup, type: type, in: context) {
            return []
        }

        guard let structDecl = declGroup.as(StructDeclSyntax.self) else {
            let message = MacroExpansionErrorMessage("@Generic can only be applied to a struct")
            if let namedDecl = declGroup.asProtocol(NamedDeclSyntax.self) {
                context.diagnose(Diagnostic(node: namedDecl.name, message: message))
            }
            else {
                context.diagnose(Diagnostic(node: declGroup, message: message))
            }
            return []
        }

        let extraction = extractStoredProperties(structDecl)
        guard extraction.isValid else {
            for property in extraction.untypedProperties where !property.isBoxed {
                let name = property.pattern.identifier.text
                let message = MacroExpansionErrorMessage(
                    "@Generic requires an explicit type annotation on stored property '\(name)'"
                )
                context.diagnose(Diagnostic(node: property.pattern, message: message))
            }
            return []
        }

        let body = buildBody(extraction.properties, accessLevel: extractAccessLevel(structDecl))
        // Do not copy a generic declaration's where clause onto the extension. The original
        // declaration already establishes those constraints, and duplicating them has caused
        // circular-reference diagnostics in Swift compilers.
        let source = SourceFileSyntax(
            stringLiteral: "extension \(type.trimmed.description): Generic {\n\(body)\n}"
        )
        guard let result = source.statements.first?.item.as(ExtensionDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("failed to generate extension")
        }
        return [result]
    }

    static func diagnosePrivateNestedType(
        _ declaration: some DeclGroupSyntax,
        type: some TypeSyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool {
        guard extractAccessLevel(declaration) == .private, type.is(MemberTypeSyntax.self) else { return false }
        let message = MacroExpansionErrorMessage(
            "@Generic cannot be applied to a private nested type; use fileprivate access"
        )
        let node = declaration.asProtocol(NamedDeclSyntax.self).map { Syntax($0.name) } ?? Syntax(declaration)
        context.diagnose(Diagnostic(node: node, message: message))
        return true
    }

    static func extractStoredProperties(_ structDecl: StructDeclSyntax) -> StoredPropertyExtraction {
        var properties: [StoredProperty] = []
        var untypedProperties: [UntypedStoredProperty] = []
        var hasInvalidBoxDeclaration = false
        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
            guard !varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) else { continue }

            // @Box transforms the annotated property into a computed get/set backed by _name: Box<T>.
            // @Generic sees the source before @Box expands, so we detect the attribute here and
            // record the backing store directly instead of the (soon-to-be-computed) property.
            let isBoxed = varDecl.attributes.contains {
                $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "Box"
            }

            let bindings = extractableBindings(
                from: varDecl,
                isBoxed: isBoxed,
                hasInvalidBoxDeclaration: &hasInvalidBoxDeclaration
            )
            var effectiveTypes = Array<TypeSyntax?>(repeating: nil, count: bindings.count)
            var sharedType: TypeSyntax?

            for index in bindings.indices.reversed() {
                if let type = bindings[index].typeAnnotation?.type {
                    sharedType = type
                    effectiveTypes[index] = type
                }
                else if bindings[index].initializer == nil {
                    effectiveTypes[index] = sharedType
                }
                else {
                    // An initializer starts an independently inferred binding rather than
                    // inheriting a later binding's trailing type annotation.
                    sharedType = nil
                }
            }

            for (index, binding) in bindings.enumerated() {
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }

                // Skip computed properties; willSet/didSet are observers on stored properties.
                if let block = binding.accessorBlock, !isStoredAccessorBlock(block) { continue }

                guard let type = effectiveTypes[index] else {
                    untypedProperties.append(UntypedStoredProperty(pattern: identifier, isBoxed: isBoxed))
                    continue
                }

                properties.append(
                    storedProperty(
                        named: identifier.identifier.text,
                        type: type,
                        declaration: varDecl,
                        isBoxed: isBoxed
                    )
                )
            }
        }
        return StoredPropertyExtraction(
            properties: properties,
            untypedProperties: untypedProperties,
            hasInvalidBoxDeclaration: hasInvalidBoxDeclaration
        )
    }

    static func isInvalidBoxDeclaration(_ declaration: VariableDeclSyntax, isBoxed: Bool) -> Bool {
        guard isBoxed else { return false }
        return declaration.bindings.count != 1 ||
            declaration.bindings.first?.pattern.is(IdentifierPatternSyntax.self) != true
    }

    static func extractableBindings(
        from declaration: VariableDeclSyntax,
        isBoxed: Bool,
        hasInvalidBoxDeclaration: inout Bool
    ) -> [PatternBindingSyntax] {
        guard !isInvalidBoxDeclaration(declaration, isBoxed: isBoxed) else {
            // Swift diagnoses the accessor/peer restriction before @Box expands.
            // Suppress @Generic's dependent missing-backing-field errors.
            hasInvalidBoxDeclaration = true
            return []
        }
        return Array(declaration.bindings)
    }

    static func storedProperty(
        named name: String,
        type: TypeSyntax,
        declaration: VariableDeclSyntax,
        isBoxed: Bool
    ) -> StoredProperty {
        let isPublic = declaration.modifiers.contains { $0.name.tokenKind == .keyword(.public) }
        let hasUsableFromInline = declaration.attributes.contains {
            $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "usableFromInline"
        }
        let isPackage = declaration.modifiers.contains { $0.name.tokenKind == .keyword(.package) }

        // @Box's peer role marks backing storage @usableFromInline for public and
        // package properties. Mirror that known transformation instead of assuming
        // that arbitrary peer macros make their generated storage ABI-public.
        let isUsableFromInline = isBoxed ? isPublic || isPackage : isPublic || hasUsableFromInline
        if isBoxed {
            let typeStr = type.trimmed.description
            let boxedType: TypeSyntax = "Box<\(raw: typeStr)>"
            return StoredProperty(name: "_\(name)", type: boxedType, isUsableFromInline: isUsableFromInline)
        }
        return StoredProperty(name: name, type: type, isUsableFromInline: isUsableFromInline)
    }

    static func isStoredAccessorBlock(_ block: AccessorBlockSyntax) -> Bool {
        switch block.accessors {
            case .getter:
                return false
            case let .accessors(list):
                return list.allSatisfy {
                    $0.accessorSpecifier.tokenKind == .keyword(.willSet) ||
                        $0.accessorSpecifier.tokenKind == .keyword(.didSet)
                }
        }
    }

    static func accessPrefix(_ level: AccessLevel) -> String {
        switch level {
            case .internal: ""
            case .private: "fileprivate "
            default: level.description + " "
        }
    }

    static func buildRawRepresentationType(_ properties: ArraySlice<StoredProperty>) -> String {
        switch properties.count {
            case 0:
                return "Unit"
            case 1:
                guard let property = properties.first else { return "Unit" }
                return "\(property.type.trimmed.description).RawRepresentation"
            default:
                let middle = properties.startIndex + ((properties.count + 1) / 2)
                let lhs = buildRawRepresentationType(properties[..<middle])
                let rhs = buildRawRepresentationType(properties[middle...])
                return "Product<\(lhs), \(rhs)>"
        }
    }

    static func buildRawRepresentationExpression(_ properties: ArraySlice<StoredProperty>) -> String {
        switch properties.count {
            case 0:
                return "Unit()"
            case 1:
                guard let property = properties.first else { return "Unit()" }
                return "self.\(property.name).rawRepresentation"
            default:
                let middle = properties.startIndex + ((properties.count + 1) / 2)
                let lhs = buildRawRepresentationExpression(properties[..<middle])
                let rhs = buildRawRepresentationExpression(properties[middle...])
                return "Product(\(lhs), \(rhs))"
        }
    }

    static func buildAssignments(_ properties: ArraySlice<StoredProperty>, path: String = "rep") -> [String] {
        switch properties.count {
            case 0:
                return []
            case 1:
                guard let property = properties.first else { return [] }
                return ["self.\(property.name) = \(property.type.trimmed.description)(from: \(path))"]
            default:
                let middle = properties.startIndex + ((properties.count + 1) / 2)
                return buildAssignments(properties[..<middle], path: "\(path)._0") +
                    buildAssignments(properties[middle...], path: "\(path)._1")
        }
    }

    static func buildBody(_ properties: [StoredProperty], accessLevel level: AccessLevel) -> String {
        let acc = accessPrefix(level)
        let canInline = level != .private && level != .fileprivate &&
            (level != .public || properties.allSatisfy(\.isUsableFromInline))
        let inline = canInline ? "@inlinable\n" : ""

        let rawRepresentationType = buildRawRepresentationType(properties[...])
        let rawRepresentationExpression = buildRawRepresentationExpression(properties[...])
        let assignments = buildAssignments(properties[...]).joined(separator: "\n    ")

        return """
        \(acc)typealias RawRepresentation = \(rawRepresentationType)

        \(inline)\(acc)var rawRepresentation: RawRepresentation {
            \(rawRepresentationExpression)
        }

        \(inline)\(acc)init(from rep: RawRepresentation) {
            \(assignments)
        }
        """
    }
}
