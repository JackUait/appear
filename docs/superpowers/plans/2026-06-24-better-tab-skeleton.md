# better-tab Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A test-driven SwiftPM macOS menu-bar app where pressing one global hotkey (⌃⌥S) jumps to (activates/launches) Safari, built on a fully unit-tested binding core.

**Architecture:** Two SwiftPM targets — a pure-logic library `BetterTabCore` (no AppKit, fully unit-tested) holding the binding model and protocol seams, and a thin executable `BetterTab` (SwiftUI `MenuBarExtra` + Carbon/NSWorkspace adapters) that wires the core to the OS. All OS effects sit behind the `HotKeyRegistering` and `AppActivating` protocols so the core logic is testable headlessly.

**Tech Stack:** Swift 6.1 toolchain, SwiftPM, SwiftUI `MenuBarExtra`, Carbon `RegisterEventHotKey`, `NSWorkspace`/`NSRunningApplication`, Swift Testing (`import Testing`).

## Global Constraints

These apply to EVERY task:

- `Package.swift` uses `swift-tools-version:6.0`.
- Platform floor: `.macOS(.v14)`.
- Swift language mode `.v5` on all targets for this increment (Swift 6 strict-concurrency hardening is a deferred follow-up, out of scope).
- **No third-party dependencies.**
- The executable entry-point source file must **not** be named `main.swift` (it collides with `@main`). Use `App.swift`.
- `BetterTabCore` imports only `Foundation` — never `AppKit`/`SwiftUI`.
- Apps are matched/stored by **bundle identifier** (e.g. `com.apple.Safari`), never localized name.
- Run all tests with `swift test` (headless).

---

### Task 1: Package scaffold + KeyCombo model

Establishes the package, the core library target, the test target, and the pure value types describing a keyboard shortcut. Ends with a green `swift test`.

**Files:**
- Create: `Package.swift`
- Create: `Sources/BetterTabCore/ModifierKey.swift`
- Create: `Sources/BetterTabCore/Key.swift`
- Create: `Sources/BetterTabCore/KeyCombo.swift`
- Test: `Tests/BetterTabCoreTests/KeyComboTests.swift`

**Interfaces:**
- Consumes: nothing (first task).
- Produces:
  - `struct ModifierKey: OptionSet, Hashable, Sendable` with statics `.control`, `.option`, `.shift`, `.command` and `var symbols: String` (glyphs in canonical order ⌃⌥⇧⌘).
  - `enum Key: UInt32, Sendable, CaseIterable` (ANSI letter virtual key codes) with `var label: String` (uppercased letter).
  - `struct KeyCombo: Hashable, Sendable { let key: Key; let modifiers: ModifierKey; init(key:modifiers:); var description: String }`.

- [ ] **Step 1: Create `Package.swift`**

```swift
// swift-tools-version:6.0
import PackageDescription

let swift5 = SwiftSetting.swiftLanguageMode(.v5)

let package = Package(
    name: "BetterTab",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(
            name: "BetterTabCore",
            swiftSettings: [swift5]
        ),
        .executableTarget(
            name: "BetterTab",
            dependencies: ["BetterTabCore"],
            swiftSettings: [swift5]
        ),
        .testTarget(
            name: "BetterTabCoreTests",
            dependencies: ["BetterTabCore"],
            swiftSettings: [swift5]
        ),
    ]
)
```

- [ ] **Step 2: Write the failing test**

Create `Tests/BetterTabCoreTests/KeyComboTests.swift`:

