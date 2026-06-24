import SwiftUI
import AppKit
import BetterTabCore

/// The menu-bar popover, re-imagined Airbnb-style and fully editable inline:
/// tap a row to jump, hover to edit/delete, or add a shortcut — all without
/// leaving the compact view.
struct RootView: View {
    @EnvironmentObject var model: BindingsModel
    @Environment(\.openWindow) private var openWindow

    @State private var editingID: String?
    @State private var addingNew = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(AirTheme.border)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(model.items) { item in
                        if editingID == item.id {
                            BindingEditor(
                                apps: model.installedApps,
                                existing: item.binding,
                                error: model.errorMessage,
                                onSave: { combo, bundleID in
                                    model.update(item.binding, combo: combo, bundleID: bundleID)
                                    if model.errorMessage == nil { closeEditors() }
                                },
                                onCancel: closeEditors,
                                onDelete: {
                                    model.remove(item.binding)
                                    closeEditors()
                                }
                            )
                        } else {
                            CompactRow(
                                binding: item.binding,
                                onJump: { model.jump(to: item.binding) },
                                onEdit: { startEditing(item.id) },
                                onDelete: { model.remove(item.binding) }
                            )
                        }
                    }

                    if addingNew {
                        BindingEditor(
                            apps: model.installedApps,
                            existing: nil,
                            error: model.errorMessage,
                            onSave: { combo, bundleID in
                                model.add(combo: combo, bundleID: bundleID)
                                if model.errorMessage == nil { closeEditors() }
                            },
                            onCancel: closeEditors
                        )
                    }
                }
                .padding(12)
            }
            .frame(maxHeight: 400)

            footer
        }
        .frame(width: 322)
        .background(AirTheme.bg)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(AirTheme.coralGradient))

            VStack(alignment: .leading, spacing: 0) {
                Text("Shortcuts")
                    .font(AirTheme.font(17, .bold))
                    .foregroundStyle(AirTheme.textPrimary)
                Text("Tap to jump • hover to edit")
                    .font(AirTheme.font(11))
                    .foregroundStyle(AirTheme.textSecondary)
            }
            Spacer()
            Menu {
                Button("Open Window") { openEditor() }
                Divider()
                Button("Quit BetterTab") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AirTheme.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(Circle().strokeBorder(AirTheme.border, lineWidth: 1))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().overlay(AirTheme.border)
            HStack {
                Button {
                    closeEditors()
                    model.errorMessage = nil
                    withAnimation(.easeOut(duration: 0.18)) { addingNew = true }
                } label: {
                    Label("Add a shortcut", systemImage: "plus")
                }
                .buttonStyle(AirPrimaryButton())

                Spacer()

                Button("Open window") { openEditor() }
                    .buttonStyle(AirTextButton(tint: AirTheme.textSecondary))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    private func startEditing(_ id: String) {
        model.errorMessage = nil
        addingNew = false
        withAnimation(.easeOut(duration: 0.16)) { editingID = id }
    }

    private func closeEditors() {
        model.errorMessage = nil
        withAnimation(.easeOut(duration: 0.16)) {
            editingID = nil
            addingNew = false
        }
    }

    private func openEditor() {
        NSApp.setActivationPolicy(.regular)
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}

/// A compact, tappable row: tap to jump; hover reveals edit & delete.
private struct CompactRow: View {
    let binding: AppBinding
    let onJump: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 11) {
            AppIcon(bundleID: binding.bundleID, size: 30)

            Text(AppCatalog.name(forBundleID: binding.bundleID))
                .font(AirTheme.font(14, .medium))
                .foregroundStyle(AirTheme.textPrimary)

            Spacer(minLength: 8)

            if hovering {
                iconButton("pencil", action: onEdit)
                iconButton("trash", action: onDelete)
            } else {
                ShortcutChips(combo: binding.combo)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(hovering ? AirTheme.bgSubtle : AirTheme.bg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AirTheme.border, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onJump)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }

    private func iconButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AirTheme.textPrimary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(AirTheme.bg))
                .overlay(Circle().strokeBorder(AirTheme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
