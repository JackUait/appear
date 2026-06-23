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
