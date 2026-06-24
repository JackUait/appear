/// OS seam for registering global hotkeys. Implemented in the executable by a
/// Carbon-backed adapter; faked in tests.
public protocol HotKeyRegistering: AnyObject {
    /// Registers `combo` so that `handler` runs when it is pressed system-wide.
    func register(combo: KeyCombo, handler: @escaping () -> Void) throws
    /// Removes all previously registered hotkeys.
    func unregisterAll()
}
