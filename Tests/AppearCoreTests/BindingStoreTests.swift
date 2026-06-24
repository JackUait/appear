import Testing
@testable import AppearCore

private let comboS = KeyCombo(key: .s, modifiers: [.control, .option])
private let safari = AppBinding(combo: comboS, bundleID: "com.apple.Safari")

@Test func addThenResolveReturnsBinding() throws {
    let store = BindingStore()
    try store.add(safari)
    #expect(store.binding(for: comboS) == safari)
}

@Test func resolveUnknownComboReturnsNil() {
    let store = BindingStore()
    #expect(store.binding(for: comboS) == nil)
}

@Test func removeDeletesBinding() throws {
    let store = BindingStore()
    try store.add(safari)
    store.remove(combo: comboS)
    #expect(store.binding(for: comboS) == nil)
}

@Test func addingDuplicateComboThrowsConflict() throws {
    let store = BindingStore()
    try store.add(safari)
    let clash = AppBinding(combo: comboS, bundleID: "com.apple.Terminal")
    #expect(throws: BindingStoreError.duplicateCombo(comboS)) {
        try store.add(clash)
    }
}

@Test func removeAllEmptiesTheStore() throws {
    let store = BindingStore()
    try store.add(safari)
    try store.add(AppBinding(
        combo: KeyCombo(key: .t, modifiers: [.control, .option]),
        bundleID: "com.apple.Terminal"
    ))
    store.removeAll()
    #expect(store.all.isEmpty)
    #expect(store.binding(for: comboS) == nil)
}
