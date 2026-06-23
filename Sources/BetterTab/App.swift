import SwiftUI
import AppKit

@main
struct BetterTabApp: App {
    @StateObject private var model = BindingsModel()

    init() {
        // Menu-bar agent: no Dock icon, no main window.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            RootView()
                .environmentObject(model)
        } label: {
            Image(systemName: "arrow.up.right.square")
        }
        .menuBarExtraStyle(.window)
    }
}
