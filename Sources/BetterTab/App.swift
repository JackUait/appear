import SwiftUI
import AppKit
import BetterTabCore

@main
struct BetterTabApp: App {
    private let controller = AppController()

    init() {
        // Menu-bar agent: no Dock icon, no main window.
        NSApplication.shared.setActivationPolicy(.accessory)
        controller.start()
    }

    var body: some Scene {
        MenuBarExtra("BetterTab", systemImage: "command") {
            Text(controller.statusText)
            Divider()
            Button("Quit BetterTab") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
