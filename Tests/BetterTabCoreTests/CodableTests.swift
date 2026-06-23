import Foundation
import Testing
@testable import BetterTabCore

@Test func appBindingSurvivesJSONRoundTrip() throws {
    let original = AppBinding(
        combo: KeyCombo(key: .s, modifiers: [.control, .option, .command]),
        bundleID: "com.apple.Safari"
    )

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(AppBinding.self, from: data)

    #expect(decoded == original)
}

@Test func bindingArraySurvivesJSONRoundTrip() throws {
    let original = [
        AppBinding(combo: KeyCombo(key: .s, modifiers: [.control, .option]), bundleID: "com.apple.Safari"),
        AppBinding(combo: KeyCombo(key: .t, modifiers: [.command, .shift]), bundleID: "com.apple.Terminal"),
    ]

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode([AppBinding].self, from: data)

    #expect(decoded == original)
}
