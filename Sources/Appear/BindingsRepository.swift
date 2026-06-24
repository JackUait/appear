import Foundation
import AppearCore

/// Persists the user's bindings across launches via `UserDefaults` (JSON-encoded).
struct BindingsRepository {
    private let key = "bindings.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [AppBinding] {
        guard let data = defaults.data(forKey: key),
              let bindings = try? JSONDecoder().decode([AppBinding].self, from: data) else {
            return []
        }
        return bindings
    }

    func save(_ bindings: [AppBinding]) {
        guard let data = try? JSONEncoder().encode(bindings) else { return }
        defaults.set(data, forKey: key)
    }
}
