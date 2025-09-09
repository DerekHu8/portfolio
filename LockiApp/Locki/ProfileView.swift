//
//  ProfileView.swift
//  Locki
//
//  Created by Derek Hu on 7/31/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var firebaseManager = FirebaseManager.shared
    @Binding var isPresented: Bool
    @Binding var posts: [Post]
    @Binding var showingSearch: Bool
    @Binding var showingCreatePost: Bool
    @Binding var showingLeaderboard: Bool
    @Binding var showingNotifications: Bool
    @Binding var showingProfile: Bool
    @State private var showingEditProfile = false
    @State private var profileUsername = "@yourusername"
    @State private var profileName = "YOUR NAME"
    @State private var profileProfession = "🎵 Productivity Enthusiast"
    @State private var profileBio = "🎯 \"Focus\" - the mindset • GETTING PRODUCTIVE"
    @State private var profilePictureData: Data?
    @State private var showingShareSheet = false
    @State private var showingSettingsPanel = false
    @State private var showingLoginDetails = false
    @State private var userSettings = UserSettings(userId: "")
    
    // User Statistics State Variables
    @State private var dailyStreak: Int = 0
    @State private var buddyCount: Int = 0
    @State private var totalStudyMinutes: Int = 0
    @State private var userPostCount: Int = 0
    
    init(isPresented: Binding<Bool> = .constant(true), posts: Binding<[Post]> = .constant([]), showingSearch: Binding<Bool> = .constant(false), showingCreatePost: Binding<Bool> = .constant(false), showingLeaderboard: Binding<Bool> = .constant(false), showingNotifications: Binding<Bool> = .constant(false), showingProfile: Binding<Bool> = .constant(false)) {
        self._isPresented = isPresented
        self._posts = posts
        self._showingSearch = showingSearch
        self._showingCreatePost = showingCreatePost
        self._showingLeaderboard = showingLeaderboard
        self._showingNotifications = showingNotifications
        self._showingProfile = showingProfile
    }
    
    // Calculate total study hours from Firebase data or local posts as fallback
    private var totalStudyHours: (hours: Int, minutes: Int) {
        // Use Firebase data if available, otherwise fallback to local posts
        if totalStudyMinutes > 0 {
            let finalHours = totalStudyMinutes / 60
            let remainingMinutes = totalStudyMinutes % 60
            return (hours: finalHours, minutes: remainingMinutes)
        } else {
            // Fallback to calculating from local posts
            let userPosts = posts.filter { $0.username == profileUsername }
            
            var totalMinutes = 0
            
            for post in userPosts {
                let hours = Int(post.hours) ?? 0
                let minutes = Int(post.minutes) ?? 0
                totalMinutes += (hours * 60) + minutes
            }
            
            let finalHours = totalMinutes / 60
            let remainingMinutes = totalMinutes % 60
            
            return (hours: finalHours, minutes: remainingMinutes)
        }
    }
    
    // Format total study time for display
    private var formattedStudyTime: String {
        let total = totalStudyHours
        if total.hours > 0 && total.minutes > 0 {
            return "\(total.hours)h \(total.minutes)m"
        } else if total.hours > 0 {
            return "\(total.hours)h"
        } else if total.minutes > 0 {
            return "\(total.minutes)m"
        } else {
            return "0h"
        }
    }
    
    // Generate share content for profile
    private var shareContent: [Any] {
        let profileURL = "https://locki.app/profile/\(profileUsername.replacingOccurrences(of: "@", with: ""))"
        let shareText = """
        Check out my Locki profile! 🔥
        
        \(profileName) (\(profileUsername))
        \(profileProfession)
        \(profileBio)
        
        📊 My Stats:
        • \(userPostCount > 0 ? userPostCount : posts.count) Posts
        • \(formattedStudyTime) Studied
        • \(dailyStreak) Day Streak
        • \(buddyCount) Buddies
        
        Join me on Locki - the productivity social app!
        \(profileURL)
        """
        
        return [shareText, URL(string: profileURL)!]
    }
    
    // MARK: - Settings Functions
    
    private func loadUserSettings() {
        Task {
            do {
                let settings = try await FirebaseService.shared.getUserSettings()
                DispatchQueue.main.async {
                    self.userSettings = settings
                    self.themeManager.currentTheme = settings.theme
                }
            } catch {
                print("Error loading user settings: \(error)")
            }
        }
    }
    
    private func loadUserProfile() {
        if let currentUser = firebaseManager.currentUser {
            profileUsername = "@\(currentUser.username)"
            profileName = currentUser.displayName.isEmpty ? currentUser.username : currentUser.displayName
            profileProfession = currentUser.profession
            profileBio = currentUser.bio
            profilePictureData = currentUser.profilePictureData
        }
    }
    
    private func loadUserStatistics() {
        guard let currentUser = firebaseManager.currentUser else {
            // Reset to default values if not authenticated
            dailyStreak = 0
            buddyCount = 0
            totalStudyMinutes = 0
            userPostCount = 0
            return
        }
        
        Task {
            do {
                // Load user statistics from Firebase
                let userStats = try await FirebaseService.shared.getUserStats(userId: currentUser.id ?? "")
                
                DispatchQueue.main.async {
                    self.dailyStreak = userStats.currentStreak
                    self.totalStudyMinutes = userStats.totalMinutes
                    self.userPostCount = userStats.totalPosts
                }
                
                // Load buddy count (this might require a separate query)
                let buddyIds = try await FirebaseService.shared.getBuddyIds(userId: currentUser.id ?? "")
                
                DispatchQueue.main.async {
                    self.buddyCount = buddyIds.count
                }
                
            } catch {
                print("Error loading user statistics: \(error)")
                // Keep default values (0) on error
            }
        }
    }
    
    private func saveUserSettings() {
        Task {
            do {
                try await FirebaseService.shared.updateUserSettings(userSettings)
            } catch {
                print("Error saving user settings: \(error)")
            }
        }
    }
    
    private func logOut() {
        Task {
            // Save user settings before logout
            saveUserSettings()
            
            // Save current profile data to Firebase
            if let currentUser = firebaseManager.currentUser {
                let success = await firebaseManager.updateProfile(
                    username: profileUsername.hasPrefix("@") ? String(profileUsername.dropFirst()) : profileUsername,
                    displayName: profileName,
                    profession: profileProfession,
                    bio: profileBio,
                    profilePictureData: profilePictureData
                )
            }
            
            // Wait a moment for saves to complete
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Sign out and return to login page
            await MainActor.run {
                FirebaseManager.shared.signOut()
                showingSettingsPanel = false
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            themeManager.colors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation
                HStack {
                    Spacer()
                    
                    // Username
                    Text(profileUsername)
                        .font(.title2)
                        .foregroundColor(themeManager.colors.primaryText)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Settings Button
                    Button(action: {
                        showingSettingsPanel = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.body)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Profile Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Picture and Info Section
                        VStack(spacing: 16) {
                            // Profile Picture with Verification Badge
                            ZStack {
                                if let profilePictureData = profilePictureData, let uiImage = UIImage(data: profilePictureData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(themeManager.colors.primaryText)
                                                .font(.system(size: 30))
                                        )
                                }
                                
                                // Verification Badge
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(themeManager.colors.primaryText)
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                            )
                                    }
                                }
                                .frame(width: 80, height: 80)
                            }
                            
                            // Name and Bio
                            VStack(spacing: 8) {
                                Text(profileName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.colors.primaryText)
                                
                                VStack(spacing: 4) {
                                    Text(profileProfession)
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.colors.secondaryText)
                                    
                                    Text(profileBio)
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.colors.secondaryText)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            
                            // Stats Section
                            HStack(spacing: 30) {
                                // Posts Count
                                VStack(spacing: 4) {
                                    Text("\(userPostCount > 0 ? userPostCount : posts.count)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(themeManager.colors.primaryText)
                                    
                                    Text("Posts")
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.secondaryText)
                                }
                                
                                // Productivity Hours
                                VStack(spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(themeManager.colors.primaryText)
                                            .font(.caption)
                                        
                                        Text(formattedStudyTime)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(themeManager.colors.primaryText)
                                    }
                                    
                                    Text("Hours")
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.secondaryText)
                                }
                                
                                // Daily Streak
                                VStack(spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(themeManager.colors.primaryText)
                                            .font(.caption)
                                        
                                        Text("\(dailyStreak)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(themeManager.colors.primaryText)
                                    }
                                    
                                    Text("Daily Streak")
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.secondaryText)
                                }
                                
                                // Buddies Count
                                VStack(spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.2.fill")
                                            .foregroundColor(themeManager.colors.primaryText)
                                            .font(.caption)
                                        
                                        Text("\(buddyCount)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(themeManager.colors.primaryText)
                                    }
                                    
                                    Text("Buddies")
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.secondaryText)
                                }
                            }
                            .padding(.top, 8)
                            
                            // Action Buttons
                            HStack(spacing: 12) {
                                // Edit Profile Button
                                Button(action: {
                                    showingEditProfile = true
                                }) {
                                    Text("Edit Profile")
                                        .font(.headline)
                                        .foregroundColor(themeManager.colors.primaryText)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(themeManager.colors.secondaryBackground)
                                        .cornerRadius(20)
                                }
                                
                                // Share Profile Button
                                Button(action: {
                                    showingShareSheet = true
                                }) {
                                    Text("Share Profile")
                                        .font(.headline)
                                        .foregroundColor(themeManager.colors.primaryText)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(themeManager.colors.secondaryBackground)
                                        .cornerRadius(20)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        
                        // Posts Grid Section
                        if !posts.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 2), spacing: 2) {
                                ForEach(posts.reversed()) { post in
                                    PostGridItemView(post: post)
                                }
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // No posts message
                            VStack {
                                Spacer()
                                    .frame(height: 60)
                                
                                Text("No Posts Yet")
                                    .font(.headline)
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .fontWeight(.medium)
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            
            // Bottom Navigation Bar
            VStack {
                Spacer()
                
                HStack {
                    // Home Button
                    Button(action: {
                        isPresented = false
                        showingSearch = false
                        showingCreatePost = false
                        showingLeaderboard = false
                    }) {
                        Image(systemName: "house.fill")
                            .foregroundColor(themeManager.colors.secondaryText)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    // Search Button
                    Button(action: {
                        isPresented = false
                        showingSearch = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(themeManager.colors.secondaryText)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    // Create Post Button (Center)
                    Button(action: {
                        isPresented = false
                        showingCreatePost = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.black)
                            .font(.body)
                            .fontWeight(.bold)
                            .frame(width: 32, height: 32)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Trophy Button (Leaderboard)
                    Button(action: {
                        isPresented = false
                        showingLeaderboard = true
                    }) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(themeManager.colors.secondaryText)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    // Profile Button
                    Button(action: {
                        // Already on profile page, do nothing
                    }) {
                        Image(systemName: "person.fill")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.body)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 14)
                .background(themeManager.colors.primaryBackground)
            }
            
            // Settings Panel Overlay
            if showingSettingsPanel {
                // Dark overlay
                themeManager.colors.shadowColor
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSettingsPanel = false
                        }
                    }
                
                // Settings Panel
                HStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Settings Header
                        HStack {
                            Text("Settings")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.colors.primaryText)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingSettingsPanel = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(themeManager.colors.primaryText)
                                    .font(.body)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                        
                        ScrollView {
                            VStack(spacing: 24) {
                                // App Settings Section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("App Settings")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.colors.primaryText)
                                        .padding(.horizontal, 20)
                                    
                                    // Theme Toggle
                                    HStack {
                                        Image(systemName: themeManager.currentTheme == .dark ? "moon.fill" : "sun.max.fill")
                                            .foregroundColor(themeManager.colors.primaryText)
                                            .font(.body)
                                        
                                        Text("Theme")
                                            .font(.body)
                                            .foregroundColor(themeManager.colors.primaryText)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                themeManager.toggleTheme()
                                                userSettings.theme = themeManager.currentTheme
                                                saveUserSettings()
                                            }
                                        }) {
                                            Text(themeManager.currentTheme.rawValue.capitalized)
                                                .font(.body)
                                                .foregroundColor(themeManager.colors.secondaryText)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                
                                // Privacy Settings Section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Privacy")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.colors.primaryText)
                                        .padding(.horizontal, 20)
                                    
                                    // Profile Visibility
                                    HStack {
                                        Image(systemName: "eye.fill")
                                            .foregroundColor(themeManager.colors.primaryText)
                                            .font(.body)
                                        
                                        Text("Profile Visibility")
                                            .font(.body)
                                            .foregroundColor(themeManager.colors.primaryText)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                switch userSettings.profileVisibility {
                                                case .publicProfile:
                                                    userSettings.profileVisibility = .buddiesOnly
                                                case .buddiesOnly:
                                                    userSettings.profileVisibility = .privateProfile
                                                case .privateProfile:
                                                    userSettings.profileVisibility = .publicProfile
                                                }
                                                saveUserSettings()
                                            }
                                        }) {
                                            Text(userSettings.profileVisibility.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                                .font(.body)
                                                .foregroundColor(themeManager.colors.secondaryText)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                
                                // Notification Settings Section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Notifications")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.colors.primaryText)
                                        .padding(.horizontal, 20)
                                    
                                    // Push Notifications
                                    HStack {
                                        Image(systemName: "bell.fill")
                                            .foregroundColor(themeManager.colors.primaryText)
                                            .font(.body)
                                        
                                        Text("Push Notifications")
                                            .font(.body)
                                            .foregroundColor(themeManager.colors.primaryText)
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: Binding(
                                            get: { userSettings.pushNotificationsEnabled },
                                            set: { newValue in
                                                userSettings.pushNotificationsEnabled = newValue
                                                saveUserSettings()
                                            }
                                        ))
                                        .tint(themeManager.colors.toggleColor)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    // Like Notifications
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(themeManager.colors.primaryText)
                                            .font(.body)
                                        
                                        Text("Like Notifications")
                                            .font(.body)
                                            .foregroundColor(themeManager.colors.primaryText)
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: Binding(
                                            get: { userSettings.likeNotifications },
                                            set: { newValue in
                                                userSettings.likeNotifications = newValue
                                                saveUserSettings()
                                            }
                                        ))
                                        .tint(themeManager.colors.toggleColor)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    // Comment Notifications
                                    HStack {
                                        Image(systemName: "bubble.fill")
                                            .foregroundColor(themeManager.colors.primaryText)
                                            .font(.body)
                                        
                                        Text("Comment Notifications")
                                            .font(.body)
                                            .foregroundColor(themeManager.colors.primaryText)
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: Binding(
                                            get: { userSettings.commentNotifications },
                                            set: { newValue in
                                                userSettings.commentNotifications = newValue
                                                saveUserSettings()
                                            }
                                        ))
                                        .tint(themeManager.colors.toggleColor)
                                    }
                                    .padding(.horizontal, 20)
                                }
                                
                                // Account Section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Account")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.colors.primaryText)
                                        .padding(.horizontal, 20)
                                    
                                    // View Login Details Button
                                    Button(action: {
                                        showingLoginDetails = true
                                    }) {
                                        HStack {
                                            Image(systemName: "person.text.rectangle.fill")
                                                .foregroundColor(themeManager.colors.primaryText)
                                                .font(.body)
                                            
                                            Text("View Login Details")
                                                .font(.body)
                                                .foregroundColor(themeManager.colors.primaryText)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                    
                                    // Log Out Button
                                    Button(action: {
                                        // Log out functionality
                                        logOut()
                                    }) {
                                        HStack {
                                            Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                                .foregroundColor(.red)
                                                .font(.body)
                                            
                                            Text("Log Out")
                                                .font(.body)
                                                .foregroundColor(.red)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                
                                Spacer(minLength: 100) // Bottom padding
                            }
                        }
                    }
                    .frame(width: 320)
                    .background(themeManager.colors.primaryBackground)
                    .cornerRadius(20, corners: [.topLeft, .bottomLeft])
                    .shadow(color: themeManager.colors.shadowColor, radius: 10, x: -5, y: 0)
                }
                .transition(.move(edge: .trailing))
                .animation(.easeInOut(duration: 0.3), value: showingSettingsPanel)
            }
            
            // Login Details Overlay
            if showingLoginDetails {
                // Dark overlay
                themeManager.colors.shadowColor
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingLoginDetails = false
                        }
                    }
                
                // Login Details Panel
                VStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Login Details")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.colors.primaryText)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingLoginDetails = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(themeManager.colors.primaryText)
                                    .font(.body)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                        
                        // Login Details Content
                        VStack(spacing: 20) {
                            // Email Section
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(themeManager.colors.primaryText)
                                        .font(.body)
                                    
                                    Text("Email")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.colors.primaryText)
                                }
                                
                                Text(Auth.auth().currentUser?.email ?? "No email found")
                                    .font(.body)
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(themeManager.colors.secondaryBackground)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 20)
                            
                            // Password Section
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(themeManager.colors.primaryText)
                                        .font(.body)
                                    
                                    Text("Password")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.colors.primaryText)
                                }
                                
                                Text("••••••••••••")
                                    .font(.body)
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(themeManager.colors.secondaryBackground)
                                    .cornerRadius(10)
                                
                                Text("For security reasons, your password is protected and cannot be displayed.")
                                    .font(.caption)
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .padding(.top, 4)
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.bottom, 30)
                    }
                    .background(themeManager.colors.primaryBackground)
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    .shadow(color: themeManager.colors.shadowColor, radius: 10, x: 0, y: -5)
                    
                    Spacer()
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.3), value: showingLoginDetails)
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(
                isPresented: $showingEditProfile,
                username: $profileUsername,
                name: $profileName,
                profession: $profileProfession,
                bio: $profileBio,
                profilePictureData: $profilePictureData
            )
            .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareContent)
        }
        .onAppear {
            loadUserSettings()
            loadUserProfile()
            loadUserStatistics()
        }
        .onChange(of: firebaseManager.isAuthenticated) {
            if firebaseManager.isAuthenticated {
                loadUserProfile()
                loadUserStatistics()
            } else {
                // Reset statistics when user logs out
                dailyStreak = 0
                buddyCount = 0
                totalStudyMinutes = 0
                userPostCount = 0
            }
        }
    }
}

