import SwiftUI
import AppKit
import BetterTabCore

/// A click-to-record shortcut field. While recording, a local event monitor
/// captures the next real keystroke (a supported key plus at least one
/// modifier) and reports it as a `KeyCombo` — no modifier checkboxes or key
/// menus. Events are swallowed while recording so they neither type nor beep.
struct ShortcutRecorder: View {
    @Binding var combo: KeyCombo?

    @State private var recording = false
    @State private var liveModifiers: ModifierKey = []
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
                if liveModifiers.isEmpty {
                    Text("Type a shortcut…")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(liveModifiers.symbols.map(String.init).enumerated()), id: \.offset) { _, glyph in
                        KeyCap(label: glyph, emphasized: true)
                    }
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(.tint, style: StrokeStyle(lineWidth: 1, dash: [3]))
                        .frame(width: 22, height: 22)
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
        liveModifiers = []
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            handle(event)
        }
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        recording = false
        liveModifiers = []
    }

    /// Returns nil to swallow the event (no beep, no typed character) whenever
    /// we are recording.
    private func handle(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .flagsChanged:
            liveModifiers = Self.modifiers(from: event.modifierFlags)
            return nil
        case .keyDown:
            if event.keyCode == 53 { stopRecording(); return nil } // Escape cancels
            let mods = Self.modifiers(from: event.modifierFlags)
            // Require at least one modifier — a bare key is no use as a global
            // launcher hotkey. Keep listening until the user holds one.
            guard !mods.isEmpty,
                  let captured = KeyCombo(virtualKeyCode: UInt32(event.keyCode), modifiers: mods)
            else { return nil }
            combo = captured
            stopRecording()
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
