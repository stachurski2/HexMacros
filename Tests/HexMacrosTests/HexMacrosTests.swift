import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(HexMacrosMacros)
import HexMacrosMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
    "Identifiable": Identifiable.self,
    "autoId": AutoIdMacro.self
]
#endif

@Suite("Hex Macros Tests")
struct HexMacrosTests {

    
    // MARK: - Identifiable Macro Tests
    
    @Suite("Identifiable Macro")
    struct IdentifiableTests {
        @Test("Without argument")
        func withoutArgument() throws {
            #if canImport(HexMacrosMacros)
            assertMacroExpansion(
                """
                @Identifiable()
                struct SomeStruct { }
                """,
                expandedSource: """
                
                struct SomeStruct { }
                
                extension SomeStruct : Identifiable {
                }
                """,
                macros: testMacros
            )
            #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
            #endif
        }
        
        @Test("With identifier argument")
        func withIdentifierArgument() throws {
            #if canImport(HexMacrosMacros)
            assertMacroExpansion(
                """
                @Identifiable("identifier")
                struct SomeStruct {
                  let identifier: Int
                }
                """,
                expandedSource: """
                
                struct SomeStruct {
                  let identifier: Int
                }
                
                extension SomeStruct : Identifiable {
                    var id: Int {
                        identifier
                    }
                }
                """,
                macros: testMacros
            )
            #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
            #endif
        }
        
        @Test("With different property types")
        func withStringIdentifier() throws {
            #if canImport(HexMacrosMacros)
            assertMacroExpansion(
                """
                @Identifiable("name")
                struct Person {
                  let name: String
                }
                """,
                expandedSource: """
                
                struct Person {
                  let name: String
                }
                
                extension Person : Identifiable {
                    var id: String {
                        name
                    }
                }
                """,
                macros: testMacros
            )
            #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
            #endif
        }
    }
    
    // MARK: - AutoId Macro Tests
    
    @Suite("AutoId Macro")
    struct AutoIdTests {
        @Test("Basic struct")
        func basicStruct() throws {
            #if canImport(HexMacrosMacros)
            assertMacroExpansion(
                """
                @autoId()
                struct SomeStruct { }
                """,
                expandedSource: """
                
                struct SomeStruct { 
                
                    let id = UUID()
                }
                """,
                macros: testMacros
            )
            #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
            #endif
        }
        
        @Test("Struct with existing properties")
        func structWithExistingProperties() throws {
            #if canImport(HexMacrosMacros)
            assertMacroExpansion(
                """
                @autoId()
                struct User {
                    let name: String
                }
                """,
                expandedSource: """
                
                struct User {
                    let name: String
                
                    let id = UUID()
                }
                """,
                macros: testMacros
            )
            #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
            #endif
        }
    }
    
    // MARK: - Stringify Macro Tests
    
    @Suite("Stringify Macro")
    struct StringifyTests {
        @Test("Simple expression")
        func simpleExpression() throws {
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
        
        @Test("String literal with interpolation")
        func stringLiteralWithInterpolation() throws {
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
    }
}
