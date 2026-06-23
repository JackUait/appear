import SwiftUI
import BetterTabCore

/// One row in the bindings list: app identity on the left, the keycap combo on
/// the right, with a remove control revealed on hover.
struct BindingRow: View {
    let binding: AppBinding
    let onRemove: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 11) {
            AppIcon(bundleID: binding.bundleID)

            VStack(alignment: .leading, spacing: 1) {
                Text(AppCatalog.name(forBundleID: binding.bundleID))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(binding.bundleID)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.textFaint)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            ComboView(combo: binding.combo)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(Theme.surfaceHi))
                    .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .opacity(hovering ? 1 : 0)
            .help("Remove shortcut")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(hovering ? Theme.bgRaised : .clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}
