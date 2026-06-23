import Foundation

/// Errors raised while activating a binding's target app.
public enum ActivationError: Error, Equatable {
    /// The target app is neither running nor installed.
    case notInstalled(bundleID: String)
}

/// Installs bindings and reacts to hotkey presses by jumping to the target app.
public final class HotKeyCoordinator {
    private let store: BindingStore
    private let registrar: HotKeyRegistering
    private let activator: AppActivating

    public init(store: BindingStore, registrar: HotKeyRegistering, activator: AppActivating) {
        self.store = store
        self.registrar = registrar
        self.activator = activator
    }

    /// Stores the binding and registers its combo with the OS.
    public func install(_ binding: AppBinding) throws {
        try store.add(binding)
        try registrar.register(combo: binding.combo) { [weak self] in
            try? self?.handle(combo: binding.combo)
        }
    }

    /// Resolves `combo` to its binding and activates (or launches) the target.
    func handle(combo: KeyCombo) throws {
        guard let binding = store.binding(for: combo) else { return }
        if activator.activateRunningApp(bundleID: binding.bundleID) { return }
        guard let url = activator.applicationURL(bundleID: binding.bundleID) else {
            throw ActivationError.notInstalled(bundleID: binding.bundleID)
        }
        try activator.launchApplication(at: url)
    }
}
