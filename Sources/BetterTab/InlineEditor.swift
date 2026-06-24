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

    @State private var control: Bool
    @State private var option: Bool
    @State private var shift: Bool
    @State private var command: Bool
    @State private var key: Key?
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

        let mods = existing?.combo.modifiers ?? [.command, .option]
        _control = State(initialValue: mods.contains(.control))
        _option = State(initialValue: mods.contains(.option))
        _shift = State(initialValue: mods.contains(.shift))
        _command = State(initialValue: mods.contains(.command))
        _key = State(initialValue: existing?.combo.key)
        _bundleID = State(initialValue: existing?.bundleID)
    }

    private var modifiers: ModifierKey {
        var m = ModifierKey()
        if control { m.insert(.control) }
        if option { m.insert(.option) }
        if shift { m.insert(.shift) }
        if command { m.insert(.command) }
        return m
    }

    private var combo: KeyCombo? {
        guard let key, !modifiers.isEmpty else { return nil }
        return KeyCombo(key: key, modifiers: modifiers)
    }

    private var isValid: Bool { combo != nil && bundleID != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 5) {
                modifier("⌃", $control)
                modifier("⌥", $option)
                modifier("⇧", $shift)
                modifier("⌘", $command)
                keyMenu
                Spacer(minLength: 0)
            }

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

    private func modifier(_ glyph: String, _ isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Text(glyph)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isOn.wrappedValue ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                .frame(width: 26, height: 24)
                .background(isOn.wrappedValue ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary),
                           in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var keyMenu: some View {
        Menu {
            ForEach(Key.allCases, id: \.self) { key in
                Button(key.label) { self.key = key }
            }
        } label: {
            Text(key?.label ?? "Key")
                .frame(minWidth: 26)
        }
        .menuStyle(.button)
        .buttonStyle(.bordered)
        .controlSize(.small)
        .fixedSize()
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
