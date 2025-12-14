import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(HexMacrosMacros)
import HexMacrosMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
    "Identifiable": Identifiable.self
]
#endif

final class HexMacrosTests: XCTestCase {
    func testMacro() throws {
        #if canImport(HexMacrosMacros)
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(HexMacrosMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testIdentifiableMacro() throws {
        #if canImport(HexMacrosMacros)
    
        assertMacroExpansion(
            #"""
            @Identifiable()
            struct SomeStruct { }
            """#,
            expandedSource: #"""

            struct SomeStruct { }

            extension SomeStruct : Identifiable {
            }
            """#,
            macros: testMacros
        )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testIdentifiableMacro2() throws {
    #if canImport(HexMacrosMacros)
        assertMacroExpansion(
            #"""
            @Identifiable("identifier")
            struct SomeStruct {
              let identifier:Int
            }
            """#,
            expandedSource: #"""
            
            struct SomeStruct {
              let identifier:Int
            }

            extension SomeStruct : Identifiable {
                var id: Int {
                    identifier
                }
            }
            """#,
            macros: testMacros
        )
    #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
    }
}
