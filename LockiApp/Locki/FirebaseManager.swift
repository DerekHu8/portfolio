//
//  FirebaseManager.swift
//  Locki
//
//  Main manager class to coordinate Firebase operations with UI
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import SwiftUI

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var userStats: UserStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Feed and Posts
    @Published var feedPosts: [Post] = []
    @Published var userPosts: [Post] = []
    
    // Social
    @Published var notifications: [AppNotification] = []
    @Published var unreadNotificationCount = 0
    @Published var conversations: [Conversation] = []
    @Published var leaderboardUsers: [LeaderboardUser] = []
    
    // Search
    @Published var searchResults: [SearchResult] = []
    @Published var searchHistory: [SearchHistory] = []
    
    // Real-time listeners
    private var notificationListener: ListenerRegistration?
    private var conversationListener: ListenerRegistration?
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        Task { @MainActor in
            removeListeners()
        }
    }
    
    // MARK: - Authentication State Management
    
    private func setupAuthStateListener() {
        authStateListener = self.firebaseService.addAuthStateListener { [weak self] isSignedIn, user in
            Task { @MainActor in
                self?.isAuthenticated = isSignedIn
                self?.currentUser = user
                
                if isSignedIn {
                    if let user = user {
                        // User data is available
                        await self?.loadUserData()
                        self?.setupRealTimeListeners()
                    } else {
                        // User is signed in but data not yet available, retry
                        await self?.retryLoadUserData()
                    }
                } else {
                    self?.clearUserData()
                    Task { @MainActor in
                        self?.removeListeners()
                    }
                }
            }
        }
    }
    
    private func retryLoadUserData() async {
        // Wait a moment and try to get user data again
        for attempt in 1...3 {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            do {
                if let userId = Auth.auth().currentUser?.uid {
                    let userData = try await self.firebaseService.getUser(userId: userId)
                    await MainActor.run {
                        self.currentUser = userData
                    }
                    await loadUserData()
                    setupRealTimeListeners()
                    return
                }
            } catch {
                print("Retry attempt \(attempt) failed: \(error)")
                if attempt == 3 {
                    print("Failed to load user data after 3 attempts")
                }
            }
        }
    }
    
    private func loadUserData() async {
        do {
            // Load user stats
            if let userId = currentUser?.id {
                userStats = try await self.firebaseService.getUserStats(userId: userId)
            }
            
            // Load initial data
            await loadFeedPosts()
            await loadNotifications()
            await loadConversations()
            
        } catch {
            handleError(error)
        }
    }
    
    private func clearUserData() {
        currentUser = nil
        userStats = nil
        feedPosts = []
        userPosts = []
        notifications = []
        conversations = []
        leaderboardUsers = []
        searchResults = []
        searchHistory = []
        unreadNotificationCount = 0
    }
    
    private func setupRealTimeListeners() {
        guard let currentUserId = currentUser?.id else { return }
        
        // Listen to notifications
        notificationListener = self.firebaseService.listenToNotifications { [weak self] notifications in
            Task { @MainActor in
                self?.notifications = notifications
                self?.unreadNotificationCount = notifications.filter { !$0.isRead }.count
            }
        }
        
        // Listen to conversations
        conversationListener = self.firebaseService.listenToConversations { [weak self] conversations in
            Task { @MainActor in
                self?.conversations = conversations
            }
        }
    }
    
    @MainActor
    private func removeListeners() {
        notificationListener?.remove()
        conversationListener?.remove()
        
        if let authStateListener = authStateListener {
            self.firebaseService.removeAuthStateListener(authStateListener)
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        print("Firebase Error: \(error.localizedDescription)")
        errorMessage = error.localizedDescription
    }
    
    private func withLoading<T>(_ operation: @escaping () async throws -> T) async -> T? {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await operation()
            isLoading = false
            return result
        } catch {
            isLoading = false
            handleError(error)
            return nil
        }
    }
}

// MARK: - Authentication Methods

extension FirebaseManager {
    
    func signUp(email: String, password: String, username: String, displayName: String) async -> Bool {
        guard let newUser = await withLoading({
            try await self.firebaseService.signUp(email: email, password: password, username: username, displayName: displayName)
        }) else {
            return false
        }
        
        // Explicitly update authentication state after successful sign-up
        await MainActor.run {
            self.isAuthenticated = true
            self.currentUser = newUser
        }
        
        // Load user data and setup listeners
        await loadUserData()
        setupRealTimeListeners()
        
        return true
    }
    
