import SwiftUI
import BetterTabCore

/// Compact inline editor used inside the popover, so shortcuts can be edited
/// without leaving the menu-bar view. Native controls throughout.
struct InlineEditor: View {
    let apps: [InstalledApp]
    var error: String?
    let onSave: (KeyCombo, String) -> Void
    let onCancel: () -> Void
    var onDelete: (() -> Void)?

    @State private var combo: KeyCombo?
    @State private var bundleID: String?

    private let isNew: Bool

    init(
        apps: [InstalledApp],
        existing: AppBinding?,
        error: String? = nil,
        onSave: @escaping (KeyCombo, String) -> Void,
        onCancel: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.apps = apps
        self.error = error
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
        self.isNew = existing == nil

        _combo = State(initialValue: existing?.combo)
        _bundleID = State(initialValue: existing?.bundleID)
    }

    private var isValid: Bool { combo != nil && bundleID != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ShortcutRecorder(combo: $combo)

            appMenu

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                if let onDelete {
                    Button("Delete", role: .destructive, action: onDelete)
                        .controlSize(.small)
                }
                Spacer()
                Button("Cancel", action: onCancel)
                    .controlSize(.small)
                Button(isNew ? "Add" : "Save") {
                    if let combo, let bundleID { onSave(combo, bundleID) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!isValid)
            }
        }
        .padding(11)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
    }

    private var appMenu: some View {
        Menu {
            ForEach(apps) { app in
                Button(app.name) { bundleID = app.bundleID }
            }
        } label: {
            HStack(spacing: 7) {
                if let bundleID {
                    AppIcon(bundleID: bundleID, size: 17)
                    Text(AppCatalog.name(forBundleID: bundleID))
                } else {
                    Image(systemName: "app.dashed").foregroundStyle(.secondary)
                    Text("Choose an app").foregroundStyle(.secondary)
                }
            }
        }
        .menuStyle(.button)
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}
