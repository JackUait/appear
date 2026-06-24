import SwiftUI
import BetterTabCore

/// Inline editor for adding or editing a binding, used in both the popover and
/// the window. Airbnb styling: circular modifier toggles, pill popups, coral CTA.
struct BindingEditor: View {
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
        VStack(alignment: .leading, spacing: 12) {
            label("PRESS")
            HStack(spacing: 7) {
                modifier("⌃", $control)
                modifier("⌥", $option)
                modifier("⇧", $shift)
                modifier("⌘", $command)
                keyPicker
            }

            label("OPEN")
            appPicker

            if let error {
                Text(error)
                    .font(AirTheme.font(12, .medium))
                    .foregroundStyle(AirTheme.danger)
            }

            HStack {
                if let onDelete {
                    Button("Delete", action: onDelete)
                        .buttonStyle(AirTextButton(tint: AirTheme.danger))
                }
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(AirTextButton())
                Button(isNew ? "Add" : "Save") {
                    if let combo, let bundleID { onSave(combo, bundleID) }
                }
                .buttonStyle(AirPrimaryButton())
                .disabled(!isValid)
                .opacity(isValid ? 1 : 0.5)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AirTheme.bg)
                .shadow(color: .black.opacity(0.10), radius: 14, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AirTheme.border, lineWidth: 1)
        )
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(AirTheme.font(10, .heavy))
            .tracking(1.2)
            .foregroundStyle(AirTheme.textFaint)
    }

    private func modifier(_ glyph: String, _ isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Text(glyph)
                .font(AirTheme.font(14, .semibold))
                .foregroundStyle(isOn.wrappedValue ? .white : AirTheme.textPrimary)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(isOn.wrappedValue ? AnyShapeStyle(AirTheme.coralGradient) : AnyShapeStyle(AirTheme.bg))
                )
                .overlay(Circle().strokeBorder(isOn.wrappedValue ? .clear : AirTheme.border, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private var keyPicker: some View {
        Menu {
            ForEach(Key.allCases, id: \.self) { key in
                Button(key.label) { self.key = key }
            }
        } label: {
            HStack(spacing: 4) {
                Text(key?.label ?? "Key")
                    .font(AirTheme.font(13, .semibold))
                    .foregroundStyle(key == nil ? AirTheme.textSecondary : AirTheme.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(AirTheme.textSecondary)
            }
            .padding(.horizontal, 13)
            .frame(height: 32)
            .background(Capsule().strokeBorder(AirTheme.border, lineWidth: 1.5))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var appPicker: some View {
        Menu {
            ForEach(apps) { app in
                Button(app.name) { bundleID = app.bundleID }
            }
        } label: {
            HStack(spacing: 9) {
                if let bundleID {
                    AppIcon(bundleID: bundleID, size: 22)
                    Text(AppCatalog.name(forBundleID: bundleID))
                        .font(AirTheme.font(14, .medium))
                        .foregroundStyle(AirTheme.textPrimary)
                } else {
                    Image(systemName: "square.grid.2x2")
                        .foregroundStyle(AirTheme.textFaint)
                    Text("Choose an app")
                        .font(AirTheme.font(14))
                        .foregroundStyle(AirTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AirTheme.textSecondary)
            }
            .padding(.horizontal, 13)
            .frame(height: 42)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(AirTheme.border, lineWidth: 1.5))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}
