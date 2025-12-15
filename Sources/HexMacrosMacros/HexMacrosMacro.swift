import SwiftCompilerPlugin
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct Identifiable: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        // Extract the id property name from macro arguments
        let idPropertyName = extractIdPropertyName(from: node)
        
        // If a custom property name is specified, validate and get its type
        if let propertyName = idPropertyName {
            guard let propertyType = findPropertyType(named: propertyName, in: declaration) else {
                context.diagnose(
                    Diagnostic(
                        node: declaration,
                        message: MacroExpansionErrorMessage("Could not find variable called '\(propertyName)'")
                    )
                )
                return []
            }
            
            // Generate extension with computed property
            return [try createExtension(for: type, propertyName: propertyName, propertyType: propertyType)]
        }
        
        // No custom property specified, generate simple conformance
        return [try createExtension(for: type, propertyName: nil, propertyType: nil)]
    }
    
    /// Extracts the id property name from the macro arguments
    private static func extractIdPropertyName(from node: AttributeSyntax) -> String? {
        guard case .argumentList(let arguments) = node.arguments,
              let firstArgument = arguments.first else {
            return nil
        }
        
        return firstArgument.expression
            .as(StringLiteralExprSyntax.self)?
            .representedLiteralValue
    }
    
    /// Finds a property with the given name in the declaration and returns its type
    private static func findPropertyType(named propertyName: String, in declaration: some DeclGroupSyntax) -> TypeSyntax? {
        for member in declaration.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }
            
            for binding in variableDecl.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      pattern.identifier.text == propertyName else {
                    continue
                }
                
                return binding.typeAnnotation?.type
            }
        }
        
        return nil
    }
    
    /// Creates the extension declaration syntax
    private static func createExtension(
        for type: some TypeSyntaxProtocol,
        propertyName: String?,
        propertyType: TypeSyntax?
    ) throws -> ExtensionDeclSyntax {
        try ExtensionDeclSyntax("extension \(type.trimmed): Identifiable") {
            if let propertyName, let propertyType {
                try VariableDeclSyntax("var id: \(propertyType.trimmed)") {
                    ExprSyntax(stringLiteral: propertyName)
                }
            }
        }
    }
}


public struct AutoIdMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Check if 'id' property already exists
        if hasIdProperty(in: declaration) {
            context.diagnose(
                Diagnostic(
                    node: declaration,
                    message: MacroExpansionErrorMessage("'id' property already declared in scope")
                )
            )
            return []
        }
        
        // Create and return the id property declaration
        let variableDecl = try VariableDeclSyntax("let id = UUID()")
        return [DeclSyntax(variableDecl)]
    }
    
    /// Checks if a property named 'id' already exists in the declaration
    private static func hasIdProperty(in declaration: some DeclGroupSyntax) -> Bool {
        for member in declaration.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }
            
            for binding in variableDecl.bindings {
                if let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                   pattern.identifier.text == "id" {
                    return true
                }
            }
        }
        
        return false
    }
}

@main
struct HexMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        AutoIdMacro.self,
        Identifiable.self,
    ]
}
