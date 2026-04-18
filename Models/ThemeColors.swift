import SwiftUI

struct ThemeColors {
    let bg: Color
    let bgSecondary: Color
    let text: Color
    let textMuted: Color
    let border: Color
    let accent: Color
    let success: Color
    let error: Color

    static let light = ThemeColors(
        bg: Color(hex: "FAFAFA"),
        bgSecondary: Color(hex: "F2F2F2"),
        text: Color(hex: "111111"),
        textMuted: Color(hex: "71717A"),
        border: Color(hex: "E4E4E7"),
        accent: Color(hex: "52525B"),
        success: Color(hex: "22C55E"),
        error: Color(hex: "EF4444")
    )

    static let dark = ThemeColors(
        bg: Color(hex: "161616"),
        bgSecondary: Color(hex: "1F1F1F"),
        text: Color(hex: "F0F0F0"),
        textMuted: Color(hex: "71717A"),
        border: Color(hex: "303030"),
        accent: Color(hex: "A1A1AA"),
        success: Color(hex: "22C55E"),
        error: Color(hex: "EF4444")
    )

    static let nord = ThemeColors(
        bg: Color(hex: "2E3440"),
        bgSecondary: Color(hex: "3B4252"),
        text: Color(hex: "ECEFF4"),
        textMuted: Color(hex: "8896AA"),
        border: Color(hex: "4C566A"),
        accent: Color(hex: "81A1C1"),
        success: Color(hex: "A3BE8C"),
        error: Color(hex: "BF616A")
    )

    static func current(for theme: AppTheme, scheme: ColorScheme) -> ThemeColors {
        switch theme {
        case .light: .light
        case .dark: .dark
        case .nord: .nord
        case .system: scheme == .dark ? .dark : .light
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: Double, r: Double, g: Double, b: Double
        switch hex.count {
        case 6:
            (a, r, g, b) = (1, Double((int >> 16) & 0xFF) / 255, Double((int >> 8) & 0xFF) / 255, Double(int & 0xFF) / 255)
        case 8:
            (a, r, g, b) = (Double((int >> 24) & 0xFF) / 255, Double((int >> 16) & 0xFF) / 255, Double((int >> 8) & 0xFF) / 255, Double(int & 0xFF) / 255)
        default:
            (a, r, g, b) = (1, 0, 0, 0)
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}