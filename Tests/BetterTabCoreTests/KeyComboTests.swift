import Testing
import Foundation
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

@Test func multiKeyChordDescriptionListsEveryKey() {
    // L+R+G+N+M held together, no modifiers. Keys render in key-code order.
    let chord = KeyCombo(virtualKeyCodes: [0x25, 0x0F, 0x05, 0x2D, 0x2E], modifiers: [])
    #expect(chord?.description == "G+R+L+N+M")
}

@Test func chordEqualityIgnoresKeyOrder() {
    let a = KeyCombo(keys: [Key(virtualKeyCode: 0x25), Key(virtualKeyCode: 0x0F)], modifiers: [])
    let b = KeyCombo(keys: [Key(virtualKeyCode: 0x0F), Key(virtualKeyCode: 0x25)], modifiers: [])
    #expect(a == b)
}

@Test func singleKeyDoesNotRequireEventTapButChordDoes() {
    #expect(KeyCombo(key: .f, modifiers: [.control]).requiresEventTap == false)
    #expect(KeyCombo(keys: [.l, .r], modifiers: []).requiresEventTap == true)
}

@Test func chordSurvivesJSONRoundTrip() throws {
    let chord = KeyCombo(keys: [.l, .r, .g], modifiers: [.control])
    let data = try JSONEncoder().encode(chord)
    let decoded = try JSONDecoder().decode(KeyCombo.self, from: data)
    #expect(decoded == chord)
}

@Test func chordMatchesExactHeldKeysAndModifiers() {
    let chord = KeyCombo(keys: [.l, .r, .g], modifiers: [.control])
    let codes = Set([Key.l, .r, .g].map(\.virtualKeyCode))
    #expect(chord.matches(pressedKeyCodes: codes, modifiers: [.control]))
}

@Test func chordDoesNotMatchPartialOrExtraKeys() {
    let chord = KeyCombo(keys: [.l, .r, .g], modifiers: [])
    let twoOfThree = Set([Key.l, .r].map(\.virtualKeyCode))
    let withExtra = Set([Key.l, .r, .g, .m].map(\.virtualKeyCode))
    #expect(chord.matches(pressedKeyCodes: twoOfThree, modifiers: []) == false)
    #expect(chord.matches(pressedKeyCodes: withExtra, modifiers: []) == false)
}

@Test func chordDoesNotMatchWhenModifiersDiffer() {
    let chord = KeyCombo(keys: [.l, .r], modifiers: [.control])
    let codes = Set([Key.l, .r].map(\.virtualKeyCode))
    #expect(chord.matches(pressedKeyCodes: codes, modifiers: []) == false)
}

@Test func decodesLegacySingleKeyShape() throws {
    // Shortcuts persisted before chords stored `{"key":3,"modifiers":3}`.
    let data = Data(#"{"key":3,"modifiers":3}"#.utf8)
    let decoded = try JSONDecoder().decode(KeyCombo.self, from: data)
    #expect(decoded == KeyCombo(key: .f, modifiers: [.control, .option]))
}
