import SwiftUI
import BetterTabCore

/// A single physical-looking keycap with a backlit legend.
struct Keycap: View {
    let label: String
    var lit: Bool = true
    var size: CGFloat = 24

    var body: some View {
        Text(label)
            .font(.system(size: size * 0.46, weight: .bold, design: .monospaced))
            .foregroundStyle(lit ? Theme.accent : Theme.textFaint)
            .shadow(color: lit ? Theme.accent.opacity(0.55) : .clear, radius: lit ? 5 : 0)
            .frame(minWidth: size, minHeight: size)
            .padding(.horizontal, size * 0.18)
            .background(
                RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(lit ? 0.12 : 0.05),
                                Color.white.opacity(0.015),
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                    .strokeBorder(lit ? Theme.strokeStrong : Theme.stroke, lineWidth: 1)
            )
            .overlay(alignment: .top) {            // crisp top light line
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(lit ? 0.18 : 0.06))
                    .frame(height: 1)
                    .padding(.horizontal, size * 0.22)
                    .padding(.top, 1.5)
            }
            .shadow(color: .black.opacity(0.45), radius: 1.5, y: 1.5)
    }
}

/// Renders a `KeyCombo` as a row of modifier keycaps followed by the key keycap.
struct ComboView: View {
    let combo: KeyCombo
    var size: CGFloat = 24

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(combo.modifiers.symbols.map(String.init).enumerated()), id: \.offset) { _, glyph in
                Keycap(label: glyph, size: size)
            }
            Keycap(label: combo.key.label, size: size)
        }
    }
}