    func signIn(email: String, password: String) async -> Bool {
        guard let loginUser = await withLoading({
            try await self.firebaseService.signIn(email: email, password: password)
        }) else {
            return false
        }
        
        // Explicitly update authentication state after successful sign-up
        await MainActor.run {
            self.isAuthenticated = true
            self.currentUser = loginUser
        }
        
        // Load user data and setup listeners
        await loadUserData()
        setupRealTimeListeners()
        
        return true
    }
    
    func signOut() {
        do {
            try self.firebaseService.signOut()
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    func signInWithGoogle() async -> Bool {
        do {
            let user = try await self.firebaseService.signInWithGoogle()
            
            // Explicitly update authentication state after successful sign-in
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUser = user
            }
            
            // Load user data and setup listeners
            await loadUserData()
            setupRealTimeListeners()
            
            return true
        } catch {
            // Show error message for Google Sign-In setup requirement
            handleError(error)
            return false
        }
    }
    
    @MainActor
    func signInWithApple() async -> Bool {
        guard let user = await withLoading({
            try await self.firebaseService.signInWithApple()
        }) else {
            return false
        }
        
        // Explicitly update authentication state after successful sign-in
        await MainActor.run {
            self.isAuthenticated = true
            self.currentUser = user
        }
        
        // Load user data and setup listeners
        await loadUserData()
        setupRealTimeListeners()
        
        return true
    }
    
    func resetPassword(email: String) async -> Bool {
        return await withLoading({
            try await self.firebaseService.resetPassword(email: email)
        }) != nil
    }
    
    func updateProfile(username: String, displayName: String, profession: String, bio: String, profilePictureData: Data?) async -> Bool {
        guard var user = currentUser else { return false }
        
        // Update local user object
        user.username = username
        user.displayName = displayName
        user.profession = profession
        user.bio = bio
        user.profilePictureData = profilePictureData
        
        guard let _ = await withLoading({
            try await self.firebaseService.updateUser(user)
        }) else {
            return false
        }
        
        currentUser = user
        return true
    }
}

// MARK: - Post Management

extension FirebaseManager {
    
    func createPost(title: String, description: String, hours: String, minutes: String, imageData: Data?) async -> Bool {
        guard let currentUser = currentUser else { return false }
        
        let post = Post(
            userId: currentUser.id ?? "",
            username: currentUser.username,
            title: title,
            description: description,
            hours: hours,
            minutes: minutes,
            imageData: imageData
        )
        
        guard let _ = await withLoading({
            try await self.firebaseService.createPost(post)
        }) else {
            return false
        }
        
        // Refresh feed and user posts
        await loadFeedPosts()
        await loadUserPosts()
        
        return true
    }
    
    func loadFeedPosts() async {
        guard let posts = await withLoading({
            try await self.firebaseService.getFeedPosts(limit: 20)
        }) else {
            return
        }
        
        feedPosts = posts
    }
    
    func loadUserPosts(userId: String? = nil) async {
        let targetUserId = userId ?? currentUser?.id ?? ""
        
        guard let posts = await withLoading({
            try await self.firebaseService.getUserPosts(userId: targetUserId, limit: 20)
        }) else {
            return
        }
        
        if userId == nil || userId == currentUser?.id {
            userPosts = posts
        }
    }
    
    func likePost(_ post: Post) async {
        guard let postId = post.id else { return }
        
        let isCurrentlyLiked = post.isLikedByUser
        
        // Optimistic UI update
        if let index = feedPosts.firstIndex(where: { $0.id == postId }) {
            feedPosts[index].isLikedByUser = !isCurrentlyLiked
            feedPosts[index].likeCount += isCurrentlyLiked ? -1 : 1
        }
        
        do {
            if isCurrentlyLiked {
                try await self.firebaseService.unlikePost(postId: postId)
            } else {
                try await self.firebaseService.likePost(postId: postId)
            }
        } catch {
            // Revert optimistic update on error
            if let index = feedPosts.firstIndex(where: { $0.id == postId }) {
                feedPosts[index].isLikedByUser = isCurrentlyLiked
                feedPosts[index].likeCount += isCurrentlyLiked ? 1 : -1
            }
            handleError(error)
        }
    }
    
