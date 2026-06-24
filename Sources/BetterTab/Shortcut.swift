import SwiftUI
import BetterTabCore

/// A single key-cap chip in the macOS Keyboard-settings idiom. Fully adaptive.
struct KeyCap: View {
    let label: String
    var emphasized = false

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(emphasized ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .frame(minWidth: 20, minHeight: 20)
            .padding(.horizontal, 3)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

/// Renders a `KeyCombo` as macOS-style key caps: modifier glyphs then the key.
struct ShortcutView: View {
    let combo: KeyCombo
    var emphasized = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(combo.modifiers.symbols.map(String.init).enumerated()), id: \.offset) { _, glyph in
                KeyCap(label: glyph, emphasized: emphasized)
            }
            KeyCap(label: combo.key.label, emphasized: emphasized)
        }
    }
}
