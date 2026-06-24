import AppKit
import CoreGraphics
import ApplicationServices
import BetterTabCore

/// Detects multi-key chords (e.g. `G+L+M+N+R` held together) that Carbon's
/// single-key `RegisterEventHotKey` can't express.
///
/// A `CGEventTap` at the session level watches every key down/up so we can tell
/// which keys are held simultaneously and fire when the held set exactly
/// matches a registered chord. The tap needs Accessibility permission — that's
/// inherent to observing keys destined for other apps — so `register` throws
/// `accessibilityNotGranted` until the user grants it.
final class ChordEventTapMonitor: HotKeyRegistering {
    private struct Chord {
        let combo: KeyCombo
        let handler: () -> Void
    }

    private var chords: [Chord] = []

    /// Regular (non-modifier) keys currently held down.
    private var pressed: Set<UInt32> = []
    /// The held set that last fired, so a sustained hold doesn't re-fire.
    private var latched: Set<UInt32>?

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func register(combo: KeyCombo, handler: @escaping () -> Void) throws {
        try ensureTap()
        chords.append(Chord(combo: combo, handler: handler))
    }

    func unregisterAll() {
        chords.removeAll()
        pressed.removeAll()
        latched = nil
        teardownTap()
    }

    /// Whether the process currently holds Accessibility permission.
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Shows the system prompt directing the user to grant Accessibility.
    static func promptForAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    // MARK: - Tap lifecycle

    private func ensureTap() throws {
        guard tap == nil else { return }
        guard Self.isTrusted else { throw HotKeyRegistrarError.accessibilityNotGranted }

        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<ChordEventTapMonitor>.fromOpaque(userInfo).takeUnretainedValue()
                return monitor.handle(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw HotKeyRegistrarError.accessibilityNotGranted
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        self.runLoopSource = source
    }

    private func teardownTap() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes) }
        tap = nil
        runLoopSource = nil
    }

    // MARK: - Event handling (runs on the main run loop)

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let passthrough = Unmanaged.passUnretained(event)

        // The system disables the tap if a callback is ever slow; re-enable it.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return passthrough
        }

        let keyCode = UInt32(event.getIntegerValueField(.keyboardEventKeycode))

        switch type {
        case .keyUp:
            pressed.remove(keyCode)
            if let latched, latched != pressed { self.latched = nil }
            return passthrough

        case .keyDown:
            // Ignore auto-repeat so a held chord fires once.
            if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 { return passthrough }
            pressed.insert(keyCode)
            let modifiers = Self.modifiers(from: event.flags)
            guard latched != pressed,
                  let chord = chords.first(where: { $0.combo.matches(pressedKeyCodes: pressed, modifiers: modifiers) })
            else { return passthrough }

            latched = pressed
            let handler = chord.handler
            DispatchQueue.main.async(execute: handler)
            // Swallow the key that completes the chord so it doesn't also type.
            return nil

        default:
            return passthrough
        }
    }

    private static func modifiers(from flags: CGEventFlags) -> ModifierKey {
        var mods = ModifierKey()
        if flags.contains(.maskControl) { mods.insert(.control) }
        if flags.contains(.maskAlternate) { mods.insert(.option) }
        if flags.contains(.maskShift) { mods.insert(.shift) }
        if flags.contains(.maskCommand) { mods.insert(.command) }
        return mods
    }
}
