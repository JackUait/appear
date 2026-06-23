import AppKit
import Carbon.HIToolbox
import BetterTabCore

/// Errors from the Carbon hotkey backend.
enum HotKeyRegistrarError: Error {
    case registrationFailed(status: OSStatus)
}

/// Real `HotKeyRegistering` backed by Carbon's `RegisterEventHotKey`.
/// Requires no Accessibility permission and works in an unsigned executable.
final class CarbonHotKeyRegistrar: HotKeyRegistering {
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var handlers: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1
    private var eventHandler: EventHandlerRef?

    init() {
        installDispatcher()
    }

    private func installDispatcher() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                let registrar = Unmanaged<CarbonHotKeyRegistrar>
                    .fromOpaque(userData!).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event, EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID), nil,
                    MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID
                )
                registrar.handlers[hotKeyID.id]?()
                return noErr
            },
            1, &spec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    func register(combo: KeyCombo, handler: @escaping () -> Void) throws {
        let id = nextID
        nextID += 1
        handlers[id] = handler

        let hotKeyID = EventHotKeyID(signature: OSType(0x42544142 /* "BTAB" */), id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            combo.key.rawValue,
            carbonMask(for: combo.modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr, let ref else {
            handlers[id] = nil
            throw HotKeyRegistrarError.registrationFailed(status: status)
        }
        hotKeyRefs.append(ref)
    }

    func unregisterAll() {
        for ref in hotKeyRefs { UnregisterEventHotKey(ref) }
        hotKeyRefs.removeAll()
        handlers.removeAll()
    }

    private func carbonMask(for modifiers: ModifierKey) -> UInt32 {
        var mask: UInt32 = 0
        if modifiers.contains(.command) { mask |= UInt32(cmdKey) }
        if modifiers.contains(.option)  { mask |= UInt32(optionKey) }
        if modifiers.contains(.control) { mask |= UInt32(controlKey) }
        if modifiers.contains(.shift)   { mask |= UInt32(shiftKey) }
        return mask
    }
}
