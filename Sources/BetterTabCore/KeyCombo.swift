/// A keyboard shortcut: a key plus its modifier flags.
public struct KeyCombo: Hashable, Sendable, Codable {
    public let key: Key
    public let modifiers: ModifierKey

    public init(key: Key, modifiers: ModifierKey) {
        self.key = key
        self.modifiers = modifiers
    }

    /// Builds a combo from a hardware virtual key code (e.g. an `NSEvent`'s
    /// `keyCode`) and modifier flags, or nil if the code isn't a supported `Key`.
    public init?(virtualKeyCode: UInt32, modifiers: ModifierKey) {
        guard let key = Key(rawValue: virtualKeyCode) else { return nil }
        self.init(key: key, modifiers: modifiers)
    }

    /// Human-readable form, e.g. "⌃⌥S".
    public var description: String { "\(modifiers.symbols)\(key.label)" }
}
