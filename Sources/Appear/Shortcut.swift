import SwiftUI
import AppearCore

/// A single key-cap chip in the macOS Keyboard-settings idiom — subtly raised,
/// fully adaptive.
struct KeyCap: View {
    let label: String
    var emphasized = false

    var body: some View {
        Text(label)
            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
            .foregroundStyle(emphasized ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .frame(minWidth: 22, minHeight: 22)
            .padding(.horizontal, 3)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.quaternary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(.separator.opacity(0.6), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 0.5, y: 0.5)
    }
}

/// Renders a `KeyCombo` as macOS-style key caps: modifier glyphs, then each
/// key in the chord.
struct ShortcutView: View {
    let combo: KeyCombo
    var emphasized = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(combo.modifiers.symbols.map(String.init).enumerated()), id: \.offset) { _, glyph in
                KeyCap(label: glyph, emphasized: emphasized)
            }
            ForEach(Array(combo.keys.enumerated()), id: \.offset) { _, key in
                KeyCap(label: key.label, emphasized: emphasized)
            }
        }
    }
}
