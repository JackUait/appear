/// A keyboard shortcut: a key plus its modifier flags.
public struct KeyCombo: Hashable, Sendable, Codable {
    public let key: Key
    public let modifiers: ModifierKey

    public init(key: Key, modifiers: ModifierKey) {
        self.key = key
        self.modifiers = modifiers
    }

    /// Human-readable form, e.g. "⌃⌥S".
    public var description: String { "\(modifiers.symbols)\(key.label)" }
}
