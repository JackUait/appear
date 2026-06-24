import SwiftUI
import BetterTabCore

/// Add/edit sheet for the standalone window: a grouped `Form` with checkbox
/// modifiers, key & application pickers, and a live preview.
struct EditorSheet: View {
    @EnvironmentObject var model: BindingsModel
    @Environment(\.dismiss) private var dismiss

    let existing: AppBinding?

    @State private var control: Bool
    @State private var option: Bool
    @State private var shift: Bool
    @State private var command: Bool
    @State private var key: Key?
    @State private var bundleID: String?
    @State private var error: String?

    init(existing: AppBinding?) {
        self.existing = existing
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
        VStack(spacing: 0) {
            Form {
                Section("Trigger") {
                    LabeledContent("Modifiers") {
                        HStack(spacing: 14) {
                            Toggle("⌃", isOn: $control).toggleStyle(.checkbox)
                            Toggle("⌥", isOn: $option).toggleStyle(.checkbox)
                            Toggle("⇧", isOn: $shift).toggleStyle(.checkbox)
                            Toggle("⌘", isOn: $command).toggleStyle(.checkbox)
                        }
                    }
                    Picker("Key", selection: $key) {
                        Text("Choose…").tag(Key?.none)
                        ForEach(Key.allCases, id: \.self) { key in
                            Text(key.label).tag(Key?.some(key))
                        }
                    }
                }

                Section("Target") {
                    Picker("Application", selection: $bundleID) {
                        Text("Choose…").tag(String?.none)
                        ForEach(model.installedApps) { app in
                            Text(app.name).tag(String?.some(app.bundleID))
                        }
                    }
                }

                Section("Preview") {
                    LabeledContent("Shortcut") {
                        HStack(spacing: 8) {
                            if let combo {
                                ShortcutView(combo: combo, emphasized: true)
                            } else {
                                Text("—").foregroundStyle(.secondary)
                            }
                            if let bundleID {
                                Image(systemName: "arrow.right").foregroundStyle(.tertiary)
                                AppIcon(bundleID: bundleID, size: 18)
                                Text(AppCatalog.name(forBundleID: bundleID)).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            if let error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
            }

            Divider()
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(existing == nil ? "Add" : "Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
            }
            .padding(16)
        }
        .frame(width: 460)
    }

    private func save() {
        guard let combo, let bundleID else { return }
        if let existing {
            model.update(existing, combo: combo, bundleID: bundleID)
        } else {
            model.add(combo: combo, bundleID: bundleID)
        }
        if model.errorMessage == nil {
            dismiss()
        } else {
            error = model.errorMessage
        }
    }
}
