import SwiftUI
import BetterTabCore

/// Native sheet for composing a new binding: a grouped `Form` with checkbox
/// modifiers and `Picker`s for the key and application, a live preview, and
/// standard Cancel / Add buttons.
struct AddSheet: View {
    @EnvironmentObject var model: BindingsModel
    @Environment(\.dismiss) private var dismiss

    @State private var control = false
    @State private var option = true
    @State private var command = true
    @State private var shift = false
    @State private var key: Key?
    @State private var bundleID: String?

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
                            HStack {
                                AppIcon(bundleID: app.bundleID, size: 16)
                                Text(app.name)
                            }
                            .tag(String?.some(app.bundleID))
                        }
                    }
                }

                Section("Preview") {
                    LabeledContent("Shortcut") {
                        HStack(spacing: 8) {
                            Text(combo?.description ?? "—")
                                .font(.body.monospaced())
                                .foregroundStyle(combo == nil ? .secondary : .primary)
                            if bundleID != nil {
                                Image(systemName: "arrow.right").foregroundStyle(.tertiary)
                                if let bundleID {
                                    AppIcon(bundleID: bundleID, size: 16)
                                    Text(AppCatalog.name(forBundleID: bundleID))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            if let error = model.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
            }

            Divider()
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add") { add() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
            }
            .padding(16)
        }
        .frame(width: 440)
        .onAppear { model.errorMessage = nil }
    }

    private func add() {
        guard let combo, let bundleID else { return }
        model.add(combo: combo, bundleID: bundleID)
        if model.errorMessage == nil { dismiss() }
    }
}
