import SwiftUI

/// "Night Console" palette — near-black surfaces with a warm amber legend accent,
/// echoing backlit mechanical keycaps.
enum Theme {
    static let bg          = Color(hex: 0x0E0F13)
    static let bgRaised    = Color(hex: 0x14161C)
    static let surface     = Color(hex: 0x1B1F27)
    static let surfaceHi   = Color(hex: 0x232834)

    static let stroke       = Color.white.opacity(0.06)
    static let strokeStrong = Color.white.opacity(0.14)

    static let textPrimary   = Color(hex: 0xECEEF3)
    static let textSecondary = Color(hex: 0x9AA0AC)
    static let textFaint     = Color(hex: 0x5B616C)

    static let accent     = Color(hex: 0xF2B705)   // amber legend
    static let accentSoft = Color(hex: 0xF2B705).opacity(0.16)
    static let danger     = Color(hex: 0xFF6B6B)

    static let display = Font.system(.body, design: .monospaced)
    static let mono    = Font.system(.callout, design: .monospaced)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
