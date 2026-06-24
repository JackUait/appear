import Foundation
import AppKit
import AppearCore

/// Identifiable wrapper so a binding can drive `List`/`Table` selection.
/// Combos are unique, so the combo description is a stable id.
struct BindingItem: Identifiable, Hashable {
    let binding: AppBinding
    var id: String { binding.combo.description }
}

/// Observable source of truth for the UI. Owns the core objects, keeps the live
/// hotkey registrations in sync with the edited list, and persists changes.
@MainActor
final class BindingsModel: ObservableObject {
    @Published private(set) var bindings: [AppBinding] = []
    @Published var errorMessage: String?

    /// True while an inline editor (add or edit) is open in the popover. The
    /// status-item controller reads this to keep the popover from auto-closing
    /// on outside clicks mid-edit.
    @Published var isEditing = false

    /// True when a saved multi-key chord can't run because Accessibility access
    /// hasn't been granted. Drives the in-popover permission banner.
    @Published private(set) var needsAccessibility = false

    private let store = BindingStore()
    private let registrar = CompositeHotKeyRegistrar()
    private let activator = WorkspaceAppActivator()
    private var didPromptAccessibility = false
    private lazy var coordinator = HotKeyCoordinator(
        store: store, registrar: registrar, activator: activator
    )
    private let repository: BindingsRepository

    /// Installed apps, loaded once for the picker.
    let installedApps: [InstalledApp]

    init(repository: BindingsRepository = BindingsRepository()) {
        self.repository = repository
        self.installedApps = AppCatalog.installedApps()

        let loaded = repository.load()
        apply(loaded.isEmpty ? Self.seedBindings : loaded)
    }

    /// Friendly defaults so a fresh install isn't an empty void.
    static let seedBindings: [AppBinding] = [
        AppBinding(combo: KeyCombo(key: .s, modifiers: [.control, .option]),
                   bundleID: "com.apple.Safari"),
        AppBinding(combo: KeyCombo(key: .f, modifiers: [.control, .option]),
                   bundleID: "com.apple.finder"),
    ]

    /// Temporarily tears down the live global hotkeys while the user records a
    /// new shortcut. Otherwise Carbon intercepts any keystroke that matches an
    /// already-registered combo system-wide, so the recorder never sees that
    /// keyDown and the combo can't be captured (it just fires the old hotkey).
    func suspendHotkeys() {
        registrar.unregisterAll()
    }

    /// Restores the global hotkeys after recording finishes.
    func resumeHotkeys() {
        try? coordinator.reload(bindings)
    }

    func add(combo: KeyCombo, bundleID: String) {
        guard !bindings.contains(where: { $0.combo == combo }) else {
            errorMessage = "\(combo.description) is already bound."
            return
        }
        apply(bindings + [AppBinding(combo: combo, bundleID: bundleID)])
    }

    func remove(_ binding: AppBinding) {
        apply(bindings.filter { $0 != binding })
    }

    /// Edits an existing binding in place (combo and/or target). Rejects a combo
    /// that collides with a *different* binding.
    func update(_ old: AppBinding, combo: KeyCombo, bundleID: String) {
        if combo != old.combo, bindings.contains(where: { $0.combo == combo }) {
            errorMessage = "\(combo.description) is already bound."
            return
        }
        apply(bindings.filter { $0 != old } + [AppBinding(combo: combo, bundleID: bundleID)])
    }

    func isBound(_ combo: KeyCombo) -> Bool {
        bindings.contains { $0.combo == combo }
    }

    /// Immediately activates (or launches) a binding's target — used when the
    /// user clicks a row in the launcher popover.
    func jump(to binding: AppBinding) {
        if activator.activateRunningApp(bundleID: binding.bundleID) { return }
        guard let url = activator.applicationURL(bundleID: binding.bundleID) else { return }
        try? activator.launchApplication(at: url)
    }

    /// Identifiable rows for `List`/`Table`.
    var items: [BindingItem] { bindings.map(BindingItem.init) }

    /// Re-applies registrations after the user grants Accessibility, so a
    /// multi-key chord that couldn't install at first starts working without a
    /// relaunch. Called when the app becomes active.
    func reapplyHotkeysIfNeeded() {
        guard registrar.needsAccessibility, ChordEventTapMonitor.isTrusted else { return }
        apply(bindings)
    }

    /// Re-registers every hotkey from `next`, then persists. Sorted by app name.
    private func apply(_ next: [AppBinding]) {
        do {
            try coordinator.reload(next)
            bindings = next.sorted {
                AppCatalog.name(forBundleID: $0.bundleID)
                    .localizedCaseInsensitiveCompare(AppCatalog.name(forBundleID: $1.bundleID))
                    == .orderedAscending
            }
            repository.save(bindings)
            errorMessage = nil
            needsAccessibility = registrar.needsAccessibility
            if needsAccessibility { promptForAccessibilityOnce() }
        } catch {
            errorMessage = "Couldn't update shortcuts: \(error)"
        }
    }

    private func promptForAccessibilityOnce() {
        guard !didPromptAccessibility else { return }
        didPromptAccessibility = true
        ChordEventTapMonitor.promptForAccessibility()
    }

    /// Opens System Settings at the Accessibility pane so the user can grant
    /// access for multi-key chords.
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
