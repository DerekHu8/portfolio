//
//  SearchView.swift
//  Locki
//
//  Created by Derek Hu on 7/31/25.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var firebaseManager = FirebaseManager.shared
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var showingOtherProfile = false
    @State private var selectedUser: User?
    @Binding var isPresented: Bool
    @Binding var showingProfile: Bool
    @Binding var showingCreatePost: Bool
    @Binding var showingLeaderboard: Bool
    @Binding var showingNotifications: Bool
    
    init(isPresented: Binding<Bool> = .constant(true), showingProfile: Binding<Bool> = .constant(false), showingCreatePost: Binding<Bool> = .constant(false), showingLeaderboard: Binding<Bool> = .constant(false), showingNotifications: Binding<Bool> = .constant(false)) {
        self._isPresented = isPresented
        self._showingProfile = showingProfile
        self._showingCreatePost = showingCreatePost
        self._showingLeaderboard = showingLeaderboard
        self._showingNotifications = showingNotifications
    }
    
    var body: some View {
        ZStack {
            // Background
            themeManager.colors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Header
                HStack {
                    Spacer()
                    
                    Text("Search")
                        .font(.title2)
                        .foregroundColor(themeManager.colors.primaryText)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Search Bar
                HStack(spacing: 12) {
                    // Magnifying Glass Icon
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.colors.secondaryText)
                        .font(.title3)
                    
                    // Search Text Field
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("Search")
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        TextField("", text: $searchText)
                            .foregroundColor(themeManager.colors.primaryText)
                            .onChange(of: searchText) {
                                performSearch()
                            }
                    }
                }
                .padding(.horizontal, 20)
                .frame(height: 54)
                .background(themeManager.colors.secondaryBackground)
                .cornerRadius(27)
                .padding(.horizontal, 24)
                
                // Search Results
                if searchText.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(themeManager.colors.secondaryText.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("Search for Users")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.colors.primaryText)
                            
                            Text("Find friends and discover new people")
                                .font(.subheadline)
                                .foregroundColor(themeManager.colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                } else {
                    // Search results
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchResults) { user in
                                SearchResultRow(user: user) {
                                    selectedUser = user
                                    showingOtherProfile = true
                                }
                                .environmentObject(themeManager)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
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
                        showingCreatePost = false
                        showingLeaderboard = false
                        showingProfile = false
                    }) {
                        Image(systemName: "house.fill")
                            .foregroundColor(themeManager.colors.secondaryText)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    // Search Button
                    Button(action: {
                        // Already on search page, do nothing
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    // Create Post Button (Center)
                    Button(action: {
                        isPresented = false
                        showingCreatePost = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(themeManager.colors.primaryBackground)
                            .font(.body)
                            .fontWeight(.bold)
                            .frame(width: 32, height: 32)
                            .background(themeManager.colors.primaryText)
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
                        isPresented = false
                        showingProfile = true
                    }) {
                        Image(systemName: "person.fill")
                            .foregroundColor(themeManager.colors.secondaryText)
                            .font(.body)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 14)
                .background(themeManager.colors.primaryBackground)
            }
        }
        .fullScreenCover(isPresented: $showingOtherProfile) {
            if let selectedUser = selectedUser {
                OtherUserProfileView(user: selectedUser, isPresented: $showingOtherProfile)
                    .environmentObject(themeManager)
            }
        }
    }
    
    // MARK: - Search Functions
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        Task {
            do {
                // Search users directly using FirebaseService
                let users = try await FirebaseService.shared.searchUsersForProfiles(query: searchText, limit: 10)
                await MainActor.run {
                    searchResults = users
                }
            } catch {
                print("Search error: \(error)")
                await MainActor.run {
                    searchResults = []
                }
            }
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let user: User
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Profile Picture
                if let profilePictureData = user.profilePictureData, let uiImage = UIImage(data: profilePictureData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(themeManager.colors.secondaryBackground)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(themeManager.colors.secondaryText)
                                .font(.title3)
                        )
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.displayName.isEmpty ? user.username : user.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.colors.primaryText)
                        
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                    
                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.secondaryText)
                    
                    if !user.profession.isEmpty {
                        Text(user.profession)
                            .font(.caption)
                            .foregroundColor(themeManager.colors.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(themeManager.colors.secondaryText)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(themeManager.colors.secondaryBackground)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Other User Profile View

struct OtherUserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var firebaseManager = FirebaseManager.shared
    let user: User
    @Binding var isPresented: Bool
    @State private var userPosts: [Post] = []
    @State private var userStats: UserStats?
    
    // Calculate total study hours from user's posts
    private var totalStudyHours: (hours: Int, minutes: Int) {
        let userPosts = userPosts.filter { $0.username == user.username }
        
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
    
    var body: some View {
        ZStack {
            // Background
            themeManager.colors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    // Username
                    Text("@\(user.username)")
                        .font(.title2)
                        .foregroundColor(themeManager.colors.primaryText)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Invisible spacer for alignment
                    Image(systemName: "xmark")
                        .foregroundColor(.clear)
                        .font(.body)
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
                                if let profilePictureData = user.profilePictureData, let uiImage = UIImage(data: profilePictureData) {
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
                                if user.isVerified {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.white)
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                )
                                        }
                                    }
                                    .frame(width: 80, height: 80)
                                }
                            }
                            
                            // Name and Bio
                            VStack(spacing: 8) {
                                Text(user.displayName.isEmpty ? user.username : user.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.colors.primaryText)
                                
                                VStack(spacing: 4) {
                                    if !user.profession.isEmpty {
                                        Text(user.profession)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.colors.secondaryText)
                                    }
                                    
                                    if !user.bio.isEmpty {
                                        Text(user.bio)
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.colors.secondaryText)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                            
                            // Stats Section
                            HStack(spacing: 30) {
                                // Posts Count
                                VStack(spacing: 4) {
                                    Text("\(userPosts.count)")
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
                                
                                // Daily Streak (placeholder)
                                VStack(spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(themeManager.colors.primaryText)
                                            .font(.caption)
                                        
                                        Text("\(userStats?.currentStreak ?? 0)")
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
                                        
                                        Text("\(userStats?.buddyCount ?? 0)")
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
                                // Follow/Message Button
                                Button(action: {
                                    // Follow or message functionality
                                }) {
                                    Text("Follow")
                                        .font(.headline)
                                        .foregroundColor(themeManager.colors.primaryText)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(themeManager.colors.secondaryBackground)
                                        .cornerRadius(20)
                                }
                                
                                // Message Button
                                Button(action: {
                                    // Message functionality
                                }) {
                                    Text("Message")
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
                        if !userPosts.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 2), spacing: 2) {
                                ForEach(userPosts.reversed()) { post in
                                    PostGridItemView(post: post)
                                        .environmentObject(themeManager)
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
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        Task {
            // Load user's posts directly
            if let userId = user.id {
                do {
                    let posts = try await FirebaseService.shared.getUserPosts(userId: userId, limit: 20)
                    await MainActor.run {
                        userPosts = posts
                    }
                    
                    // Load user stats
                    userStats = try await FirebaseService.shared.getUserStats(userId: userId)
                } catch {
                    print("Error loading user data: \(error)")
                }
            }
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(ThemeManager.shared)
}
