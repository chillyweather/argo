import SwiftUI

enum AppFont {
    static func font(family: String, size: CGFloat) -> Font {
        if family == "System" || family.isEmpty {
            return .system(size: size, design: .monospaced)
        }
        return .custom(family, size: size)
    }

    static let availableFamilies: [String] = {
        NSFontManager.shared.availableFontFamilies.sorted()
    }()
}