```swift
import Testing
@testable import BetterTabCore

@Test func modifierSymbolsAreInCanonicalOrder() {
    let mods: ModifierKey = [.command, .control, .shift, .option]
    #expect(mods.symbols == "⌃⌥⇧⌘")
}

@Test func emptyModifiersHaveNoSymbols() {
    #expect(ModifierKey().symbols == "")
}

@Test func keyLabelIsUppercasedLetter() {
    #expect(Key.s.label == "S")
}

@Test func keyComboDescriptionCombinesModifiersAndKey() {
    let combo = KeyCombo(key: .s, modifiers: [.control, .option])
    #expect(combo.description == "⌃⌥S")
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `swift test`
Expected: build FAILS — `cannot find 'ModifierKey' in scope` / `cannot find 'Key' in scope` / `cannot find 'KeyCombo' in scope`.

- [ ] **Step 4: Implement `ModifierKey`**

Create `Sources/BetterTabCore/ModifierKey.swift`:

```swift
/// A set of keyboard modifier flags, independent of any OS framework.
public struct ModifierKey: OptionSet, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let control = ModifierKey(rawValue: 1 << 0)
    public static let option  = ModifierKey(rawValue: 1 << 1)
    public static let shift   = ModifierKey(rawValue: 1 << 2)
    public static let command = ModifierKey(rawValue: 1 << 3)

    /// Modifier glyphs in the conventional macOS display order: ⌃⌥⇧⌘.
    public var symbols: String {
        var result = ""
        if contains(.control) { result += "⌃" }
        if contains(.option)  { result += "⌥" }
        if contains(.shift)   { result += "⇧" }
        if contains(.command) { result += "⌘" }
        return result
    }
}
```

- [ ] **Step 5: Implement `Key`**

Create `Sources/BetterTabCore/Key.swift`:

```swift
/// A keyboard key identified by its macOS ANSI virtual key code.
/// Raw values are the `kVK_ANSI_*` codes used by Carbon's RegisterEventHotKey.
public enum Key: UInt32, Sendable, CaseIterable {
    case a = 0x00, b = 0x0B, c = 0x08, d = 0x02, e = 0x0E, f = 0x03
    case g = 0x05, h = 0x04, i = 0x22, j = 0x26, k = 0x28, l = 0x25
    case m = 0x2E, n = 0x2D, o = 0x1F, p = 0x23, q = 0x0C, r = 0x0F
    case s = 0x01, t = 0x11, u = 0x20, v = 0x09, w = 0x0D, x = 0x07
    case y = 0x10, z = 0x06

    /// The uppercased letter shown to users, e.g. `.s` -> "S".
    public var label: String { "\(self)".uppercased() }
}
```

- [ ] **Step 6: Implement `KeyCombo`**

Create `Sources/BetterTabCore/KeyCombo.swift`:

```swift
/// A keyboard shortcut: a key plus its modifier flags.
public struct KeyCombo: Hashable, Sendable {
    public let key: Key
    public let modifiers: ModifierKey

    public init(key: Key, modifiers: ModifierKey) {
        self.key = key
        self.modifiers = modifiers
    }

    /// Human-readable form, e.g. "⌃⌥S".
    public var description: String { "\(modifiers.symbols)\(key.label)" }
}
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `swift test`
Expected: PASS — 4 tests pass, build succeeds.

- [ ] **Step 8: Commit**

```bash
git add Package.swift Sources/BetterTabCore Tests/BetterTabCoreTests
git commit -m "feat: package scaffold + KeyCombo model"
```

---

### Task 2: AppBinding + BindingStore

Adds the value type tying a shortcut to a target app, and the store that holds bindings with duplicate-combo rejection.

**Files:**
- Create: `Sources/BetterTabCore/AppBinding.swift`
- Create: `Sources/BetterTabCore/BindingStore.swift`
- Test: `Tests/BetterTabCoreTests/BindingStoreTests.swift`

**Interfaces:**
- Consumes: `KeyCombo` (Task 1).
- Produces:
  - `struct AppBinding: Hashable, Sendable { let combo: KeyCombo; let bundleID: String; init(combo:bundleID:) }`.
  - `enum BindingStoreError: Error, Equatable { case duplicateCombo(KeyCombo) }`.
  - `final class BindingStore` with `init()`, `func add(_ binding: AppBinding) throws`, `func remove(combo: KeyCombo)`, `func binding(for combo: KeyCombo) -> AppBinding?`, `var all: [AppBinding]`.

- [ ] **Step 1: Write the failing test**

Create `Tests/BetterTabCoreTests/BindingStoreTests.swift`:

```swift
import Testing
@testable import BetterTabCore

private let comboS = KeyCombo(key: .s, modifiers: [.control, .option])
private let safari = AppBinding(combo: comboS, bundleID: "com.apple.Safari")

@Test func addThenResolveReturnsBinding() throws {
    let store = BindingStore()
    try store.add(safari)
    #expect(store.binding(for: comboS) == safari)
}

@Test func resolveUnknownComboReturnsNil() {
    let store = BindingStore()
    #expect(store.binding(for: comboS) == nil)
}

@Test func removeDeletesBinding() throws {
    let store = BindingStore()
    try store.add(safari)
    store.remove(combo: comboS)
    #expect(store.binding(for: comboS) == nil)
}

@Test func addingDuplicateComboThrowsConflict() throws {
    let store = BindingStore()
    try store.add(safari)
    let clash = AppBinding(combo: comboS, bundleID: "com.apple.Terminal")
    #expect(throws: BindingStoreError.duplicateCombo(comboS)) {
        try store.add(clash)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter BindingStoreTests`
Expected: build FAILS — `cannot find 'AppBinding' in scope` / `cannot find 'BindingStore' in scope`.

