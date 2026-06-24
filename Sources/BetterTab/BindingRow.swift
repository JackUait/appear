import SwiftUI
import AppKit
import BetterTabCore

/// One row in the grouped shortcuts list: app identity on the left, the shortcut
/// chips on the right. Highlights with the system selection color when selected.
struct BindingRow: View {
    let binding: AppBinding
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            AppIcon(bundleID: binding.bundleID, size: 26)

            Text(AppCatalog.name(forBundleID: binding.bundleID))
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? Color(nsColor: .alternateSelectedControlTextColor) : .primary)

            Spacer(minLength: 12)

            ShortcutView(combo: binding.combo, style: isSelected ? .onAccent : .neutral)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color(nsColor: .selectedContentBackgroundColor) : .clear)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}
