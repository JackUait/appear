import Testing
@testable import BetterTabCore

@Test func modifierSymbolsAreInCanonicalOrder() {
    let mods: ModifierKey = [.command, .control, .shift, .option]
    #expect(mods.symbols == "⌃⌥⇧⌘")
}

@Test func emptyModifiersHaveNoSymbols() {
    #expect(ModifierKey().symbols == "")
}

@Test func keyLabelIsUppercasedLetter() {
    #expect(Key.s.label == "S")
}

@Test func keyComboDescriptionCombinesModifiersAndKey() {
    let combo = KeyCombo(key: .s, modifiers: [.control, .option])
    #expect(combo.description == "⌃⌥S")
}

@Test func capturingSupportedKeyCodeBuildsCombo() {
    // 0x01 is the virtual key code for "S".
    let combo = KeyCombo(virtualKeyCode: 0x01, modifiers: [.control, .option])
    #expect(combo == KeyCombo(key: .s, modifiers: [.control, .option]))
}

@Test func capturingUnsupportedKeyCodeReturnsNil() {
    // 0x12 is the virtual key code for "1", which is not a supported Key.
    #expect(KeyCombo(virtualKeyCode: 0x12, modifiers: [.command]) == nil)
}
