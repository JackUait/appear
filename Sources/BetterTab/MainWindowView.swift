import SwiftUI
import AppKit
import BetterTabCore

/// The standalone window: a native `Table` of bindings with a toolbar +/− and a
/// sheet for adding. While this window is open the app behaves as a regular
/// (Dock-present) app; it returns to a menu-bar agent when the window closes.
struct MainWindowView: View {
    @EnvironmentObject var model: BindingsModel
    @State private var selection = Set<BindingItem.ID>()
    @State private var showingAdd = false

    var body: some View {
        Table(model.items, selection: $selection) {
            TableColumn("Application") { item in
                HStack(spacing: 8) {
                    AppIcon(bundleID: item.binding.bundleID, size: 18)
                    Text(AppCatalog.name(forBundleID: item.binding.bundleID))
                }
            }
            TableColumn("Shortcut") { item in
                Text(item.binding.combo.description)
                    .font(.body.monospaced())
                    .foregroundStyle(.secondary)
            }
            .width(min: 110, ideal: 130)
        }
        .frame(minWidth: 440, minHeight: 300)
        .overlay {
            if model.bindings.isEmpty {
                ContentUnavailableView {
                    Label("No Shortcuts", systemImage: "keyboard")
                } description: {
                    Text("Add a shortcut to jump to an app with a keystroke.")
                } actions: {
                    Button("Add Shortcut") { showingAdd = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    model.errorMessage = nil
                    showingAdd = true
                } label: {
                    Label("Add Shortcut", systemImage: "plus")
                }
                .help("Add a shortcut")

                Button {
                    removeSelected()
                } label: {
                    Label("Remove Shortcut", systemImage: "minus")
                }
                .help("Remove the selected shortcut")
                .disabled(selection.isEmpty)
            }
        }
        .navigationTitle("BetterTab")
        .sheet(isPresented: $showingAdd) {
            AddSheet().environmentObject(model)
        }
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        // Revert to a menu-bar agent only when the window actually closes — not
        // merely on focus loss (which `onDisappear` would catch, hiding the
        // window as the app drops to .accessory).
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in
            DispatchQueue.main.async {
                let hasVisibleWindow = NSApp.windows.contains {
                    $0.isVisible && $0.styleMask.contains(.titled) && !($0 is NSPanel)
                }
                if !hasVisibleWindow { NSApp.setActivationPolicy(.accessory) }
            }
        }
    }

    private func removeSelected() {
        let toRemove = model.items.filter { selection.contains($0.id) }.map(\.binding)
        for binding in toRemove { model.remove(binding) }
        selection.removeAll()
    }
}
