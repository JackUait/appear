# appear — Skeleton + Shortcut→App Jump (Design)

**Date:** 2026-06-24
**Status:** Approved

## Summary

`appear` is a macOS menu-bar utility that lets a user bind a global keyboard
shortcut to an application; pressing the shortcut jumps to (activates) that app,
launching it first if it isn't already running.

This first increment delivers a **bare-bones, test-driven skeleton plus one small
real feature**: a fully unit-tested binding model, and thin live wiring that
registers one real global hotkey and activates the target app so the workflow is
demonstrable end-to-end.

## Goals

- A SwiftPM package that builds, runs as a menu-bar app, and has a headless test
  harness wired up.
- All decision logic lives in a pure-logic library target with no AppKit
  dependency, developed via TDD (red → green).
- One live-wired binding (e.g. `⌃⌥S → Safari`) proves the shortcut→app jump works
  when the app is run.

## Non-Goals (deferred)

- Settings UI / shortcut recorder.
- Persistence of bindings to disk.
- An installed-app picker.
- Multiple simultaneously live-wired bindings.
- Packaging into a distributable, signed `.app` bundle.

The architecture leaves clean seams for all of these.

## Technology Decisions

Validated against the local toolchain (Swift 6.1.2, Xcode 16.4, macOS 26.2) and
deep research:

- **App shell:** SwiftPM `executableTarget` running a SwiftUI `MenuBarExtra` with
  `NSApplication.shared.setActivationPolicy(.accessory)` — a menu-bar agent with no
  Dock icon. The entry-point source file must **not** be named `main.swift` (it
  would collide with `@main`).
- **Global hotkey:** Carbon `RegisterEventHotKey`. Chosen because it requires **no
  Accessibility / Input Monitoring permission**, works on an unsigned `swift run`
  binary with no entitlements, and consumes the keystroke. (`NSEvent` global
  monitors were rejected — they require Accessibility permission and cannot consume
  the event.) Implemented dependency-free as a ~40-line adapter.
- **Jump to app:** `NSRunningApplication.activate()` (the deprecated
  `.activateIgnoringOtherApps` option is dropped) to foreground a running app, and
  `NSWorkspace.openApplication(at:configuration:)` with `configuration.activates =
  true` to launch-and-foreground an app that isn't running. Apps are matched by
  **bundle identifier** (stable across moves/renames), not localized name. The basic
  activate/launch path needs no special permission.
- **Testing:** Swift Testing (`import Testing`, `@Test`, `#expect`/`#require`),
  bundled with the toolchain (no package dependency). `swift test` runs the suite
  headlessly. The pure-logic library target imports no AppKit, so the test build
  never pulls in UI frameworks.

## Architecture

A two-target SwiftPM package separating pure logic from OS side effects:

- **`AppearCore`** (library, no AppKit) — all testable logic and protocol seams.
- **`Appear`** (executable) — thin SwiftUI `MenuBarExtra` app plus the two real
  OS adapters. Not unit-tested; it is glue wiring the core to the OS.

### Core components (`AppearCore`, unit-tested)

- **`KeyCombo`** — value type: `keyCode: UInt32` + Carbon `modifiers: UInt32`, plus
  a human-readable description. Value semantics make it trivially testable.
- **`AppBinding`** — value type: a `KeyCombo` + target `bundleID: String`.
- **`BindingStore`** — holds bindings; `add` / `remove` / `binding(for: KeyCombo)`.
  Rejects a duplicate combo with a typed conflict error.
- **`HotKeyRegistering`** (protocol) — `register(combo:handler:)` / `unregisterAll()`.
  The OS seam for hotkeys.
- **`AppActivating`** (protocol) — `runningApp(bundleID:)`, `appURL(bundleID:)`,
  `launch(url:activates:)`. The OS seam for activation.
- **`HotKeyCoordinator`** — installs a binding by registering its combo with the
  registrar; when the handler fires, resolves the combo to its binding and
  activates the target. Holds the activation policy: already running → `activate()`
  (no launch); installed but not running → launch with `activates: true`; not
  installed → throw.

### Executable components (`Appear`, thin glue, not unit-tested)

- **`CarbonHotKeyRegistrar: HotKeyRegistering`** — wraps `RegisterEventHotKey` /
  `InstallEventHandler`.
- **`WorkspaceAppActivator: AppActivating`** — real `NSWorkspace` /
  `NSRunningApplication` calls.
- **`App.swift`** — `@main` SwiftUI `App` that sets `.accessory` activation policy
  and presents a `MenuBarExtra` showing the active binding and a **Quit** button.
  Wires one binding live (e.g. `⌃⌥S → Safari`) to prove the end-to-end jump.

## Data Flow

```
⌃⌥S pressed
  → Carbon RegisterEventHotKey
  → CarbonHotKeyRegistrar handler
  → HotKeyCoordinator resolves combo → AppBinding
  → WorkspaceAppActivator.activate(bundleID:)
  → Safari comes to front (or launches if not running)
```

## Error Handling

Typed errors surfaced from the core and propagated by the adapters:

- Duplicate combo on `BindingStore.add` → conflict error.
- Activation target not installed → not-installed error.
- Hotkey registration failure → registration error.

## Testing Plan (TDD, Swift Testing, headless)

In `AppearCoreTests`, written test-first (red → green):

- **`KeyCombo`** — equality / value semantics / human-readable description.
- **`BindingStore`** — add then resolve a combo to its bundle ID; remove; adding a
  duplicate combo throws the conflict error.
- **`HotKeyCoordinator`** (with a spy registrar that captures the handler and a fake
  activator that records calls):
  - Installing a binding registers the combo with the registrar.
  - Firing the captured handler calls `activate` with the correct bundle ID.
  - Already-running target → `activate`, no launch.
  - Installed but not running → launch with `activates: true`.
  - Not installed → throws not-installed error.

## Directory Layout

```
appear/
├── Package.swift                         # swift-tools-version:6.0, .macOS(.v14)
├── Sources/
│   ├── AppearCore/                    # pure logic, no AppKit
│   │   ├── KeyCombo.swift
│   │   ├── AppBinding.swift
│   │   ├── BindingStore.swift
│   │   ├── HotKeyRegistering.swift
│   │   ├── AppActivating.swift
│   │   └── HotKeyCoordinator.swift
│   └── Appear/                        # thin executable (App.swift, NOT main.swift)
│       ├── App.swift
│       ├── CarbonHotKeyRegistrar.swift
│       └── WorkspaceAppActivator.swift
└── Tests/
    └── AppearCoreTests/
        ├── KeyComboTests.swift
        ├── BindingStoreTests.swift
        └── HotKeyCoordinatorTests.swift
```

## Research Sources

- SwiftPM + SwiftUI menu-bar app: alwaysrightinstitute.com/tows,
  nilcoalescing.com (menu-bar utility), Apple `MenuBarExtra` docs.
- Global hotkeys: `RegisterEventHotKey` permission-free dispatch
  (quicopy.com), Carbon-vs-NSEvent (electrobun #334),
  sindresorhus/KeyboardShortcuts (reference, not used).
- App activation: Apple `NSRunningApplication` / `NSWorkspace` docs,
  `activate(options:)` deprecation of `.activateIgnoringOtherApps` in macOS 14,
  Apple Forums thread 793253.
- Testing: Apple Swift Testing docs, swiftlang/swift-testing, `swift test` guide.
