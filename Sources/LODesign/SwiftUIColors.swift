#if canImport(SwiftUI)
import SwiftUI

// MARK: - SwiftUI Color Extensions

extension Color {
    /// Initialize from a hex string like "#a855f7"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }
}

extension LOColorToken {
    /// SwiftUI Color from this design token
    public var color: Color {
        Color(hex: hex)
    }
}

// MARK: - Semantic Colors

extension Color {
    public static let loPurple400 = LOColorToken.purple400.color
    public static let loPurple500 = LOColorToken.purple500.color
    public static let loPurple600 = LOColorToken.purple600.color
    public static let loPurple900 = LOColorToken.purple900.color
    public static let loBgDark = LOColorToken.bgDark.color
    public static let loBgSection = LOColorToken.bgSection.color
    public static let loBgCard = LOColorToken.bgCard.color
    public static let loTextPrimary = LOColorToken.textPrimary.color
    public static let loTextSecondary = LOColorToken.textSecondary.color
    public static let loTextMuted = LOColorToken.textMuted.color
    public static let loBorder = LOColorToken.border.color
    public static let loAccent = LOColorToken.accent.color
}

// MARK: - Gradient

extension LinearGradient {
    public static let loPurpleGradient = LinearGradient(
        colors: [LOColorToken.gradientStart.color, LOColorToken.gradientEnd.color],
        startPoint: .leading,
        endPoint: .trailing
    )
}
#endif
