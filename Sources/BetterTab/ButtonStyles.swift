import SwiftUI

/// Amber, filled call-to-action. Dims when disabled.
struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(enabled ? Color(hex: 0x1A1400) : Theme.textFaint)
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(enabled ? Theme.accent : Theme.surface)
                    .opacity(configuration.isPressed ? 0.82 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.white.opacity(enabled ? 0.18 : 0.04), lineWidth: 1)
            )
            .shadow(color: enabled ? Theme.accent.opacity(0.3) : .clear,
                    radius: configuration.isPressed ? 2 : 6, y: 1)
    }
}

/// Quiet, outlined secondary action.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.surface)
                    .opacity(configuration.isPressed ? 0.7 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }
}

/// Row button that lifts subtly on hover/press; used in lists.
struct HoverHighlightStyle: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hovering ? Theme.surfaceHi : .clear)
            )
            .onHover { hovering = $0 }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
