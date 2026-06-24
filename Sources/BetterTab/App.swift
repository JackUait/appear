import SwiftUI
import AppKit

@main
struct BetterTabApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("BetterTab", id: "main") {
            MainWindowView()
                .environmentObject(appDelegate.model)
        }
        .windowResizability(.contentSize)
        // Launch as a menu-bar agent; the window opens on demand from the popover.
        .defaultLaunchBehavior(.suppressed)
    }
}

/// Owns the shared model and the menu-bar status item. Using an AppKit-managed
/// status item (instead of `MenuBarExtra`) lets the popover stay open while the
/// user edits a shortcut — see `StatusItemController`.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = BindingsModel()
    private var statusController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start as a menu-bar agent (no Dock icon). The standalone window
        // promotes the app to a regular app while it's open.
        NSApp.setActivationPolicy(.accessory)
        statusController = StatusItemController(model: model)

        // After the user grants Accessibility (in System Settings), re-register
        // so any multi-key chord starts working without a relaunch.
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.reapplyHotkeysIfNeeded() }
        }
    }

    /// Keep the menu-bar agent alive when the popover or standalone window
    /// closes — there is no `MenuBarExtra` scene holding the app open anymore.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
