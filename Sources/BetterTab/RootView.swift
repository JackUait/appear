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
                VStack(spacing: 3) {
                    if model.bindings.isEmpty && !addingNew {
                        empty
                    }

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
                            .transition(.opacity)
                        } else {
                            CompactRow(
                                binding: item.binding,
                                onJump: { model.jump(to: item.binding) },
                                onEdit: { startEditing(item.id) },
                                onDelete: { withAnimation(.snappy) { model.remove(item.binding) } }
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
                        .transition(.opacity)
                    }
                }
                .padding(8)
                .animation(.snappy(duration: 0.22), value: model.items)
            }
            .frame(maxHeight: 420)

            Divider()
            footer
        }
        .frame(width: 340)
        .background(VisualEffectBackground().ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.78)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: "command")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .shadow(color: Color.accentColor.opacity(0.35), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 1) {
                Text("BetterTab").font(.headline)
                Text("Jump to your apps")
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
        .padding(.vertical, 12)
    }

    private var empty: some View {
        VStack(spacing: 7) {
            Image(systemName: "command")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No shortcuts yet")
                .font(.callout.weight(.medium))
            Text("Add one to jump to an app with a keystroke.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 20)
    }

    private var footer: some View {
        HStack {
            Button {
                close()
                model.errorMessage = nil
                withAnimation(.snappy) { addingNew = true }
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
        withAnimation(.snappy) { editingID = id }
    }

    private func close() {
        model.errorMessage = nil
        withAnimation(.snappy) {
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

/// A compact, tappable row: tap to jump; hover crossfades the shortcut into
/// edit & delete controls.
private struct CompactRow: View {
    let binding: AppBinding
    let onJump: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 11) {
            AppIcon(bundleID: binding.bundleID, size: 28)

            Text(AppCatalog.name(forBundleID: binding.bundleID))
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)

            Spacer(minLength: 8)

            ZStack(alignment: .trailing) {
                ShortcutView(combo: binding.combo)
                    .opacity(hovering ? 0 : 1)
                HStack(spacing: 4) {
                    iconButton("pencil", help: "Edit", action: onEdit)
                    iconButton("trash", help: "Delete", action: onDelete)
                }
                .opacity(hovering ? 1 : 0)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(hovering ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onJump)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.13), value: hovering)
        .help("Jump to \(AppCatalog.name(forBundleID: binding.bundleID))")
    }

    private func iconButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(Circle().fill(.background.opacity(0.5)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
