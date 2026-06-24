import AppKit
import SwiftUI
import AppearCore

/// Owns the menu-bar status item and the popover that hosts `RootView`.
///
/// Replaces `MenuBarExtra(.window)`, whose popover auto-dismisses on focus loss
/// with no override. Here the popover behaves like a normal menu — a click in
/// another app closes it — except while an inline editor is open
/// (`model.isEditing`), so an in-progress edit and its key/app pickers survive
/// switching apps.
@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let model: BindingsModel
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var outsideClickMonitor: Any?

    init(model: BindingsModel) {
        self.model = model
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "command", accessibilityDescription: "Appear")
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(togglePopover)
        }

        // We drive dismissal ourselves (see startOutsideClickMonitor); a
        // transient popover from a background accessory app does not reliably
        // auto-close on outside clicks.
        popover.behavior = .applicationDefined
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: RootView(closePopover: { [weak self] in self?.closePopover() })
                .environmentObject(model)
        )
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // Take key so SwiftUI controls (toggles, menus) inside the popover
        // receive events immediately, without a throwaway first click.
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
        startOutsideClickMonitor()
    }

    func closePopover() {
        stopOutsideClickMonitor()
        popover.close()
    }

    /// Close the popover when the user clicks in another app — unless an inline
    /// editor is open, in which case the in-progress edit must survive. A global
    /// monitor only sees events destined for other apps, so clicks inside the
    /// popover (and its SwiftUI menus) never reach here.
    private func startOutsideClickMonitor() {
        guard outsideClickMonitor == nil else { return }
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            guard let self, !self.model.isEditing else { return }
            self.closePopover()
        }
    }

    private func stopOutsideClickMonitor() {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }

    /// Backstop veto for any close path other than our monitor.
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        !model.isEditing
    }
}
