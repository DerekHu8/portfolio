//
//  FirebaseService+Auth.swift
//  Locki
//
//  Authentication operations for Firebase
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

// MARK: - Authentication

extension FirebaseService {
    
    // MARK: - User Authentication
    
    func signUp(email: String, password: String, username: String, displayName: String) async throws -> User {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Create user profile
            let newUser = User(
                username: username,
                displayName: displayName,
                email: email
            )
            
            // Save user data to Firestore
            try await createUserInFirestore(user: newUser, userId: authResult.user.uid)
            
            // Send email verification
            try await authResult.user.sendEmailVerification()
            
            return newUser
            
        } catch {
            if let authError = error as? AuthErrorCode {
                throw mapAuthError(authError)
            }
            throw FirebaseService.FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Get user data from Firestore
            let user = try await getUser(userId: authResult.user.uid)
            
            // Update last active date
            try await updateUserLastActive()
            
            return user
            
        } catch {
            if let authError = error as? AuthErrorCode {
                throw mapAuthError(authError)
            }
            throw FirebaseService.FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw FirebaseService.FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            if let authError = error as? AuthErrorCode {
                throw mapAuthError(authError)
            }
            throw FirebaseService.FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    func updateEmail(newEmail: String, password: String) async throws {
        do {
            guard let currentUser = Auth.auth().currentUser else {
                throw FirebaseService.FirebaseError.userNotAuthenticated
            }
            
            // Re-authenticate user before sensitive operation
            let credential = EmailAuthProvider.credential(withEmail: currentUser.email ?? "", password: password)
            try await currentUser.reauthenticate(with: credential)
            
            // Update email
            try await currentUser.updateEmail(to: newEmail)
            
            // Send verification email
            try await currentUser.sendEmailVerification()
            
            // Update email in Firestore
            try await updateUserEmail(newEmail)
            
        } catch {
            if let authError = error as? AuthErrorCode {
                throw mapAuthError(authError)
            }
            throw FirebaseService.FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        do {
            guard let currentUser = Auth.auth().currentUser else {
                throw FirebaseService.FirebaseError.userNotAuthenticated
            }
            
            // Re-authenticate user before sensitive operation
            let credential = EmailAuthProvider.credential(withEmail: currentUser.email ?? "", password: currentPassword)
            try await currentUser.reauthenticate(with: credential)
            
            // Update password
            try await currentUser.updatePassword(to: newPassword)
            
        } catch {
            if let authError = error as? AuthErrorCode {
                throw mapAuthError(authError)
            }
            throw FirebaseService.FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    func sendEmailVerification() async throws {
        do {
            guard let currentUser = Auth.auth().currentUser else {
                throw FirebaseService.FirebaseError.userNotAuthenticated
            }
            
            try await currentUser.sendEmailVerification()
        } catch {
            throw FirebaseService.FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    func deleteAccount(password: String) async throws {
        do {
            guard let currentUser = Auth.auth().currentUser else {
                throw FirebaseService.FirebaseError.userNotAuthenticated
            }
            
            let userID = currentUser.uid
            
            // Re-authenticate user before sensitive operation
            let credential = EmailAuthProvider.credential(withEmail: currentUser.email ?? "", password: password)
            try await currentUser.reauthenticate(with: credential)
            
            // Delete user data from Firestore (you might want to keep some data for analytics)
            try await deleteUserData(userId: userID)
            
            // Delete Firebase Auth account
            try await currentUser.delete()
            
        } catch {
            if let authError = error as? AuthErrorCode {
                throw mapAuthError(authError)
            }
            throw FirebaseService.FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    // MARK: - Authentication State
    
    var isUserSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    var isEmailVerified: Bool {
        return Auth.auth().currentUser?.isEmailVerified ?? false
    }
    
    // MARK: - Username Management
    
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        do {
            let querySnapshot = try await db.collection("users")
                .whereField("username", isEqualTo: username)
                .limit(to: 1)
                .getDocuments()
            
            return querySnapshot.documents.isEmpty
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func updateUsername(_ newUsername: String) async throws {
        do {
            let userID = try getCurrentUserID()
            
            // Check if username is available
            let isAvailable = try await isUsernameAvailable(newUsername)
            guard isAvailable else {
                throw FirebaseService.FirebaseError.unknownError("Username is already taken")
            }
            
            // Update username in user document
            try await db.collection("users").document(userID).updateData([
                "username": newUsername
            ])
            
            // You might also want to update username in related documents (posts, comments, etc.)
            try await updateUsernameInRelatedDocuments(oldUsername: "", newUsername: newUsername, userID: userID)
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapAuthError(_ authError: AuthErrorCode) -> FirebaseService.FirebaseError {
        switch authError.code {
        case .invalidEmail:
            return .unknownError("Invalid email address")
        case .emailAlreadyInUse:
            return .unknownError("Email address is already in use")
        case .weakPassword:
            return .unknownError("Password is too weak")
        case .userNotFound:
            return .unknownError("No account found with this email")
        case .wrongPassword:
            return .unknownError("Incorrect password")
        case .userDisabled:
            return .unknownError("This account has been disabled")
        case .tooManyRequests:
            return .unknownError("Too many requests. Please try again later")
        case .networkError:
            return .networkError
        default:
            return .unknownError("Authentication error: \(authError.localizedDescription)")
        }
    }
    
    private func updateUserLastActive() async throws {
        let userID = try getCurrentUserID()
        try await db.collection("users").document(userID).updateData([
            "lastActiveDate": FieldValue.serverTimestamp(),
            "isActive": true
        ])
    }
    
    private func updateUserEmail(_ newEmail: String) async throws {
        let userID = try getCurrentUserID()
        try await db.collection("users").document(userID).updateData([
            "email": newEmail
        ])
    }
    
    private func deleteUserData(userId: String) async throws {
        // This is a simplified version. In a real app, you might want to:
        // 1. Keep some data for analytics
        // 2. Anonymize rather than delete
        // 3. Handle related data (posts, comments, likes, etc.)
        
        let batch = db.batch()
        
        // Delete user document
        let userRef = db.collection("users").document(userId)
        batch.deleteDocument(userRef)
        
        // Delete user stats
        let userStatsRef = db.collection("userStats").document(userId)
        batch.deleteDocument(userStatsRef)
        
        // Delete user settings
        let userSettingsRef = db.collection("userSettings").document(userId)
        batch.deleteDocument(userSettingsRef)
        
        try await batch.commit()
        
        // Note: You might want to handle user's posts, comments, likes, etc. separately
        // as these operations might be complex and could be done in background
    }
    
    private func updateUsernameInRelatedDocuments(oldUsername: String, newUsername: String, userID: String) async throws {
        // Update username in posts
        let postsQuery = try await db.collection("posts")
            .whereField("userId", isEqualTo: userID)
            .getDocuments()
        
        let batch = db.batch()
        
        for document in postsQuery.documents {
            batch.updateData(["username": newUsername], forDocument: document.reference)
        }
        
        // Update username in comments
        let commentsQuery = try await db.collection("postComments")
            .whereField("userId", isEqualTo: userID)
            .getDocuments()
        
        for document in commentsQuery.documents {
            batch.updateData(["username": newUsername], forDocument: document.reference)
        }
        
        // Update username in likes
        let likesQuery = try await db.collection("postLikes")
            .whereField("userId", isEqualTo: userID)
            .getDocuments()
        
        for document in likesQuery.documents {
            batch.updateData(["username": newUsername], forDocument: document.reference)
        }
        
        try await batch.commit()
    }
}

// MARK: - Authentication State Listener

extension FirebaseService {
    
    func addAuthStateListener(_ completion: @escaping (Bool, User?) -> Void) -> AuthStateDidChangeListenerHandle {
        return Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                // User is signed in
                Task {
                    do {
                        let userData = try await self.getUser(userId: user.uid)
                        DispatchQueue.main.async {
                            completion(true, userData)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(true, nil) // Signed in but couldn't get user data
                        }
                    }
                }
            } else {
                // User is signed out
                DispatchQueue.main.async {
                    completion(false, nil)
                }
            }
        }
    }
    
    @MainActor
    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }
    
    // MARK: - Google Sign-In
    
    @MainActor
    func signInWithGoogle() async throws -> User {
        // For now, show an alert that Google Sign-In requires additional setup
        throw FirebaseService.FirebaseError.unknownError("Google Sign-In requires additional SDK setup. Please use email/password or Apple Sign-In.")
    }
    
    // MARK: - Apple Sign-In
    
    @MainActor
    func signInWithApple() async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = generateNonce()
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate(nonce: request.nonce) { result in
                continuation.resume(with: result)
            }
            
            authorizationController.delegate = delegate
            authorizationController.presentationContextProvider = delegate
            authorizationController.performRequests()
        }
    }
    
    // MARK: - Helper Methods
    
    func generateUsernameFromEmail(_ email: String) -> String {
        let baseUsername = email.components(separatedBy: "@").first ?? "user"
        return baseUsername.lowercased().replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
    }
    
    func createUserInFirestore(user: User, userId: String) async throws -> User {
        var userWithId = user
        userWithId.id = userId
        
        let userRef = db.collection("users").document(userId)
        try userRef.setData(from: userWithId)
        
        // Create initial user stats
        let userStats = UserStats(userId: userId)
        
        let statsRef = db.collection("userStats").document(userId)
        try statsRef.setData(from: userStats)
        
        return userWithId
    }
    
    private func generateNonce() -> String {
        let nonce = UUID().uuidString
        let inputData = Data(nonce.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

// MARK: - Apple Sign-In Delegate

private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<User, Error>) -> Void
    private let nonce: String?
    
    init(nonce: String?, completion: @escaping (Result<User, Error>) -> Void) {
        self.nonce = nonce
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            do {
                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    guard let nonce = nonce else {
                        throw FirebaseService.FirebaseError.unknownError("Invalid nonce")
                    }
                    
                    guard let appleIDToken = appleIDCredential.identityToken else {
                        throw FirebaseService.FirebaseError.unknownError("Unable to fetch identity token")
                    }
                    
                    guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                        throw FirebaseService.FirebaseError.unknownError("Unable to serialize token string")
                    }
                    
                    let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                                   rawNonce: nonce,
                                                                   fullName: appleIDCredential.fullName)
                    
                    let authResult = try await Auth.auth().signIn(with: credential)
                    
                    // Check if user exists in Firestore
                    if let existingUser = try? await FirebaseService.shared.getUser(userId: authResult.user.uid) {
                        completion(.success(existingUser))
                    } else {
                        // Create new user from Apple account
                        let fullName = appleIDCredential.fullName
                        let displayName = [fullName?.givenName, fullName?.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                        
                        let email = appleIDCredential.email ?? ""
                        let username = FirebaseService.shared.generateUsernameFromEmail(email.isEmpty ? authResult.user.uid : email)
                        
                        let newUser = User(
                            username: username,
                            displayName: displayName,
                            profession: "",
                            bio: "",
                            email: email
                        )
                        
                        let createdUser = try await FirebaseService.shared.createUserInFirestore(user: newUser, userId: authResult.user.uid)
                        completion(.success(createdUser))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
    }
}