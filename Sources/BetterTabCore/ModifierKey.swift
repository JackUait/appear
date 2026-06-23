/// A set of keyboard modifier flags, independent of any OS framework.
public struct ModifierKey: OptionSet, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let control = ModifierKey(rawValue: 1 << 0)
    public static let option  = ModifierKey(rawValue: 1 << 1)
    public static let shift   = ModifierKey(rawValue: 1 << 2)
    public static let command = ModifierKey(rawValue: 1 << 3)

    /// Modifier glyphs in the conventional macOS display order: ⌃⌥⇧⌘.
    public var symbols: String {
        var result = ""
        if contains(.control) { result += "⌃" }
        if contains(.option)  { result += "⌥" }
        if contains(.shift)   { result += "⇧" }
        if contains(.command) { result += "⌘" }
        return result
    }
}
