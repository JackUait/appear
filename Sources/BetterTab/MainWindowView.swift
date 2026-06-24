import SwiftUI
import AppKit
import BetterTabCore

/// The standalone window: a NavigationStack with a unified toolbar, search, an
/// inset list of shortcuts, and a Form sheet for add/edit. The app is a regular
/// Dock app while open and reverts to a menu-bar agent on close.
struct MainWindowView: View {
    @EnvironmentObject var model: BindingsModel
    @State private var search = ""
    @State private var selection: BindingItem.ID?
    @State private var route: SheetRoute?

    private enum SheetRoute: Identifiable {
        case add
        case edit(AppBinding)
        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let binding): return binding.combo.description
            }
        }
    }

    private var filtered: [BindingItem] {
        guard !search.isEmpty else { return model.items }
        return model.items.filter {
            AppCatalog.name(forBundleID: $0.binding.bundleID).localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if model.bindings.isEmpty {
                    ContentUnavailableView {
                        Label("No Shortcuts", systemImage: "command.square")
                    } description: {
                        Text("Add a shortcut to jump to an app with a keystroke.")
                    } actions: {
                        Button("Add Shortcut") { route = .add }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(selection: $selection) {
                        ForEach(filtered) { item in
                            row(item)
                                .tag(item.id)
                                .contextMenu {
                                    Button("Edit") { route = .edit(item.binding) }
                                    Button("Jump to App") { model.jump(to: item.binding) }
                                    Divider()
                                    Button("Delete", role: .destructive) { model.remove(item.binding) }
                                }
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle("BetterTab")
            .searchable(text: $search, placement: .toolbar, prompt: "Search apps")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { route = .add } label: {
                        Label("Add Shortcut", systemImage: "plus")
                    }
                }
            }
        }
        .frame(minWidth: 480, idealWidth: 520, minHeight: 360)
        .sheet(item: $route) { route in
            switch route {
            case .add:
                EditorSheet(existing: nil).environmentObject(model)
            case .edit(let binding):
                EditorSheet(existing: binding).environmentObject(model)
            }
        }
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

    private func row(_ item: BindingItem) -> some View {
        HStack(spacing: 10) {
            AppIcon(bundleID: item.binding.bundleID, size: 28)
            Text(AppCatalog.name(forBundleID: item.binding.bundleID))
                .font(.body)
            Spacer(minLength: 12)
            ShortcutView(combo: item.binding.combo)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { route = .edit(item.binding) }
    }
}
