import Foundation

/// OS seam for finding, activating, and launching applications. Implemented in
/// the executable by an `NSWorkspace`-backed adapter; faked in tests.
public protocol AppActivating {
    /// Activates an already-running app. Returns `false` if it isn't running.
    func activateRunningApp(bundleID: String) -> Bool
    /// Resolves the on-disk URL of an installed app, or `nil` if not installed.
    func applicationURL(bundleID: String) -> URL?
    /// Launches the app at `url` and brings it to the front.
    func launchApplication(at url: URL) throws
}