- [ ] **Step 3: Implement `AppBinding`**

Create `Sources/BetterTabCore/AppBinding.swift`:

```swift
/// Binds a keyboard shortcut to a target application (by bundle identifier).
public struct AppBinding: Hashable, Sendable {
    public let combo: KeyCombo
    public let bundleID: String

    public init(combo: KeyCombo, bundleID: String) {
        self.combo = combo
        self.bundleID = bundleID
    }
}
```

- [ ] **Step 4: Implement `BindingStore`**

Create `Sources/BetterTabCore/BindingStore.swift`:

```swift
/// Errors raised while mutating a `BindingStore`.
public enum BindingStoreError: Error, Equatable {
    /// A binding already exists for this combo.
    case duplicateCombo(KeyCombo)
}

/// In-memory collection of shortcut→app bindings, keyed by combo.
public final class BindingStore {
    private var bindings: [KeyCombo: AppBinding] = [:]

    public init() {}

    /// Adds a binding. Throws `.duplicateCombo` if the combo is already bound.
    public func add(_ binding: AppBinding) throws {
        guard bindings[binding.combo] == nil else {
            throw BindingStoreError.duplicateCombo(binding.combo)
        }
        bindings[binding.combo] = binding
    }

    public func remove(combo: KeyCombo) {
        bindings[combo] = nil
    }

    public func binding(for combo: KeyCombo) -> AppBinding? {
        bindings[combo]
    }

    public var all: [AppBinding] { Array(bindings.values) }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `swift test --filter BindingStoreTests`
Expected: PASS — 4 tests pass.

- [ ] **Step 6: Commit**

```bash
git add Sources/BetterTabCore/AppBinding.swift Sources/BetterTabCore/BindingStore.swift Tests/BetterTabCoreTests/BindingStoreTests.swift
git commit -m "feat: AppBinding + BindingStore with duplicate detection"
```

---

### Task 3: Protocol seams + HotKeyCoordinator

Adds the two OS-seam protocols and the coordinator that wires "combo fired → resolve binding → activate (or launch) target." This is the heart of the testable logic, verified with a spy registrar and a fake activator.

**Files:**
- Create: `Sources/BetterTabCore/HotKeyRegistering.swift`
- Create: `Sources/BetterTabCore/AppActivating.swift`
- Create: `Sources/BetterTabCore/HotKeyCoordinator.swift`
- Test: `Tests/BetterTabCoreTests/HotKeyCoordinatorTests.swift`

**Interfaces:**
- Consumes: `KeyCombo`, `AppBinding`, `BindingStore` (Tasks 1–2).
- Produces:
  - `protocol HotKeyRegistering: AnyObject { func register(combo: KeyCombo, handler: @escaping () -> Void) throws; func unregisterAll() }`.
  - `protocol AppActivating { func activateRunningApp(bundleID: String) -> Bool; func applicationURL(bundleID: String) -> URL?; func launchApplication(at url: URL) throws }`.
  - `enum ActivationError: Error, Equatable { case notInstalled(bundleID: String) }`.
  - `final class HotKeyCoordinator` with `init(store:registrar:activator:)`, `func install(_ binding: AppBinding) throws`, and internal `func handle(combo: KeyCombo) throws` (the resolve-and-activate logic).

- [ ] **Step 1: Write the failing test**

Create `Tests/BetterTabCoreTests/HotKeyCoordinatorTests.swift`:

```swift
import Foundation
import Testing
@testable import BetterTabCore

// MARK: - Test doubles

private final class SpyHotKeyRegistrar: HotKeyRegistering {
    private(set) var registeredCombos: [KeyCombo] = []
    private var handlers: [KeyCombo: () -> Void] = [:]

    func register(combo: KeyCombo, handler: @escaping () -> Void) throws {
        registeredCombos.append(combo)
        handlers[combo] = handler
    }

    func unregisterAll() {
        handlers.removeAll()
    }

    /// Simulates the OS delivering the hotkey press.
    func fire(_ combo: KeyCombo) { handlers[combo]?() }
}

private final class FakeAppActivator: AppActivating {
    var runningBundleIDs: Set<String> = []
    var installedURLs: [String: URL] = [:]
    var launchError: Error?

    private(set) var activatedBundleIDs: [String] = []
    private(set) var launchedURLs: [URL] = []

    func activateRunningApp(bundleID: String) -> Bool {
        guard runningBundleIDs.contains(bundleID) else { return false }
        activatedBundleIDs.append(bundleID)
        return true
    }

    func applicationURL(bundleID: String) -> URL? { installedURLs[bundleID] }

