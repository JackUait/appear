import Foundation
import BetterTabCore

/// Observable source of truth for the UI. Owns the core objects, keeps the live
/// hotkey registrations in sync with the edited list, and persists changes.
@MainActor
final class BindingsModel: ObservableObject {
    @Published private(set) var bindings: [AppBinding] = []
    @Published var errorMessage: String?

    private let store = BindingStore()
    private let registrar = CarbonHotKeyRegistrar()
    private let activator = WorkspaceAppActivator()
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

    func isBound(_ combo: KeyCombo) -> Bool {
        bindings.contains { $0.combo == combo }
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
        } catch {
            errorMessage = "Couldn't update shortcuts: \(error)"
        }
    }
}
