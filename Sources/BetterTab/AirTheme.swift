import SwiftUI

/// Airbnb-flavored design tokens: warm white surfaces, the coral "Rausch"
/// accent, soft shadows, and rounded ("Cereal"-like) type.
enum AirTheme {
    static let bg            = Color(hex: 0xFFFFFF)
    static let bgSubtle      = Color(hex: 0xF7F7F7)
    static let border        = Color(hex: 0xDDDDDD)
    static let textPrimary   = Color(hex: 0x222222)
    static let textSecondary = Color(hex: 0x717171)
    static let textFaint     = Color(hex: 0xA0A0A0)
    static let coral         = Color(hex: 0xFF385C)
    static let danger        = Color(hex: 0xC13515)

    static let coralGradient = LinearGradient(
        colors: [Color(hex: 0xFF385C), Color(hex: 0xE61E4D)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Buttons

/// Coral pill CTA.
struct AirPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AirTheme.font(14, .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Capsule().fill(AirTheme.coralGradient))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .shadow(color: AirTheme.coral.opacity(0.35),
                    radius: configuration.isPressed ? 2 : 7, y: 2)
    }
}

/// Outlined pill, dark text.
struct AirOutlineButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AirTheme.font(14, .semibold))
            .foregroundStyle(AirTheme.textPrimary)
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(Capsule().fill(AirTheme.bg))
            .overlay(Capsule().strokeBorder(AirTheme.textPrimary.opacity(0.85), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// Quiet text button (Cancel / Delete).
struct AirTextButton: ButtonStyle {
    var tint: Color = AirTheme.textPrimary
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AirTheme.font(14, .semibold))
            .foregroundStyle(tint)
            .underline()
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}
