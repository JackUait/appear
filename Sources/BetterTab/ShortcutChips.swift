import SwiftUI
import BetterTabCore

/// A single rounded key pill in the Airbnb palette.
struct KeyPill: View {
    let label: String

    var body: some View {
        Text(label)
            .font(AirTheme.font(12, .semibold))
            .foregroundStyle(AirTheme.textPrimary)
            .frame(minWidth: 21, minHeight: 21)
            .padding(.horizontal, 4)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(AirTheme.bgSubtle))
            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(AirTheme.border, lineWidth: 1))
    }
}

/// Renders a `KeyCombo` as a row of rounded key pills.
struct ShortcutChips: View {
    let combo: KeyCombo

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(combo.modifiers.symbols.map(String.init).enumerated()), id: \.offset) { _, glyph in
                KeyPill(label: glyph)
            }
            KeyPill(label: combo.key.label)
        }
    }
}
