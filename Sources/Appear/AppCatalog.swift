import AppKit
import AppearCore

/// A user-installed application the user can bind a shortcut to.
struct InstalledApp: Identifiable, Hashable {
    var id: String { bundleID }
    let name: String
    let bundleID: String
    let url: URL
}

/// Discovers installed apps (for the picker) and resolves names/icons for a
/// bundle identifier (for displaying bindings). Thin wrapper over `NSWorkspace`
/// and the standard application directories.
enum AppCatalog {
    private static let searchDirs: [URL] = [
        URL(fileURLWithPath: "/Applications"),
        URL(fileURLWithPath: "/Applications/Utilities"),
        URL(fileURLWithPath: "/System/Applications"),
        URL(fileURLWithPath: "/System/Applications/Utilities"),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
    ]

    static func installedApps() -> [InstalledApp] {
        var seen = Set<String>()
        var apps: [InstalledApp] = []
        for dir in searchDirs {
            let urls = (try? FileManager.default.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil
            )) ?? []
            for url in urls where url.pathExtension == "app" {
                guard let bundle = Bundle(url: url),
                      let id = bundle.bundleIdentifier,
                      !seen.contains(id) else { continue }
                seen.insert(id)
                apps.append(InstalledApp(name: displayName(url), bundleID: id, url: url))
            }
        }
        return apps.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    static func name(forBundleID id: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else {
            return id
        }
        return displayName(url)
    }

    static func icon(forBundleID id: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    private static func displayName(_ url: URL) -> String {
        FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")
    }
}
