import SwiftUI
import AppKit
import AppearCore

/// A click-to-record shortcut field. While recording, a local event monitor
/// captures the keys held down together and reports them as a `KeyCombo` — a
/// single key with modifiers (`⌃⌥F`) or a multi-key chord (`G+L+M+N+R`). The
/// chord is captured when the keys are released (or once five are held), so the
/// order they go down doesn't matter. Events are swallowed while recording so
/// they neither type nor beep.
struct ShortcutRecorder: View {
    @Binding var combo: KeyCombo?

    /// Called when recording starts (`true`) and stops (`false`), so the host
    /// can suspend its global hotkeys while capturing — otherwise an existing
    /// hotkey swallows the keystroke before it reaches us.
    var onRecordingChange: (Bool) -> Void = { _ in }

    /// The most keys a single chord may hold.
    private static let maxKeys = 5

    @State private var recording = false
    @State private var liveModifiers: ModifierKey = []
    @State private var heldKeys: [Key] = []
    @State private var peakKeys: [Key] = []
    @State private var peakModifiers: ModifierKey = []
    @State private var monitor: Any?

    var body: some View {
        Button(action: toggle) {
            content
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(recording ? AnyShapeStyle(Color.accentColor.opacity(0.14))
                                         : AnyShapeStyle(.quaternary))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(recording ? AnyShapeStyle(.tint) : AnyShapeStyle(.separator),
                                      lineWidth: recording ? 1.5 : 0.5)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.12), value: recording)
        .onDisappear(perform: stopRecording)
    }

    @ViewBuilder private var content: some View {
        if recording {
            HStack(spacing: 6) {
                if liveModifiers.isEmpty && heldKeys.isEmpty {
                    Text("Press keys…")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(liveModifiers.symbols.map(String.init).enumerated()), id: \.offset) { _, glyph in
                        KeyCap(label: glyph, emphasized: true)
                    }
                    ForEach(Array(heldKeys.enumerated()), id: \.offset) { _, key in
                        KeyCap(label: key.label, emphasized: true)
                    }
                    if heldKeys.count < Self.maxKeys {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(.tint, style: StrokeStyle(lineWidth: 1, dash: [3]))
                            .frame(width: 22, height: 22)
                    }
                }
                Spacer(minLength: 6)
                Text("esc")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        } else if let combo {
            HStack(spacing: 8) {
                ShortcutView(combo: combo, emphasized: true)
                Spacer(minLength: 6)
                Text("Click to change")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        } else {
            HStack(spacing: 7) {
                Image(systemName: "record.circle")
                    .foregroundStyle(.secondary)
                Text("Record Shortcut")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
    }

    private func toggle() {
        if recording { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        guard !recording else { return }
        liveModifiers = []
        heldKeys = []
        peakKeys = []
        peakModifiers = []
        recording = true
        onRecordingChange(true)
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { event in
            handle(event)
        }
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        liveModifiers = []
        heldKeys = []
        peakKeys = []
        peakModifiers = []
        if recording {
            recording = false
            onRecordingChange(false)
        }
    }

    /// Commits the largest set of keys seen this press, if it's a usable
    /// shortcut (has a modifier, or is a chord of two or more keys).
    private func finalizeChord() {
        defer { stopRecording() }
        guard !peakModifiers.isEmpty || peakKeys.count >= 2 else { return }
        combo = KeyCombo(keys: peakKeys, modifiers: peakModifiers)
    }

    /// Returns nil to swallow the event (no beep, no typed character) whenever
    /// we are recording.
    private func handle(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .flagsChanged:
            liveModifiers = Self.modifiers(from: event.modifierFlags)
            return nil

        case .keyUp:
            let key = Key(virtualKeyCode: UInt32(event.keyCode))
            heldKeys.removeAll { $0 == key }
            // Once every key is up, commit the chord that was assembled.
            if heldKeys.isEmpty { finalizeChord() }
            return nil

        case .keyDown:
            if event.keyCode == 53 { stopRecording(); return nil } // Escape cancels
            if event.isARepeat { return nil }
            let key = Key(virtualKeyCode: UInt32(event.keyCode))
            // Modifiers arrive via flagsChanged; ignore them as chord keys.
            guard !key.isModifierKey else { return nil }

            if !heldKeys.contains(key), heldKeys.count < Self.maxKeys {
                heldKeys.append(key)
            }
            if heldKeys.count >= peakKeys.count {
                peakKeys = heldKeys
                peakModifiers = Self.modifiers(from: event.modifierFlags)
            }
            // A full five-key chord can't grow further — commit immediately.
            if heldKeys.count >= Self.maxKeys { finalizeChord() }
            return nil

        default:
            return event
        }
    }

    private static func modifiers(from flags: NSEvent.ModifierFlags) -> ModifierKey {
        var mods = ModifierKey()
        if flags.contains(.control) { mods.insert(.control) }
        if flags.contains(.option) { mods.insert(.option) }
        if flags.contains(.shift) { mods.insert(.shift) }
        if flags.contains(.command) { mods.insert(.command) }
        return mods
    }
}
