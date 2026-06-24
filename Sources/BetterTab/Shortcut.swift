import SwiftUI
import BetterTabCore

/// A single neutral key-cap chip, in the style macOS uses in the Keyboard
/// settings list. Adapts to light/dark automatically.
struct KeyCapChip: View {
    let label: String
    var style: ChipStyle = .neutral

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(style.text)
            .frame(minWidth: 21, minHeight: 21)
            .padding(.horizontal, 3.5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(style.fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(style.stroke, lineWidth: 1)
            )
    }
}

enum ChipStyle {
    case neutral    // resting, on a card
    case accent     // composer preview emphasis
    case onAccent   // on a selected (accent-filled) row

    var fill: Color {
        switch self {
        case .neutral:  return Color.primary.opacity(0.06)
        case .accent:   return Color.accentColor.opacity(0.16)
        case .onAccent: return Color.white.opacity(0.22)
        }
    }
    var stroke: Color {
        switch self {
        case .neutral:  return Color.primary.opacity(0.08)
        case .accent:   return Color.accentColor.opacity(0.30)
        case .onAccent: return Color.white.opacity(0.28)
        }
    }
    var text: AnyShapeStyle {
        switch self {
        case .neutral:  return AnyShapeStyle(.secondary)
        case .accent:   return AnyShapeStyle(.tint)
        case .onAccent: return AnyShapeStyle(.white)
        }
    }
}

/// Renders a `KeyCombo` as macOS-style key chips: modifier glyphs then the key.
struct ShortcutView: View {
    let combo: KeyCombo
    var style: ChipStyle = .neutral

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(combo.modifiers.symbols.map(String.init).enumerated()), id: \.offset) { _, glyph in
                KeyCapChip(label: glyph, style: style)
            }
            KeyCapChip(label: combo.key.label, style: style)
        }
    }
}