    func addComment(to post: Post, content: String) async -> Bool {
        guard let postId = post.id else { return false }
        
        guard let _ = await withLoading({
            try await self.firebaseService.addComment(postId: postId, content: content)
        }) else {
            return false
        }
        
        // Refresh feed to show updated comment count
        await loadFeedPosts()
        return true
    }
}

// MARK: - Social Features

extension FirebaseManager {
    
    func sendBuddyRequest(to userId: String) async -> Bool {
        return await withLoading({
            try await self.firebaseService.sendBuddyRequest(to: userId)
        }) != nil
    }
    
    func acceptBuddyRequest(from userId: String) async -> Bool {
        guard let _ = await withLoading({
            try await self.firebaseService.acceptBuddyRequest(from: userId)
        }) else {
            return false
        }
        
        // Refresh user stats to update buddy count
        if let currentUserId = currentUser?.id {
            userStats = try? await self.firebaseService.getUserStats(userId: currentUserId)
        }
        
        return true
    }
    
    func loadLeaderboard(sortType: LeaderboardSortType) async {
        guard let users = await withLoading({
            try await self.firebaseService.getLeaderboard(sortType: sortType, limit: 50)
        }) else {
            return
        }
        
        leaderboardUsers = users
    }
    
    func createConversation(with userId: String) async -> String? {
        return await withLoading({
            try await self.firebaseService.createConversation(with: userId)
        })
    }
    
    func sendMessage(conversationId: String, content: String) async -> Bool {
        return await withLoading({
            try await self.firebaseService.sendMessage(conversationId: conversationId, content: content)
        }) != nil
    }
    
    private func loadNotifications() async {
        guard let notifications = await withLoading({
            try await self.firebaseService.getUserNotifications(limit: 50)
        }) else {
            return
        }
        
        self.notifications = notifications
        unreadNotificationCount = notifications.filter { !$0.isRead }.count
    }
    
    private func loadConversations() async {
        guard let conversations = await withLoading({
            try await self.firebaseService.getConversations(limit: 50)
        }) else {
            return
        }
        
        self.conversations = conversations
    }
    
    func markNotificationAsRead(_ notification: AppNotification) async {
        guard let notificationId = notification.id else { return }
        
        do {
            try await self.firebaseService.markNotificationAsRead(notificationId: notificationId)
            
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                notifications[index].isRead = true
                unreadNotificationCount = max(0, unreadNotificationCount - 1)
            }
        } catch {
            handleError(error)
        }
    }
    
    func markAllNotificationsAsRead() async {
        do {
            try await self.firebaseService.markAllNotificationsAsRead()
            
            // Update local state
            for index in notifications.indices {
                notifications[index].isRead = true
            }
            unreadNotificationCount = 0
        } catch {
            handleError(error)
        }
    }
}

// MARK: - Search

extension FirebaseManager {
    
    func searchUsers(query: String) async {
        guard let results = await withLoading({
            try await self.firebaseService.searchUsers(query: query, limit: 20)
        }) else {
            return
        }
        
        searchResults = results
        
        // Save search history
        try? await self.firebaseService.saveSearchHistory(query: query, resultType: .user)
    }
    
    func searchPosts(query: String) async {
        guard let results = await withLoading({
            try await self.firebaseService.searchPosts(query: query, limit: 20)
        }) else {
            return
        }
        
        searchResults = results
        
        // Save search history
        try? await self.firebaseService.saveSearchHistory(query: query, resultType: .post)
    }
    
    func loadSearchHistory() async {
        guard let history = await withLoading({
            try await self.firebaseService.getSearchHistory(limit: 10)
        }) else {
            return
        }
        
        searchHistory = history
    }
    
    func clearSearchResults() {
        searchResults = []
    }
}

// MARK: - Utility Methods

extension FirebaseManager {
    
    var isEmailVerified: Bool {
        return self.firebaseService.isEmailVerified
    }
    
    func refreshUserStats() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            userStats = try await self.firebaseService.getUserStats(userId: userId)
        } catch {
            handleError(error)
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}
