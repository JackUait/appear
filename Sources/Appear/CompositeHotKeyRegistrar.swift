import AppearCore

/// Routes each shortcut to the backend that can express it: single-key combos
/// go to Carbon (no permission needed); multi-key chords go to the event tap
/// (which needs Accessibility). Reload-style callers (`unregisterAll` then
/// `register` each) get both backends cleared and rebuilt together.
final class CompositeHotKeyRegistrar: HotKeyRegistering {
    private let carbon = CarbonHotKeyRegistrar()
    let chordTap = ChordEventTapMonitor()

    /// Set when a multi-key chord couldn't be installed because Accessibility
    /// isn't granted yet. The single-key shortcuts still register, so the rest
    /// of the app keeps working; the model surfaces this to prompt the user.
    private(set) var needsAccessibility = false

    func register(combo: KeyCombo, handler: @escaping () -> Void) throws {
        if combo.requiresEventTap {
            do {
                try chordTap.register(combo: combo, handler: handler)
            } catch HotKeyRegistrarError.accessibilityNotGranted {
                needsAccessibility = true
            }
        } else {
            try carbon.register(combo: combo, handler: handler)
        }
    }

    func unregisterAll() {
        needsAccessibility = false
        carbon.unregisterAll()
        chordTap.unregisterAll()
    }
}
