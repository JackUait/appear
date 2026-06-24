import SwiftUI
import AppKit
import BetterTabCore

/// The menu-bar popover: a vibrant, modern macOS surface. Tap a row to jump,
/// hover to edit/delete, or add — editable inline without leaving the popover.
struct RootView: View {
    @EnvironmentObject var model: BindingsModel
    @Environment(\.openWindow) private var openWindow

    @State private var editingID: String?
    @State private var addingNew = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(model.items) { item in
                        if editingID == item.id {
                            InlineEditor(
                                apps: model.installedApps,
                                existing: item.binding,
                                error: model.errorMessage,
                                onSave: { combo, bundleID in
                                    model.update(item.binding, combo: combo, bundleID: bundleID)
                                    if model.errorMessage == nil { close() }
                                },
                                onCancel: close,
                                onDelete: { model.remove(item.binding); close() }
                            )
                            .padding(.vertical, 2)
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
                        InlineEditor(
                            apps: model.installedApps,
                            existing: nil,
                            error: model.errorMessage,
                            onSave: { combo, bundleID in
                                model.add(combo: combo, bundleID: bundleID)
                                if model.errorMessage == nil { close() }
                            },
                            onCancel: close
                        )
                        .padding(.vertical, 2)
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 400)

            Divider()
            footer
        }
        .frame(width: 320)
        .background(VisualEffectBackground().ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(.tint)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "command")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 0) {
                Text("BetterTab").font(.headline)
                Text("^[\(model.bindings.count) shortcut](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button("Open Window") { openEditor() }
                Divider()
                Button("Quit BetterTab") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var footer: some View {
        HStack {
            Button {
                close()
                model.errorMessage = nil
                withAnimation(.easeOut(duration: 0.18)) { addingNew = true }
            } label: {
                Label("Add Shortcut", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Spacer()

            Button("Open Window") { openEditor() }
                .buttonStyle(.link)
                .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private func startEditing(_ id: String) {
        model.errorMessage = nil
        addingNew = false
        withAnimation(.easeOut(duration: 0.16)) { editingID = id }
    }

    private func close() {
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
        HStack(spacing: 10) {
            AppIcon(bundleID: binding.bundleID, size: 26)

            Text(AppCatalog.name(forBundleID: binding.bundleID))
                .font(.system(size: 13))

            Spacer(minLength: 8)

            if hovering {
                iconButton("pencil", action: onEdit)
                iconButton("trash", action: onDelete)
            } else {
                ShortcutView(combo: binding.combo)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(hovering ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(perform: onJump)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }

    private func iconButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
