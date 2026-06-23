import SwiftUI
import BetterTabCore

/// Inline composer for a new binding: choose modifiers + a key from a mini
/// QWERTY keyboard, choose a target app, then bind.
struct AddBindingView: View {
    @EnvironmentObject var model: BindingsModel
    let onDone: () -> Void

    @State private var modifiers: ModifierKey = [.control, .option]
    @State private var selectedKey: Key?
    @State private var selectedBundleID: String?
    @State private var pickingApp = false
    @State private var appSearch = ""

    private let qwerty = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
    private let modifierOptions: [(ModifierKey, String)] = [
        (.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘"),
    ]

    private var isValid: Bool {
        !modifiers.isEmpty && selectedKey != nil && selectedBundleID != nil
    }

    private var filteredApps: [InstalledApp] {
        guard !appSearch.isEmpty else { return model.installedApps }
        return model.installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(appSearch)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("WHEN I PRESS")
            modifierRow
            keyboard

            sectionLabel("JUMP TO")
            appSelector

            if let error = model.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.danger)
            }

            HStack(spacing: 8) {
                Spacer()
                Button("Cancel", action: onDone)
                    .buttonStyle(SecondaryButtonStyle())
                Button("Bind shortcut", action: bind)
                    .buttonStyle(PrimaryButtonStyle(enabled: isValid))
                    .disabled(!isValid)
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.bgRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    // MARK: Pieces

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .heavy, design: .monospaced))
            .tracking(1.6)
            .foregroundStyle(Theme.textFaint)
    }

    private var modifierRow: some View {
        HStack(spacing: 6) {
            ForEach(modifierOptions, id: \.1) { option, glyph in
                Button {
                    toggle(option)
                } label: {
                    Keycap(label: glyph, lit: modifiers.contains(option), size: 30)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var keyboard: some View {
        VStack(spacing: 5) {
            ForEach(Array(qwerty.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 5) {
                    if index > 0 { Spacer(minLength: 0).frame(width: CGFloat(index) * 11) }
                    ForEach(Array(row), id: \.self) { letter in
                        Button {
                            selectedKey = key(for: letter)
                        } label: {
                            Keycap(
                                label: String(letter),
                                lit: selectedKey == key(for: letter),
                                size: 26
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var appSelector: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.16)) { pickingApp.toggle() }
            } label: {
                HStack(spacing: 10) {
                    if let id = selectedBundleID {
                        AppIcon(bundleID: id, size: 24)
                        Text(AppCatalog.name(forBundleID: id))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                    } else {
                        Image(systemName: "square.grid.2x2")
                            .foregroundStyle(Theme.textFaint)
                            .frame(width: 24, height: 24)
                        Text("Choose an app…")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: pickingApp ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textFaint)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(Theme.stroke, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            if pickingApp {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textFaint)
                        TextField("Search apps", text: $appSearch)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 7).fill(Theme.bg)
                            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Theme.stroke, lineWidth: 1))
                    )

                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(filteredApps) { app in
                                appRow(app)
                            }
                        }
                    }
                    .frame(maxHeight: 168)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Theme.bg)
                        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))
                )
                .padding(.top, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func appRow(_ app: InstalledApp) -> some View {
        Button {
            selectedBundleID = app.bundleID
            withAnimation(.easeOut(duration: 0.16)) { pickingApp = false }
            appSearch = ""
        } label: {
            HStack(spacing: 9) {
                AppIcon(bundleID: app.bundleID, size: 22)
                Text(app.name)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if selectedBundleID == app.bundleID {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedBundleID == app.bundleID ? Theme.accentSoft : .clear)
            )
        }
        .buttonStyle(HoverHighlightStyle())
    }

    // MARK: Actions

    private func toggle(_ modifier: ModifierKey) {
        if modifiers.contains(modifier) { modifiers.remove(modifier) }
        else { modifiers.insert(modifier) }
    }

    private func key(for letter: Character) -> Key? {
        Key.allCases.first { $0.label == String(letter) }
    }

    private func bind() {
        guard let key = selectedKey, let bundleID = selectedBundleID else { return }
        model.add(combo: KeyCombo(key: key, modifiers: modifiers), bundleID: bundleID)
        if model.errorMessage == nil { onDone() }
    }
}
