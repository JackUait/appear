/// A keyboard shortcut: a set of one to five regular keys held together, plus
/// any modifier flags. A single key with modifiers (`⌃⌥F`) is the common case;
/// a multi-key chord (`G+L+M+N+R`) is held all at once and matches regardless
/// of the order the keys go down.
public struct KeyCombo: Hashable, Sendable, Codable {
    /// The non-modifier keys, stored sorted by key code so equality and
    /// description are order-independent.
    public let keys: [Key]
    public let modifiers: ModifierKey

    public init(keys: [Key], modifiers: ModifierKey) {
        self.keys = keys.sorted { $0.virtualKeyCode < $1.virtualKeyCode }
        self.modifiers = modifiers
    }

    /// Convenience for the single-key case.
    public init(key: Key, modifiers: ModifierKey) {
        self.init(keys: [key], modifiers: modifiers)
    }

    /// Builds a combo from a hardware virtual key code and modifier flags, or
    /// nil if the code is a bare modifier key (which can't be a shortcut's key).
    public init?(virtualKeyCode: UInt32, modifiers: ModifierKey) {
        let key = Key(virtualKeyCode: virtualKeyCode)
        guard !key.isModifierKey else { return nil }
        self.init(key: key, modifiers: modifiers)
    }

    /// Builds a chord from virtual key codes (the keys held together) plus
    /// modifiers, or nil if any code is a bare modifier key or the set is empty.
    public init?(virtualKeyCodes: [UInt32], modifiers: ModifierKey) {
        let keys = virtualKeyCodes.map(Key.init(virtualKeyCode:))
        guard !keys.isEmpty, !keys.contains(where: { $0.isModifierKey }) else { return nil }
        self.init(keys: keys, modifiers: modifiers)
    }

    /// True when the chord needs more than one regular key, which Carbon's
    /// single-key `RegisterEventHotKey` can't express — those need the event tap.
    public var requiresEventTap: Bool { keys.count > 1 }

    /// The set of virtual key codes this chord's keys cover.
    public var keyCodes: Set<UInt32> { Set(keys.map(\.virtualKeyCode)) }

    /// Whether this chord is exactly satisfied by the keys currently held: the
    /// pressed key codes equal the chord's keys and the modifiers match. Used by
    /// the event-tap engine to decide when to fire.
    public func matches(pressedKeyCodes: Set<UInt32>, modifiers: ModifierKey) -> Bool {
        keyCodes == pressedKeyCodes && self.modifiers == modifiers
    }

    /// Human-readable form, e.g. "⌃⌥S" or "G+L+M+N+R".
    public var description: String {
        modifiers.symbols + keys.map(\.label).joined(separator: "+")
    }

    // Codable: encode as `{keys:[...], modifiers:Int}`, but still decode the
    // older `{key:Int, modifiers:Int}` single-key shape so persisted shortcuts
    // and their JSON round-trips survive.
    private enum CodingKeys: String, CodingKey { case keys, key, modifiers }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.modifiers = try container.decode(ModifierKey.self, forKey: .modifiers)
        if let keys = try container.decodeIfPresent([Key].self, forKey: .keys) {
            self.keys = keys.sorted { $0.virtualKeyCode < $1.virtualKeyCode }
        } else {
            let key = try container.decode(Key.self, forKey: .key)
            self.keys = [key]
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keys, forKey: .keys)
        try container.encode(modifiers, forKey: .modifiers)
    }
}
