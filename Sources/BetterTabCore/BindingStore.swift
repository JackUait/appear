/// Errors raised while mutating a `BindingStore`.
public enum BindingStoreError: Error, Equatable {
    /// A binding already exists for this combo.
    case duplicateCombo(KeyCombo)
}

/// In-memory collection of shortcut→app bindings, keyed by combo.
public final class BindingStore {
    private var bindings: [KeyCombo: AppBinding] = [:]

    public init() {}

    /// Adds a binding. Throws `.duplicateCombo` if the combo is already bound.
    public func add(_ binding: AppBinding) throws {
        guard bindings[binding.combo] == nil else {
            throw BindingStoreError.duplicateCombo(binding.combo)
        }
        bindings[binding.combo] = binding
    }

    public func remove(combo: KeyCombo) {
        bindings[combo] = nil
    }

    /// Removes every binding.
    public func removeAll() {
        bindings.removeAll()
    }

    public func binding(for combo: KeyCombo) -> AppBinding? {
        bindings[combo]
    }

    public var all: [AppBinding] { Array(bindings.values) }
}
