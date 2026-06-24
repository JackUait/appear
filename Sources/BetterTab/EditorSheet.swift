import SwiftUI
import BetterTabCore

/// Add/edit sheet for the standalone window: a grouped `Form` with checkbox
/// modifiers, key & application pickers, and a live preview.
struct EditorSheet: View {
    @EnvironmentObject var model: BindingsModel
    @Environment(\.dismiss) private var dismiss

    let existing: AppBinding?

    @State private var combo: KeyCombo?
    @State private var bundleID: String?
    @State private var error: String?

    init(existing: AppBinding?) {
        self.existing = existing
        _combo = State(initialValue: existing?.combo)
        _bundleID = State(initialValue: existing?.bundleID)
    }

    private var isValid: Bool { combo != nil && bundleID != nil }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Trigger") {
                    LabeledContent("Shortcut") {
                        ShortcutRecorder(combo: $combo,
                                         onRecordingChange: { $0 ? model.suspendHotkeys() : model.resumeHotkeys() })
                            .frame(maxWidth: 220)
                    }
                }

                Section("Target") {
                    LabeledContent("Application") {
                        AppPicker(apps: model.installedApps, bundleID: $bundleID)
                            .frame(maxWidth: 260)
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
