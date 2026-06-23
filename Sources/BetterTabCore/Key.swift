/// A keyboard key identified by its macOS ANSI virtual key code.
/// Raw values are the `kVK_ANSI_*` codes used by Carbon's RegisterEventHotKey.
public enum Key: UInt32, Sendable, CaseIterable, Codable {
    case a = 0x00, b = 0x0B, c = 0x08, d = 0x02, e = 0x0E, f = 0x03
    case g = 0x05, h = 0x04, i = 0x22, j = 0x26, k = 0x28, l = 0x25
    case m = 0x2E, n = 0x2D, o = 0x1F, p = 0x23, q = 0x0C, r = 0x0F
    case s = 0x01, t = 0x11, u = 0x20, v = 0x09, w = 0x0D, x = 0x07
    case y = 0x10, z = 0x06

    /// The uppercased letter shown to users, e.g. `.s` -> "S".
    public var label: String { "\(self)".uppercased() }
}