    func launchApplication(at url: URL) throws {
        if let launchError { throw launchError }
        launchedURLs.append(url)
    }
}

// MARK: - Fixtures

private let comboS = KeyCombo(key: .s, modifiers: [.control, .option])
private let safari = AppBinding(combo: comboS, bundleID: "com.apple.Safari")

private func makeSUT() -> (HotKeyCoordinator, SpyHotKeyRegistrar, FakeAppActivator) {
    let registrar = SpyHotKeyRegistrar()
    let activator = FakeAppActivator()
    let coordinator = HotKeyCoordinator(
        store: BindingStore(), registrar: registrar, activator: activator
    )
    return (coordinator, registrar, activator)
}

// MARK: - Tests

@Test func installRegistersTheCombo() throws {
    let (sut, registrar, _) = makeSUT()
    try sut.install(safari)
    #expect(registrar.registeredCombos == [comboS])
}

@Test func firingHotkeyActivatesRunningTargetWithoutLaunching() throws {
    let (sut, registrar, activator) = makeSUT()
    activator.runningBundleIDs = ["com.apple.Safari"]
    try sut.install(safari)

    registrar.fire(comboS)

    #expect(activator.activatedBundleIDs == ["com.apple.Safari"])
    #expect(activator.launchedURLs.isEmpty)
}

@Test func handlingInstalledButNotRunningTargetLaunchesIt() throws {
    let (sut, _, activator) = makeSUT()
    let url = URL(fileURLWithPath: "/Applications/Safari.app")
    activator.installedURLs = ["com.apple.Safari": url]
    try sut.install(safari)

    try sut.handle(combo: comboS)

    #expect(activator.activatedBundleIDs.isEmpty)
    #expect(activator.launchedURLs == [url])
}

