/// Binds a keyboard shortcut to a target application (by bundle identifier).
public struct AppBinding: Hashable, Sendable, Codable {
    public let combo: KeyCombo
    public let bundleID: String

    public init(combo: KeyCombo, bundleID: String) {
        self.combo = combo
        self.bundleID = bundleID
    }
}