// MARK: - Custom Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

struct EditProfileView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var firebaseManager = FirebaseManager.shared
    @Binding var isPresented: Bool
    @Binding var username: String
    @Binding var name: String
    @Binding var profession: String
    @Binding var bio: String
    @Binding var profilePictureData: Data?
    @State private var editedUsername: String = ""
    @State private var editedName: String = ""
    @State private var editedProfession: String = ""
    @State private var editedBio: String = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        ZStack {
            // Background
            themeManager.colors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation
                HStack {
                    // Cancel Button
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.primaryText)
                    }
                    
                    Spacer()
                    
                    // Title
                    Text("Edit Profile")
                        .font(.title2)
                        .foregroundColor(themeManager.colors.primaryText)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Space for alignment
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Picture Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Profile Picture")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.primaryText)
                                .fontWeight(.medium)
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(themeManager.colors.secondaryBackground)
                                        .frame(width: 100, height: 100)
                                    
                                    if let selectedImage = selectedImage {
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    } else if let profilePictureData = profilePictureData, let uiImage = UIImage(data: profilePictureData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    } else {
                                        VStack(spacing: 8) {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(themeManager.colors.primaryText)
                                            
                                            Text("Tap to change")
                                                .font(.caption)
                                                .foregroundColor(themeManager.colors.secondaryText)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                        
                        // Username Input Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Username")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.primaryText)
                                .fontWeight(.medium)
                            
                            ZStack(alignment: .leading) {
                                if editedUsername.isEmpty {
                                    Text("Enter your username...")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.leading, 16)
                                }
                                TextField("", text: $editedUsername)
                                    .foregroundColor(themeManager.colors.primaryText)
                                    .padding(.leading, 16)
                            }
                            .frame(height: 54)
                            .background(themeManager.colors.secondaryBackground)
                            .cornerRadius(27)
                        }
                        .padding(.horizontal, 20)
                        
                        // Name Input Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Name")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.primaryText)
                                .fontWeight(.medium)
                            
                            ZStack(alignment: .leading) {
                                if editedName.isEmpty {
                                    Text("Enter your name...")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.leading, 16)
                                }
                                TextField("", text: $editedName)
                                    .foregroundColor(themeManager.colors.primaryText)
                                    .padding(.leading, 16)
                            }
                            .frame(height: 54)
                            .background(themeManager.colors.secondaryBackground)
                            .cornerRadius(27)
                        }
                        .padding(.horizontal, 20)
                        
                        // Profession Input Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Profession")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.primaryText)
                                .fontWeight(.medium)
                            
                            ZStack(alignment: .leading) {
                                if editedProfession.isEmpty {
                                    Text("Enter your profession...")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.leading, 16)
                                }
                                TextField("", text: $editedProfession)
                                    .foregroundColor(themeManager.colors.primaryText)
                                    .padding(.leading, 16)
                            }
                            .frame(height: 54)
                            .background(themeManager.colors.secondaryBackground)
                            .cornerRadius(27)
                        }
                        .padding(.horizontal, 20)
                        
                        // Bio Input Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Biography")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.primaryText)
                                .fontWeight(.medium)
                            
                            ZStack(alignment: .topLeading) {
                                if editedBio.isEmpty {
                                    Text("Enter your biography...")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.leading, 20)
                                        .padding(.top, 18)
                                }
                                TextEditor(text: $editedBio)
                                    .foregroundColor(themeManager.colors.primaryText)
                                    .padding(.leading, 16)
                                    .padding(.trailing, 16)
                                    .padding(.top, 10)
                                    .padding(.bottom, 12)
                                    .scrollContentBackground(.hidden)
                            }
                            .frame(height: 120)
                            .background(themeManager.colors.secondaryBackground)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                        
                        // Spacer to push save button to bottom
                        Spacer(minLength: 80)
                    }
                    .padding(.bottom, 100)
                }
            }
            
            // Save Button (Bottom Right)
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        Task {
                            // Save changes locally
                            username = editedUsername
                            name = editedName
                            profession = editedProfession
                            bio = editedBio
                            
                            // Save profile picture if selected
                            var updatedProfilePictureData = profilePictureData
                            if let selectedImage = selectedImage {
                                updatedProfilePictureData = selectedImage.jpegData(compressionQuality: 0.8)
                                profilePictureData = updatedProfilePictureData
                            }
                            
                            // Update profile in Firebase
                            let success = await firebaseManager.updateProfile(
                                username: editedUsername.hasPrefix("@") ? String(editedUsername.dropFirst()) : editedUsername,
                                displayName: editedName,
                                profession: editedProfession,
                                bio: editedBio,
                                profilePictureData: updatedProfilePictureData
                            )
                            
                            // Dismiss the view
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Save")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeManager.colors.primaryText)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(themeManager.colors.primaryText)
                        }
                        .frame(width: 110, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(red: 0.2, green: 0.6, blue: 1.0))
                        )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            editedUsername = username
            editedName = name
            editedProfession = profession
            editedBio = bio
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
}

struct PostGridItemView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let post: Post
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(themeManager.colors.secondaryText)
                                .font(.title2)
                        )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    ProfileView()
        .environmentObject(ThemeManager.shared)
}
