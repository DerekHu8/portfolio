//
//  LockiApp.swift
//  Locki
//
//  Created by Derek Hu on 7/31/25.
//

import SwiftUI
import FirebaseCore

@main
struct LockiApp: App {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if firebaseManager.isAuthenticated {
                HomeView()
                    .environmentObject(themeManager)
            } else {
                AccountCreationView()
                    .environmentObject(themeManager)
            }
        }
    }
}
