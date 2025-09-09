//
//  UserModel.swift
//  Locki
//
//  Created by Derek Hu on 7/31/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// DEPRECATED: UserManager is replaced by FirebaseManager
// This class is kept for backward compatibility with existing views

class UserManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // UserManager is deprecated - use FirebaseManager instead
    }
    
    func createAccount(username: String, email: String, password: String) async -> Bool {
        // Deprecated - use FirebaseManager.shared.signUp instead
        return false
    }
    
    func signOut() {
        // Deprecated - use FirebaseManager.shared.signOut instead
    }
}