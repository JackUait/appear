import SwiftUI
import AppKit
import BetterTabCore

/// The menu-bar popover, built from native components. Doubles as a launcher:
/// clicking a row jumps to that app (which dismisses the popover). "Edit
/// Shortcuts…" opens the standalone window.
struct RootView: View {
    @EnvironmentObject var model: BindingsModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if model.bindings.isEmpty {
                empty
            } else {
                list
            }

            Divider()
            footer
        }
        .frame(width: 300)
        .background(VisualEffectBackground().ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "command.square.fill")
                .font(.system(size: 22))
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text("BetterTab").font(.headline)
                Text("^[\(model.bindings.count) shortcut](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button("Edit Shortcuts…") { openEditor() }
                Divider()
                Button("Quit BetterTab") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var list: some View {
        List {
            ForEach(model.items) { item in
                Button {
                    model.jump(to: item.binding)
                } label: {
                    HStack(spacing: 9) {
                        AppIcon(bundleID: item.binding.bundleID, size: 18)
                        Text(AppCatalog.name(forBundleID: item.binding.bundleID))
                        Spacer(minLength: 8)
                        Text(item.binding.combo.description)
                            .font(.body.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .accessibilityLabel("Jump to \(AppCatalog.name(forBundleID: item.binding.bundleID))")
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .frame(height: min(CGFloat(model.bindings.count) * 32 + 12, 320))
    }

    private var empty: some View {
        VStack(spacing: 6) {
            Image(systemName: "keyboard")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No shortcuts yet")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var footer: some View {
        HStack {
            Button {
                openEditor()
            } label: {
                Label("Edit Shortcuts…", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Edit Shortcuts")
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func openEditor() {
        NSApp.setActivationPolicy(.regular)
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
