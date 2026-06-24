import Testing
@testable import BetterTabCore

@Test func modifierSymbolsAreInCanonicalOrder() {
    let mods: ModifierKey = [.command, .control, .shift, .option]
    #expect(mods.symbols == "⌃⌥⇧⌘")
}

@Test func emptyModifiersHaveNoSymbols() {
    #expect(ModifierKey().symbols == "")
}

@Test func keyLabelForLetterIsUppercased() {
    // 0x01 is the virtual key code for "S".
    #expect(Key(virtualKeyCode: 0x01).label == "S")
}

@Test func keyLabelForNonLetterKeys() {
    #expect(Key(virtualKeyCode: 0x12).label == "1")   // digit
    #expect(Key(virtualKeyCode: 0x7C).label == "→")   // right arrow
    #expect(Key(virtualKeyCode: 0x60).label == "F5")  // function key
    #expect(Key(virtualKeyCode: 0x31).label == "␣")   // space
}

@Test func keyComboDescriptionCombinesModifiersAndKey() {
    let combo = KeyCombo(key: Key(virtualKeyCode: 0x01), modifiers: [.control, .option])
    #expect(combo.description == "⌃⌥S")
}

@Test func capturingLetterKeyCodeBuildsCombo() {
    // 0x01 is the virtual key code for "S".
    let combo = KeyCombo(virtualKeyCode: 0x01, modifiers: [.control, .option])
    #expect(combo == KeyCombo(key: Key(virtualKeyCode: 0x01), modifiers: [.control, .option]))
}

@Test func capturingNonLetterKeyCodeBuildsCombo() {
    // 0x12 ("1") was unsupported before; any key is now allowed.
    let combo = KeyCombo(virtualKeyCode: 0x12, modifiers: [.command])
    #expect(combo?.description == "⌘1")
}

@Test func capturingFourModifiersAndKeyGivesFiveGlyphs() {
    let combo = KeyCombo(virtualKeyCode: 0x7C, // right arrow
                         modifiers: [.control, .option, .shift, .command])
    #expect(combo?.description == "⌃⌥⇧⌘→")
}

@Test func capturingBareModifierKeyCodeReturnsNil() {
    // 0x38 is the virtual key code for Shift, which can't be a shortcut's key.
    #expect(KeyCombo(virtualKeyCode: 0x38, modifiers: [.command]) == nil)
}