@Test func handlingNotInstalledTargetThrows() throws {
    let (sut, _, _) = makeSUT()
    try sut.install(safari)

    #expect(throws: ActivationError.notInstalled(bundleID: "com.apple.Safari")) {
        try sut.handle(combo: comboS)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter HotKeyCoordinatorTests`
Expected: build FAILS — `cannot find type 'HotKeyRegistering'` / `'AppActivating'` / `'HotKeyCoordinator'` / `'ActivationError'` in scope.

- [ ] **Step 3: Implement `HotKeyRegistering`**

Create `Sources/BetterTabCore/HotKeyRegistering.swift`:

```swift
/// OS seam for registering global hotkeys. Implemented in the executable by a
/// Carbon-backed adapter; faked in tests.
public protocol HotKeyRegistering: AnyObject {
    /// Registers `combo` so that `handler` runs when it is pressed system-wide.
    func register(combo: KeyCombo, handler: @escaping () -> Void) throws
    /// Removes all previously registered hotkeys.
    func unregisterAll()
}
```

- [ ] **Step 4: Implement `AppActivating`**

Create `Sources/BetterTabCore/AppActivating.swift`:

```swift
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
```

- [ ] **Step 5: Implement `HotKeyCoordinator`**

Create `Sources/BetterTabCore/HotKeyCoordinator.swift`:

```swift
import Foundation

/// Errors raised while activating a binding's target app.
public enum ActivationError: Error, Equatable {
    /// The target app is neither running nor installed.
    case notInstalled(bundleID: String)
}

/// Installs bindings and reacts to hotkey presses by jumping to the target app.
public final class HotKeyCoordinator {
    private let store: BindingStore
    private let registrar: HotKeyRegistering
    private let activator: AppActivating

    public init(store: BindingStore, registrar: HotKeyRegistering, activator: AppActivating) {
        self.store = store
        self.registrar = registrar
        self.activator = activator
    }

    /// Stores the binding and registers its combo with the OS.
    public func install(_ binding: AppBinding) throws {
        try store.add(binding)
        try registrar.register(combo: binding.combo) { [weak self] in
            try? self?.handle(combo: binding.combo)
        }
    }

    /// Resolves `combo` to its binding and activates (or launches) the target.
    func handle(combo: KeyCombo) throws {
        guard let binding = store.binding(for: combo) else { return }
        if activator.activateRunningApp(bundleID: binding.bundleID) { return }
        guard let url = activator.applicationURL(bundleID: binding.bundleID) else {
            throw ActivationError.notInstalled(bundleID: binding.bundleID)
        }
        try activator.launchApplication(at: url)
    }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `swift test`
Expected: PASS — all tests across the three suites pass (12 total).

- [ ] **Step 7: Commit**

```bash
git add Sources/BetterTabCore/HotKeyRegistering.swift Sources/BetterTabCore/AppActivating.swift Sources/BetterTabCore/HotKeyCoordinator.swift Tests/BetterTabCoreTests/HotKeyCoordinatorTests.swift
git commit -m "feat: OS-seam protocols + HotKeyCoordinator with tested activation logic"
```

---

### Task 4: Executable app — Carbon + NSWorkspace adapters, MenuBarExtra wiring

Implements the thin glue: the real Carbon hotkey registrar, the real NSWorkspace activator, an app controller wiring the one live binding (⌃⌥S → Safari), and the SwiftUI `MenuBarExtra` entry point. This is integration glue (not unit-tested per the spec); the deliverable is a clean `swift build` plus a documented manual smoke check.

**Files:**
- Create: `Sources/BetterTab/CarbonHotKeyRegistrar.swift`
- Create: `Sources/BetterTab/WorkspaceAppActivator.swift`
- Create: `Sources/BetterTab/AppController.swift`
- Create: `Sources/BetterTab/App.swift`

**Interfaces:**
- Consumes: `HotKeyRegistering`, `AppActivating`, `BindingStore`, `HotKeyCoordinator`, `KeyCombo`, `AppBinding`, `Key`, `ModifierKey` (Tasks 1–3).
- Produces: the runnable `BetterTab` executable. No symbols consumed by later tasks.

- [ ] **Step 1: Implement the Carbon hotkey registrar**

Create `Sources/BetterTab/CarbonHotKeyRegistrar.swift`:

```swift
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
```

- [ ] **Step 2: Implement the NSWorkspace activator**

Create `Sources/BetterTab/WorkspaceAppActivator.swift`:

```swift
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
```

- [ ] **Step 3: Implement the app controller**

Create `Sources/BetterTab/AppController.swift`:

```swift
import Foundation
import BetterTabCore

/// Owns the core objects and installs the single live binding (⌃⌥S → Safari).
final class AppController {
    private let store = BindingStore()
    private let registrar = CarbonHotKeyRegistrar()
    private let activator = WorkspaceAppActivator()
    private lazy var coordinator = HotKeyCoordinator(
        store: store, registrar: registrar, activator: activator
    )

    private let binding = AppBinding(
        combo: KeyCombo(key: .s, modifiers: [.control, .option]),
        bundleID: "com.apple.Safari"
    )

    /// Text shown in the menu bar, e.g. "⌃⌥S → Safari".
    var statusText: String { "\(binding.combo.description) → Safari" }

    /// Registers the live hotkey. Call once at launch.
    func start() {
        try? coordinator.install(binding)
    }
}
```

- [ ] **Step 4: Implement the SwiftUI entry point**

Create `Sources/BetterTab/App.swift`:

```swift
import SwiftUI
import AppKit
import BetterTabCore

@main
struct BetterTabApp: App {
    private let controller = AppController()

    init() {
        // Menu-bar agent: no Dock icon, no main window.
        NSApplication.shared.setActivationPolicy(.accessory)
        controller.start()
    }

    var body: some Scene {
        MenuBarExtra("BetterTab", systemImage: "command") {
            Text(controller.statusText)
            Divider()
            Button("Quit BetterTab") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
```

- [ ] **Step 5: Build the executable**

Run: `swift build`
Expected: build SUCCEEDS with no errors (`Compiling BetterTabCore`, `Compiling BetterTab`, `Build complete!`).

- [ ] **Step 6: Run the full test suite (confirm nothing regressed)**

Run: `swift test`
Expected: PASS — all 12 core tests still pass (the executable target adds no tests).

- [ ] **Step 7: Manual smoke check**

Run: `swift run BetterTab`
Expected: a `command` (⌘) icon appears in the menu bar (no Dock icon). With at least one other app focused, press **⌃⌥S** — Safari comes to the front (launching if it wasn't running). Open the menu-bar icon to see "⌃⌥S → Safari" and a "Quit BetterTab" item. Stop with Ctrl-C in the terminal or the Quit menu item.

Note: this step is a manual verification of OS-level glue and is not automated; record the observed result.

- [ ] **Step 8: Commit**

```bash
git add Sources/BetterTab
git commit -m "feat: Carbon + NSWorkspace adapters and MenuBarExtra app wiring ⌃⌥S → Safari"
```

---

## Notes / Deferred (out of scope)

- Swift 6 strict-concurrency hardening (currently language mode `.v5`).
- Settings UI / shortcut recorder, on-disk persistence, installed-app picker, multiple live bindings.
- Packaging into a signed, distributable `.app` bundle (manual bundle assembly + ad-hoc codesign).
