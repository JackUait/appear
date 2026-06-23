import AppKit
import BetterTabCore

/// Real `AppActivating` backed by `NSWorkspace` / `NSRunningApplication`.
struct WorkspaceAppActivator: AppActivating {
    func activateRunningApp(bundleID: String) -> Bool {
        guard let app = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleID).first else {
            return false
        }
        app.activate()
        return true
    }

    func applicationURL(bundleID: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    func launchApplication(at url: URL) throws {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
    }
}
