import Foundation

// MARK: - Color Tokens
// These tokens are the source of truth. CSS variables derive from them.
// SwiftUI Color extensions derive from them. One source. Every surface.

public enum LOColorToken: String, CaseIterable, Sendable {
    case purple400 = "#c084fc"
    case purple500 = "#a855f7"
    case purple600 = "#9333ea"
    case purple900 = "#581c87"
    case bgDark = "#0a0a0f"
    case bgSection = "#111118"
    case bgCard = "#1a1a24"
    case textPrimary = "#f5f5f7"
    case textSecondary = "#a1a1aa"
    case textMuted = "#828288"
    case border = "#27272a"

    public var hex: String { rawValue }

    public var cssVar: String {
        switch self {
        case .purple400: "--purple-400"
        case .purple500: "--purple-500"
        case .purple600: "--purple-600"
        case .purple900: "--purple-900"
        case .bgDark: "--bg-dark"
        case .bgSection: "--bg-section"
        case .bgCard: "--bg-card"
        case .textPrimary: "--text-primary"
        case .textSecondary: "--text-secondary"
        case .textMuted: "--text-muted"
        case .border: "--border"
        }
    }

    public static var accent: LOColorToken { .purple400 }
    public static var gradientStart: LOColorToken { .purple400 }
    public static var gradientEnd: LOColorToken { .purple600 }

    public static func cssRoot() -> String {
        let vars = LOColorToken.allCases.map { "    \($0.cssVar): \($0.hex);" }
        return ":root {\n\(vars.joined(separator: "\n"))\n}"
    }
}

// MARK: - Spacing

public enum LOSpacingToken: CGFloat, CaseIterable, Sendable {
    case xs = 4
    case sm = 8
    case md = 16
    case lg = 24
    case xl = 32
    case xxl = 48
    case section = 80
    case hero = 120
}

// MARK: - Radius

public enum LORadiusToken: CGFloat, Sendable {
    case small = 8
    case standard = 12
    case large = 16
    case pill = 9999
}

// MARK: - Typography

public enum LOFontToken: Sendable {
    case display(size: CGFloat, weight: LOFontWeight)
    case body(size: CGFloat, weight: LOFontWeight)
    case mono(size: CGFloat)

    public var familyName: String {
        switch self {
        case .display: "SF Pro Display"
        case .body: "SF Pro Text"
        case .mono: "SF Mono"
        }
    }

    public var webFallback: String {
        switch self {
        case .display: "'Inter', system-ui, sans-serif"
        case .body: "'Inter', system-ui, sans-serif"
        case .mono: "'Fira Code', monospace"
        }
    }
}

public enum LOFontWeight: String, Sendable {
    case regular = "400"
    case medium = "500"
    case semibold = "600"
    case bold = "700"
    case heavy = "800"
}
