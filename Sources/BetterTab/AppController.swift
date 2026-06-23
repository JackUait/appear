import Foundation
import BetterTabCore

/// Owns the core objects and installs the single live binding (⌃⌥S → Safari).
final class AppController {
    private let store = BindingStore()
    private let registrar = CarbonHotKeyRegistrar()
    private let activator = WorkspaceAppActivator()
    private lazy var coordinator = HotKeyCoordinator(
        store: store, registrar: registrar, activator: activator
    )

    private let binding = AppBinding(
        combo: KeyCombo(key: .s, modifiers: [.control, .option]),
        bundleID: "com.apple.Safari"
    )

    /// Text shown in the menu bar, e.g. "⌃⌥S → Safari".
    var statusText: String { "\(binding.combo.description) → Safari" }

    /// Registers the live hotkey. Call once at launch.
    func start() {
        try? coordinator.install(binding)
    }
}
