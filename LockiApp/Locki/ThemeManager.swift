//
//  ThemeManager.swift
//  Locki
//
//  Theme management system for the app
//

import SwiftUI
import Combine

// MARK: - Theme Colors
struct ThemeColors {
    let primaryBackground: Color
    let secondaryBackground: Color
    let tertiaryBackground: Color
    let primaryText: Color
    let secondaryText: Color
    let accentBlue: Color
    let buttonBackground: Color
    let cardBackground: Color
    let borderColor: Color
    let shadowColor: Color
    let iconColor: Color
    let toggleColor: Color
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .dark {
        didSet {
            saveTheme()
        }
    }
    
    private init() {
        loadTheme()
    }
    
    var colors: ThemeColors {
        switch currentTheme {
        case .dark:
            return ThemeColors(
                primaryBackground: Color(red: 0.08, green: 0.14, blue: 0.21),
                secondaryBackground: Color(red: 0.15, green: 0.25, blue: 0.35),
                tertiaryBackground: Color(red: 0.12, green: 0.20, blue: 0.28),
                primaryText: .white,
                secondaryText: .gray,
                accentBlue: Color(red: 0.3, green: 0.6, blue: 1.0),
                buttonBackground: Color(red: 0.15, green: 0.25, blue: 0.35),
                cardBackground: Color(red: 0.12, green: 0.20, blue: 0.28),
                borderColor: Color.gray.opacity(0.3),
                shadowColor: Color.black.opacity(0.3),
                iconColor: .white,
                toggleColor: Color(red: 0.3, green: 0.6, blue: 1.0)
            )
        case .light:
            return ThemeColors(
                primaryBackground: Color.white,
                secondaryBackground: Color(red: 0.95, green: 0.95, blue: 0.97),
                tertiaryBackground: Color(red: 0.98, green: 0.98, blue: 0.99),
                primaryText: Color.black,
                secondaryText: Color(red: 0.3, green: 0.3, blue: 0.3),
                accentBlue: Color(red: 0.0, green: 0.48, blue: 1.0),
                buttonBackground: Color(red: 0.95, green: 0.95, blue: 0.97),
                cardBackground: Color(red: 0.98, green: 0.98, blue: 0.99),
                borderColor: Color.gray.opacity(0.5),
                shadowColor: Color.black.opacity(0.1),
                iconColor: Color.black,
                toggleColor: Color(red: 0.0, green: 0.48, blue: 1.0)
            )
        case .auto:
            // Default to dark for now
            return ThemeColors(
                primaryBackground: Color(red: 0.08, green: 0.14, blue: 0.21),
                secondaryBackground: Color(red: 0.15, green: 0.25, blue: 0.35),
                tertiaryBackground: Color(red: 0.12, green: 0.20, blue: 0.28),
                primaryText: .white,
                secondaryText: .gray,
                accentBlue: Color(red: 0.3, green: 0.6, blue: 1.0),
                buttonBackground: Color(red: 0.15, green: 0.25, blue: 0.35),
                cardBackground: Color(red: 0.12, green: 0.20, blue: 0.28),
                borderColor: Color.gray.opacity(0.3),
                shadowColor: Color.black.opacity(0.3),
                iconColor: .white,
                toggleColor: Color(red: 0.3, green: 0.6, blue: 1.0)
            )
        }
    }
    
    func toggleTheme() {
        switch currentTheme {
        case .dark:
            currentTheme = .light
        case .light:
            currentTheme = .dark
        case .auto:
            currentTheme = .dark
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme")
    }
    
    private func loadTheme() {
        if let savedTheme = UserDefaults.standard.string(forKey: "app_theme"),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        }
    }
}

// MARK: - Environment Key for Theme
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions for Easy Theme Access
extension View {
    func themed() -> some View {
        self.environmentObject(ThemeManager.shared)
    }
}