import SwiftUI
import AppKit

@main
struct BetterTabApp: App {
    @StateObject private var model = BindingsModel()

    init() {
        // Start as a menu-bar agent (no Dock icon). The standalone window
        // promotes the app to a regular app while it's open.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            RootView()
                .environmentObject(model)
        } label: {
            Image(systemName: "command")
        }
        .menuBarExtraStyle(.window)

        Window("BetterTab", id: "main") {
            MainWindowView()
                .environmentObject(model)
        }
        .windowResizability(.contentSize)
        // .defaultLaunchBehavior(.suppressed)   // don't open at launch; opened on demand
    }
}
