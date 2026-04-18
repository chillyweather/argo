import SwiftUI

struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = ThemeColors.light
}

extension EnvironmentValues {
    var theme: ThemeColors {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}