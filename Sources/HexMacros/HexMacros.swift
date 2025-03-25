// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "HexMacrosMacros", type: "StringifyMacro")

@attached(extension, conformances: Identifiable, names: arbitrary)
public macro Identifiable(_ id: String? = nil) = #externalMacro(module: "HexMacrosMacros", type: "Identifiable")

@attached(member, names: arbitrary)
public macro autoId() = #externalMacro(module: "HexMacrosMacros", type: "AutoIdMacro")
