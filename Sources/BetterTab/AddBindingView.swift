import SwiftUI
import AppKit
import BetterTabCore

/// Inline composer styled like a System Settings form: modifier pills, a key
/// popup, an application popup, a live preview, and native action buttons.
struct AddBindingView: View {
    @EnvironmentObject var model: BindingsModel
    let onDone: () -> Void

    @State private var modifiers: ModifierKey = [.command, .option]
    @State private var selectedKey: Key?
    @State private var selectedBundleID: String?

    private let modifierOptions: [(ModifierKey, String)] = [
        (.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘"),
    ]

    private var composed: KeyCombo? {
        guard let key = selectedKey, !modifiers.isEmpty else { return nil }
        return KeyCombo(key: key, modifiers: modifiers)
    }

    private var isValid: Bool { composed != nil && selectedBundleID != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("New Shortcut")
                .font(.system(size: 13, weight: .semibold))

            VStack(spacing: 9) {
                field("Modifiers") { modifierPills }
                field("Key") { keyMenu }
                field("Application") { appMenu }
            }

            preview

            if let error = model.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.multicolor)
            }

            HStack(spacing: 8) {
                Spacer()
                Button("Cancel", action: onDone)
                    .controlSize(.regular)
                Button("Add Shortcut", action: bind)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(!isValid)
            }
            .padding(.top, 1)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
                )
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }

    // MARK: Rows

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .trailing)
            content()
            Spacer(minLength: 0)
        }
    }

    private var modifierPills: some View {
        HStack(spacing: 6) {
            ForEach(modifierOptions, id: \.1) { option, glyph in
                Button {
                    if modifiers.contains(option) { modifiers.remove(option) }
                    else { modifiers.insert(option) }
                } label: {
                    Text(glyph)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(modifiers.contains(option) ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                        .frame(width: 30, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(modifiers.contains(option) ? Color.accentColor : Color.primary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .strokeBorder(modifiers.contains(option) ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var keyMenu: some View {
        Menu {
            ForEach(Key.allCases, id: \.self) { key in
                Button(key.label) { selectedKey = key }
            }
        } label: {
            Text(selectedKey?.label ?? "Choose…")
                .frame(minWidth: 40)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
    }

    private var appMenu: some View {
        Menu {
            ForEach(model.installedApps) { app in
                Button {
                    selectedBundleID = app.bundleID
                } label: {
                    Text(app.name)
                }
            }
        } label: {
            HStack(spacing: 7) {
                if let id = selectedBundleID {
                    AppIcon(bundleID: id, size: 16)
                    Text(AppCatalog.name(forBundleID: id))
                } else {
                    Text("Choose…").foregroundStyle(.secondary)
                }
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
    }

    @ViewBuilder private var preview: some View {
        if let combo = composed {
            HStack(spacing: 9) {
                ShortcutView(combo: combo, style: .accent)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                if let id = selectedBundleID {
                    AppIcon(bundleID: id, size: 18)
                    Text(AppCatalog.name(forBundleID: id))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Choose an app")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 2)
            .transition(.opacity)
        }
    }

    private func bind() {
        guard let combo = composed, let bundleID = selectedBundleID else { return }
        model.add(combo: combo, bundleID: bundleID)
        if model.errorMessage == nil { onDone() }
    }
}
