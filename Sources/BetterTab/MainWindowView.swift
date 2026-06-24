import SwiftUI
import AppKit
import BetterTabCore

/// The standalone window, Airbnb-style: a roomy white surface with rounded
/// shortcut cards and the same inline editor as the popover. The app is a
/// regular Dock app while open and reverts to a menu-bar agent on close.
struct MainWindowView: View {
    @EnvironmentObject var model: BindingsModel

    @State private var editingID: String?
    @State private var addingNew = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(AirTheme.border)

            ScrollView {
                VStack(spacing: 12) {
                    if addingNew {
                        BindingEditor(
                            apps: model.installedApps,
                            existing: nil,
                            error: model.errorMessage,
                            onSave: { combo, bundleID in
                                model.add(combo: combo, bundleID: bundleID)
                                if model.errorMessage == nil { close() }
                            },
                            onCancel: close
                        )
                    }

                    ForEach(model.items) { item in
                        if editingID == item.id {
                            BindingEditor(
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
                        } else {
                            BindingCard(
                                binding: item.binding,
                                onJump: { model.jump(to: item.binding) },
                                onEdit: { startEditing(item.id) },
                                onDelete: { model.remove(item.binding) }
                            )
                        }
                    }

                    if model.bindings.isEmpty && !addingNew {
                        empty
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(minWidth: 540, idealWidth: 560, minHeight: 440)
        .background(AirTheme.bg)
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in
            DispatchQueue.main.async {
                let hasVisibleWindow = NSApp.windows.contains {
                    $0.isVisible && $0.styleMask.contains(.titled) && !($0 is NSPanel)
                }
                if !hasVisibleWindow { NSApp.setActivationPolicy(.accessory) }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your shortcuts")
                    .font(AirTheme.font(24, .bold))
                    .foregroundStyle(AirTheme.textPrimary)
                Text("Press a key combination to jump straight to an app.")
                    .font(AirTheme.font(13))
                    .foregroundStyle(AirTheme.textSecondary)
            }
            Spacer()
            Button {
                close()
                model.errorMessage = nil
                withAnimation(.easeOut(duration: 0.18)) { addingNew = true }
            } label: {
                Label("Add a shortcut", systemImage: "plus")
            }
            .buttonStyle(AirPrimaryButton())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(AirTheme.coral)
            Text("No shortcuts yet")
                .font(AirTheme.font(16, .semibold))
                .foregroundStyle(AirTheme.textPrimary)
            Text("Add one to jump to an app with a keystroke.")
                .font(AirTheme.font(13))
                .foregroundStyle(AirTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
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
}

/// A roomy Airbnb card for one binding; lifts on hover, tap to jump.
private struct BindingCard: View {
    let binding: AppBinding
    let onJump: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 14) {
            AppIcon(bundleID: binding.bundleID, size: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(AppCatalog.name(forBundleID: binding.bundleID))
                    .font(AirTheme.font(16, .semibold))
                    .foregroundStyle(AirTheme.textPrimary)
                ShortcutChips(combo: binding.combo)
            }

            Spacer(minLength: 12)

            iconButton("pencil", action: onEdit)
            iconButton("trash", action: onDelete)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AirTheme.bg)
                .shadow(color: .black.opacity(hovering ? 0.12 : 0.06),
                        radius: hovering ? 16 : 8, y: hovering ? 6 : 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AirTheme.border, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onJump)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.14), value: hovering)
    }

    private func iconButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AirTheme.textPrimary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(AirTheme.bg))
                .overlay(Circle().strokeBorder(AirTheme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help(symbol == "pencil" ? "Edit" : "Delete")
    }
}
