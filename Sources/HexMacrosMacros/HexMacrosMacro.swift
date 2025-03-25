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
    public static func expansion(of node: AttributeSyntax,
                                 attachedTo declaration: some DeclGroupSyntax,
                                 providingExtensionsOf type: some TypeSyntaxProtocol,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
      
        var idPropertyName:String?
        var idTypeSyntax:TypeSyntax?
        
        //retrieve id propertyName from arguments if it's needed
        if case .argumentList(let arguments) = node.arguments{
            idPropertyName = arguments.first?.expression.as(StringLiteralExprSyntax.self)?.representedLiteralValue
        }
        
        // check does idProperty exists in declaration and retrieve its typeSyntax
        if let idPropertyName = idPropertyName {
            idTypeSyntax = (declaration.memberBlock.members
            .first(where: { ($0 as MemberBlockItemSyntax).decl.as(VariableDeclSyntax.self)?
                    .bindings
                .contains(where: {($0 as PatternBindingSyntax).pattern.as(IdentifierPatternSyntax.self)?.identifier.text == idPropertyName }) ?? false }))?
                .decl.as(VariableDeclSyntax.self)?.bindings
                .first(where: {($0 as PatternBindingSyntax).pattern.as(IdentifierPatternSyntax.self)?.identifier.text == idPropertyName })?.typeAnnotation?.type
        }
        
        
        //Fallback if idProportyName is given and typeSyntax is not determined
        if let idPropertyName = idPropertyName,
            idTypeSyntax == nil {
            context.diagnose(Diagnostic(node: declaration,
                                        message: MacroExpansionErrorMessage("Could find variable called  \(idPropertyName)")))
            return []
        }
        
        // build declaration extension
        do {
            let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed) : Identifiable") {
                if let idPropertyName = idPropertyName,
                   let idTypeSyntax = idTypeSyntax {
                    try! VariableDeclSyntax(" % id:\(idTypeSyntax.trimmed)") {
                        ExprSyntax(stringLiteral: idPropertyName)
                    }
                }
            }
            return [extensionDecl]
        } catch {
            context.diagnose(Diagnostic(node: declaration, message: MacroExpansionErrorMessage("Could build extension syntax")))
            return []
        }
    }
}


public struct AutoIdMacro: MemberMacro {
    public static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        //check does not id already exist in type
        if declaration.memberBlock.members.contains(where: { ($0 as MemberBlockItemSyntax).decl.as(VariableDeclSyntax.self)?.bindings.contains(where: {($0 as PatternBindingSyntax).pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "id"})  ?? false  }){
            context.diagnose(Diagnostic(node: declaration,
                                        message: MacroExpansionErrorMessage("id property already declared in scope")))
            return []
        }
        
        // build declaration extension
        do {
            let variableDeclSyntax = try VariableDeclSyntax("let id = UUID()")
            return [DeclSyntax(variableDeclSyntax)]
        } catch {
            context.diagnose(Diagnostic(node: declaration,
                                        message: MacroExpansionErrorMessage("Could build variable declaration syntax")))
            return []
        }
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
