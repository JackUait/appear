/// A keyboard key identified by its macOS virtual key code (as reported by
/// `NSEvent.keyCode` and consumed by Carbon's `RegisterEventHotKey`).
///
/// Any key is representable — letters, digits, punctuation, arrows, function
/// keys, the keypad — not just A–Z. Combined with up to four modifiers, a
/// shortcut is therefore up to five glyphs (e.g. `⌃⌥⇧⌘→`).
public struct Key: Hashable, Sendable, Codable {
    /// The macOS virtual key code, e.g. `0x01` for "S".
    public let virtualKeyCode: UInt32

    public init(virtualKeyCode: UInt32) {
        self.virtualKeyCode = virtualKeyCode
    }

    // Encoded as a bare integer (matching the old raw-value enum) so shortcuts
    // persisted by earlier versions still decode.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(virtualKeyCode: try container.decode(UInt32.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(virtualKeyCode)
    }

    /// The glyph shown to users, e.g. "S", "1", "␣", "↩", "F5", "→".
    public var label: String { Key.glyphs[virtualKeyCode] ?? "•" }

    /// The modifier and lock keys can't stand alone as a shortcut's key.
    public var isModifierKey: Bool { Key.modifierKeyCodes.contains(virtualKeyCode) }

    // Letter conveniences for code that wires up shortcuts literally (seeds,
    // tests). Any other key is constructed via `init(virtualKeyCode:)`.
    public static let a = Key(virtualKeyCode: 0x00), b = Key(virtualKeyCode: 0x0B)
    public static let c = Key(virtualKeyCode: 0x08), d = Key(virtualKeyCode: 0x02)
    public static let e = Key(virtualKeyCode: 0x0E), f = Key(virtualKeyCode: 0x03)
    public static let g = Key(virtualKeyCode: 0x05), h = Key(virtualKeyCode: 0x04)
    public static let i = Key(virtualKeyCode: 0x22), j = Key(virtualKeyCode: 0x26)
    public static let k = Key(virtualKeyCode: 0x28), l = Key(virtualKeyCode: 0x25)
    public static let m = Key(virtualKeyCode: 0x2E), n = Key(virtualKeyCode: 0x2D)
    public static let o = Key(virtualKeyCode: 0x1F), p = Key(virtualKeyCode: 0x23)
    public static let q = Key(virtualKeyCode: 0x0C), r = Key(virtualKeyCode: 0x0F)
    public static let s = Key(virtualKeyCode: 0x01), t = Key(virtualKeyCode: 0x11)
    public static let u = Key(virtualKeyCode: 0x20), v = Key(virtualKeyCode: 0x09)
    public static let w = Key(virtualKeyCode: 0x0D), x = Key(virtualKeyCode: 0x07)
    public static let y = Key(virtualKeyCode: 0x10), z = Key(virtualKeyCode: 0x06)

    private static let modifierKeyCodes: Set<UInt32> = [
        0x36, // right command
        0x37, // command
        0x38, // shift
        0x39, // caps lock
        0x3A, // option
        0x3B, // control
        0x3C, // right shift
        0x3D, // right option
        0x3E, // right control
        0x3F, // fn
    ]

    /// Virtual-key-code → display glyph for the full standard keyboard.
    private static let glyphs: [UInt32: String] = [
        // Letters
        0x00: "A", 0x0B: "B", 0x08: "C", 0x02: "D", 0x0E: "E", 0x03: "F",
        0x05: "G", 0x04: "H", 0x22: "I", 0x26: "J", 0x28: "K", 0x25: "L",
        0x2E: "M", 0x2D: "N", 0x1F: "O", 0x23: "P", 0x0C: "Q", 0x0F: "R",
        0x01: "S", 0x11: "T", 0x20: "U", 0x09: "V", 0x0D: "W", 0x07: "X",
        0x10: "Y", 0x06: "Z",
        // Digits
        0x1D: "0", 0x12: "1", 0x13: "2", 0x14: "3", 0x15: "4",
        0x17: "5", 0x16: "6", 0x1A: "7", 0x1C: "8", 0x19: "9",
        // Punctuation
        0x18: "=", 0x1B: "-", 0x1E: "]", 0x21: "[", 0x27: "'", 0x29: ";",
        0x2A: "\\", 0x2B: ",", 0x2C: "/", 0x2F: ".", 0x32: "`",
        // Whitespace & editing
        0x24: "↩", 0x30: "⇥", 0x31: "␣", 0x33: "⌫", 0x35: "⎋", 0x75: "⌦",
        // Navigation
        0x73: "↖", 0x77: "↘", 0x74: "⇞", 0x79: "⇟",
        0x7B: "←", 0x7C: "→", 0x7D: "↓", 0x7E: "↑",
        // Keypad
        0x52: "0", 0x53: "1", 0x54: "2", 0x55: "3", 0x56: "4", 0x57: "5",
        0x58: "6", 0x59: "7", 0x5B: "8", 0x5C: "9",
        0x41: ".", 0x43: "*", 0x45: "+", 0x4B: "/", 0x4C: "⌅", 0x4E: "-",
        0x47: "⌧", 0x51: "=",
        // Function keys
        0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4", 0x60: "F5", 0x61: "F6",
        0x62: "F7", 0x64: "F8", 0x65: "F9", 0x6D: "F10", 0x67: "F11", 0x6F: "F12",
        0x69: "F13", 0x6B: "F14", 0x71: "F15", 0x6A: "F16", 0x40: "F17",
        0x4F: "F18", 0x50: "F19", 0x5A: "F20",
    ]
}
