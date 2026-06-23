import Foundation
import Testing
@testable import BetterTabCore

// MARK: - Test doubles

private final class SpyHotKeyRegistrar: HotKeyRegistering {
    private(set) var registeredCombos: [KeyCombo] = []
    private(set) var unregisterAllCallCount = 0
    private var handlers: [KeyCombo: () -> Void] = [:]

    func register(combo: KeyCombo, handler: @escaping () -> Void) throws {
        registeredCombos.append(combo)
        handlers[combo] = handler
    }

    func unregisterAll() {
        unregisterAllCallCount += 1
        registeredCombos.removeAll()
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

private let comboT = KeyCombo(key: .t, modifiers: [.control, .option])
private let terminal = AppBinding(combo: comboT, bundleID: "com.apple.Terminal")

@Test func reloadRegistersEveryBindingAndActivatesEachCombo() throws {
    let (sut, registrar, activator) = makeSUT()
    activator.runningBundleIDs = ["com.apple.Safari", "com.apple.Terminal"]

    try sut.reload([safari, terminal])

    #expect(Set(registrar.registeredCombos) == [comboS, comboT])

    registrar.fire(comboS)
    registrar.fire(comboT)
    #expect(activator.activatedBundleIDs == ["com.apple.Safari", "com.apple.Terminal"])
}

@Test func reloadClearsPreviousRegistrationsBeforeRegisteringNewSet() throws {
    let (sut, registrar, _) = makeSUT()
    try sut.install(safari)

    try sut.reload([terminal])

    #expect(registrar.unregisterAllCallCount == 1)
    #expect(registrar.registeredCombos == [comboT])
    // The old combo no longer resolves to anything.
    #expect(throws: Never.self) { registrar.fire(comboS) }
}
