 //
//  HomeView.swift
//  Locki
//
//  Created by Derek Hu on 7/31/25.
//

import SwiftUI

enum NavigationDirection {
    case left, right, none
}

struct HomeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingNotifications = false
    @State private var posts: [Post] = []
    @State private var currentPagePosition: Int = 0 // 0=Home, 1=Search, 2=CreatePost, 3=Leaderboard, 4=Profile
    @State private var scrollOffset: CGFloat = 0
    @State private var showingSearch = false
    @State private var showingCreatePost = false
    @State private var showingLeaderboard = false
    @State private var showingProfile = false
    @State private var showingMessages = false
    @State private var navigationDirection: NavigationDirection = .none
    
    // Function to navigate to a page with smooth scrolling
    private func navigateToPage(_ targetPosition: Int) {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPagePosition = targetPosition
            scrollOffset = -CGFloat(targetPosition) * UIScreen.main.bounds.width
        }
    }
    
    // Function to navigate instantly without animation
    private func navigateToPageInstantly(_ targetPosition: Int) {
        // First, close all overlays
        showingSearch = false
        showingCreatePost = false
        showingLeaderboard = false
        showingProfile = false
        showingMessages = false
        
        switch targetPosition {
        case 0:
            // Home - use carousel navigation
            currentPagePosition = 0
            scrollOffset = 0
        case 1:
            // Search - use overlay
            showingSearch = true
        case 2:
            // Create Post - use overlay
            showingCreatePost = true
        case 3:
            // Leaderboard - use overlay
            showingLeaderboard = true
        case 4:
            // Profile - use overlay
            showingProfile = true
        default:
            break
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                themeManager.colors.primaryBackground
                    .ignoresSafeArea()
                
                // Main content area - just show home page
                HomePageContent(posts: $posts, onNotificationsTap: {
                    showingNotifications = true
                }, onMessagesTap: {
                    showingMessages = true
                })
                .environmentObject(themeManager)
                .frame(width: geometry.size.width)
                
            }
        }
        .overlay(
            // Notifications overlay (only one that slides from edge)
            Group {
                if showingNotifications {
                    NotificationsView(isPresented: $showingNotifications)
                        .environmentObject(themeManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                        .zIndex(10)
                }
            }
        )
        .overlay(
            // Bottom Navigation Bar
            VStack {
                Spacer()
                
                HStack {
                    // Home Button
                    Button(action: {
                        showingSearch = false
                        showingCreatePost = false
                        showingLeaderboard = false
                        showingProfile = false
                        showingMessages = false
                    }) {
                        Image(systemName: "house.fill")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    // Search Button
                    Button(action: {
                        showingSearch = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(themeManager.colors.secondaryText)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    // Create Post Button (Center)
                    Button(action: {
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
                        showingLeaderboard = true
                    }) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(themeManager.colors.secondaryText)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    // Profile Button
                    Button(action: {
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
        )
        .overlay(
            // Messages View Overlay
            Group {
                if showingMessages {
                    MessagesView(isPresented: $showingMessages)
                        .environmentObject(themeManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                        .zIndex(5)
                }
            }
        )
        .overlay(
            // Overlay Manager for separate views
            OverlayManager(
                showingProfile: $showingProfile,
                showingSearch: $showingSearch,
                showingNotifications: $showingNotifications,
                showingCreatePost: $showingCreatePost,
                showingLeaderboard: $showingLeaderboard,
                navigationDirection: navigationDirection,
                posts: $posts,
                onPostCreated: { newPost in
                    posts.append(newPost)
                }
            )
            .environmentObject(themeManager)
        )
        .animation(.easeInOut(duration: 0.3), value: showingNotifications)
        .animation(.easeInOut(duration: 0.3), value: showingMessages)
    }
}

// Individual Page Content Components
struct HomePageContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var posts: [Post]
    let onNotificationsTap: () -> Void
    let onMessagesTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack {
                // Locki Title
                Text("Locki")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.colors.primaryText)
                
                Spacer()
                
                // Messaging and Notifications Icons
                HStack(spacing: 16) {
                    // Notifications Button
                    Button(action: {
                        onNotificationsTap()
                    }) {
                        Image(systemName: "bell")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.title3)
                    }
                    
                    // Messaging Icon
                    Button(action: {
                        onMessagesTap()
                    }) {
                        Image(systemName: "message")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.title3)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            // Posts Content Area
            ScrollView {
                LazyVStack(spacing: 16) {
                    if posts.isEmpty {
                        // Show placeholder posts when no real posts exist
                        ForEach(0..<5, id: \.self) { index in
                            PostCardView(index: index)
                        }
                    } else {
                        // Show real posts
                        ForEach(posts.reversed()) { post in
                            RealPostCardView(post: post) {
                                // Toggle like state
                                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                                    posts[index].isLikedByUser.toggle()
                                    if posts[index].isLikedByUser {
                                        posts[index].likeCount += 1
                                    } else {
                                        posts[index].likeCount -= 1
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            
            Spacer()
        }
    }
}

struct SearchPageContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    let onNavigate: (Int) -> Void
    
    var body: some View {
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
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 54)
            .background(themeManager.colors.secondaryBackground)
            .cornerRadius(27)
            .padding(.horizontal, 24)
            
            // Main Content Area
            Spacer()
        }
        
        // Bottom Navigation Bar
        VStack {
            Spacer()
            
            HStack {
                // Home Button
                Button(action: {
                    onNavigate(0)
                }) {
                    Image(systemName: "house.fill")
                        .foregroundColor(themeManager.colors.primaryText)
                        .font(.body)
                }
                
                Spacer()
                
                // Search Button
                Button(action: {
                    onNavigate(1)
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.colors.secondaryText)
                        .font(.body)
                }
                
                Spacer()
                
                // Create Post Button (Center)
                Button(action: {
                    onNavigate(2)
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
                    onNavigate(3)
                }) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(themeManager.colors.secondaryText)
                        .font(.body)
                }
                
                Spacer()
                
                // Profile Button
                Button(action: {
                    onNavigate(4)
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
}

struct CreatePostPageContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var posts: [Post]
    @State private var selectedHours = ""
    @State private var selectedMinutes = ""
    @State private var postTitle = ""
    @State private var postDescription = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    private var canPost: Bool {
        !selectedHours.isEmpty && !selectedMinutes.isEmpty && !postTitle.isEmpty && !postDescription.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation
            HStack {
                Spacer()
                
                Text("Create a New Post")
                    .font(.title2)
                    .foregroundColor(themeManager.colors.primaryText)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            // Main Content
            ScrollView {
                VStack(spacing: 24) {
                    // Timer Selection Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time Worked")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.primaryText)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 16) {
                            // Hours Text Field
                            VStack(spacing: 8) {
                                Text("Hours")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.colors.secondaryText)
                                
                                TextField("0", text: $selectedHours)
                                    .foregroundColor(themeManager.colors.primaryText)
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .frame(height: 50)
                                    .background(themeManager.colors.secondaryBackground)
                                    .cornerRadius(12)
                            }
                            
                            // Minutes Text Field
                            VStack(spacing: 8) {
                                Text("Minutes")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.colors.secondaryText)
                                
                                TextField("0", text: $selectedMinutes)
                                    .foregroundColor(themeManager.colors.primaryText)
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .frame(height: 50)
                                    .background(themeManager.colors.secondaryBackground)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Post Content Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Post Details")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.primaryText)
                            .fontWeight(.medium)
                        
                        // Post Title
                        TextField("Post title...", text: $postTitle)
                            .foregroundColor(themeManager.colors.primaryText)
                            .padding(16)
                            .background(themeManager.colors.secondaryBackground)
                            .cornerRadius(12)
                        
                        // Post Description
                        TextField("What did you work on?", text: $postDescription, axis: .vertical)
                            .foregroundColor(themeManager.colors.primaryText)
                            .padding(16)
                            .background(themeManager.colors.secondaryBackground)
                            .cornerRadius(12)
                            .frame(minHeight: 100)
                        
                        // Add Image Button
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundColor(themeManager.colors.primaryText)
                                Text("Add Image")
                                    .foregroundColor(themeManager.colors.primaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(themeManager.colors.secondaryBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Post Button
                    Button(action: {
                        if canPost {
                            let newPost = Post(
                                userId: "current_user_id",
                                username: "@yourusername",
                                title: postTitle,
                                description: postDescription,
                                hours: selectedHours,
                                minutes: selectedMinutes,
                                imageData: selectedImage?.jpegData(compressionQuality: 0.8)
                            )
                            posts.append(newPost)
                            
                            // Reset form
                            selectedHours = ""
                            selectedMinutes = ""
                            postTitle = ""
                            postDescription = ""
                            selectedImage = nil
                        }
                    }) {
                        Text("Post")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(canPost ? .black : .gray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(canPost ? Color.white : Color.gray.opacity(0.3))
                            .cornerRadius(25)
                    }
                    .disabled(!canPost)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
}

struct LeaderboardPageContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var sortType: LeaderboardSortType = .hours
    let onNavigate: (Int) -> Void
    
    // Sample leaderboard data
    private let users = [
        LeaderboardUser(userId: "1", username: "alex_chen", displayName: "Alex Chen", profileImage: "person.fill", totalHours: 145, dailyStreak: 12),
        LeaderboardUser(userId: "2", username: "sarah_j", displayName: "Sarah J", profileImage: "person.fill", totalHours: 132, dailyStreak: 18),
        LeaderboardUser(userId: "3", username: "mike_wilson", displayName: "Mike Wilson", profileImage: "person.fill", totalHours: 128, dailyStreak: 8),
        LeaderboardUser(userId: "4", username: "emma_davis", displayName: "Emma Davis", profileImage: "person.fill", totalHours: 119, dailyStreak: 15),
        LeaderboardUser(userId: "5", username: "john_doe", displayName: "John Doe", profileImage: "person.fill", totalHours: 108, dailyStreak: 22)
    ]
    private var sortedUsers: [LeaderboardUser] {
        switch sortType {
        case .hours:
            return users.sorted { $0.totalHours > $1.totalHours }
        case .streak:
            return users.sorted { $0.dailyStreak > $1.dailyStreak }
        case .weekly:
            return users.sorted { $0.weeklyHours > $1.weeklyHours }
        case .monthly:
            return users.sorted { $0.monthlyHours > $1.monthlyHours }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Header with Trophy and Title
            VStack(spacing: 16) {
                // Trophy Icon
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 60))
                
                // Leaderboard Title
                Text("Leaderboard")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.colors.primaryText)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            // Toggle Buttons
            HStack(spacing: 12) {
                // Hours Button
                Button(action: {
                    sortType = .hours
                }) {
                    Text("Hours")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(sortType == .hours ? .black : .white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(sortType == .hours ? Color.white : Color.clear)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: sortType == .hours ? 0 : 1)
                        )
                }
                
                // Daily Streak Button
                Button(action: {
                    sortType = .streak
                }) {
                    Text("Daily Streak")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(sortType == .streak ? .black : .white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(sortType == .streak ? Color.white : Color.clear)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: sortType == .streak ? 0 : 1)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            
            // Leaderboard List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(sortedUsers.enumerated()), id: \.element.id) { index, user in
                        LeaderboardRowView(
                            user: user,
                            rank: index + 1,
                            sortType: sortType,
                            onTap: {
                                // Handle tap
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }
}

struct ProfilePageContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    let posts: [Post]
    let onNavigate: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation
            HStack {
                Spacer()
                
                Text("@yourusername")
                    .font(.title2)
                    .foregroundColor(themeManager.colors.primaryText)
                    .fontWeight(.bold)
                
                Spacer()
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
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(themeManager.colors.primaryText)
                                        .font(.system(size: 30))
                                )
                            
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
                        
                        // Stats Section
                        HStack(spacing: 40) {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("25h 32m")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(themeManager.colors.primaryText)
                                }
                                
                                Text("This Week")
                                    .font(.caption)
                                    .foregroundColor(themeManager.colors.secondaryText)
                            }
                            
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("156")
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
                            // Message Button
                            Button(action: {
                                // Handle message
                            }) {
                                Text("Message")
                                    .font(.headline)
                                    .foregroundColor(themeManager.colors.primaryText)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(themeManager.colors.secondaryBackground)
                                    .cornerRadius(20)
                            }
                            
                            // Buddied Button
                            Button(action: {
                                // Handle buddied action
                            }) {
                                HStack(spacing: 6) {
                                    Text("Buddied")
                                        .font(.headline)
                                        .foregroundColor(themeManager.colors.primaryText)
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(themeManager.colors.primaryText)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(themeManager.colors.secondaryBackground)
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .padding(.bottom, 100)
            }
        }
    }
}

struct PostCardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info Section
            HStack {
                // Profile Picture
                Circle()
                    .fill(Color.gray)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.caption)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Roberta A.")
                        .font(.headline)
                        .foregroundColor(themeManager.colors.primaryText)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("Active now")
                            .font(.caption)
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(themeManager.colors.secondaryText)
                        .font(.title3)
                }
            }
            
            // Post Content
            Text("Join me to study for the big real estate test! Let's get productive together.")
                .font(.body)
                .foregroundColor(themeManager.colors.primaryText)
                .multilineTextAlignment(.leading)
            
            // Post Image
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(themeManager.colors.secondaryText)
                        .font(.system(size: 40))
                )
            
            // Action Buttons
            HStack(spacing: 20) {
                // Like Button
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart")
                            .foregroundColor(themeManager.colors.secondaryText)
                            .font(.title3)
                        
                        Text("64")
                            .font(.subheadline)
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                // Comment Button
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "message")
                            .foregroundColor(themeManager.colors.secondaryText)
                            .font(.title3)
                        
                        Text("12")
                            .font(.subheadline)
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                // Share Button
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(themeManager.colors.secondaryText)
                        .font(.title3)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(16)
    }
}

struct RealPostCardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let post: Post
    let onLike: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info Section
            HStack {
                // Profile Picture
                Circle()
                    .fill(Color.gray)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.caption)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.username)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.primaryText)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("Active now")
                            .font(.caption)
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Time worked display
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.caption)
                        
                        Text("\(post.hours)h \(post.minutes)m")
                            .font(.caption)
                            .foregroundColor(themeManager.colors.primaryText)
                            .fontWeight(.medium)
                    }
                }
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(themeManager.colors.secondaryText)
                        .font(.title3)
                }
            }
            
            // Post Title
            Text(post.title)
                .font(.headline)
                .foregroundColor(themeManager.colors.primaryText)
                .fontWeight(.medium)
            
            // Post Content
            Text(post.description)
                .font(.body)
                .foregroundColor(themeManager.colors.primaryText)
                .multilineTextAlignment(.leading)
            
            // Post Image (if available)
            if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                // Like Button
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLikedByUser ? "heart.fill" : "heart")
                            .foregroundColor(post.isLikedByUser ? .red : .gray)
                            .font(.title3)
                        
                        Text("\(post.likeCount)")
                            .font(.subheadline)
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                // Comment Button
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "message")
                            .foregroundColor(themeManager.colors.secondaryText)
                            .font(.title3)
                        
                        Text("0")
                            .font(.subheadline)
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                // Share Button
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(themeManager.colors.secondaryText)
                        .font(.title3)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(16)
    }
}

struct OverlayManager: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showingProfile: Bool
    @Binding var showingSearch: Bool
    @Binding var showingNotifications: Bool
    @Binding var showingCreatePost: Bool
    @Binding var showingLeaderboard: Bool
    let navigationDirection: NavigationDirection
    @Binding var posts: [Post]
    let onPostCreated: (Post) -> Void
    
    // Helper function to get transition based on navigation direction
    private func getTransition() -> AnyTransition {
        switch navigationDirection {
        case .right:
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        case .left:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .none:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Profile View Overlay
            if showingProfile {
                ProfileView(isPresented: $showingProfile, posts: $posts, showingSearch: $showingSearch, showingCreatePost: $showingCreatePost, showingLeaderboard: $showingLeaderboard, showingNotifications: $showingNotifications)
                    .environmentObject(themeManager)
                    .zIndex(4)
            }
            
            // Search View Overlay
            if showingSearch {
                SearchView(isPresented: $showingSearch, showingProfile: $showingProfile, showingCreatePost: $showingCreatePost, showingLeaderboard: $showingLeaderboard, showingNotifications: $showingNotifications)
                    .environmentObject(themeManager)
                    .zIndex(1)
            }
            
            // Notifications View Overlay
            if showingNotifications {
                NotificationsView(isPresented: $showingNotifications, showingSearch: $showingSearch, showingProfile: $showingProfile, showingCreatePost: $showingCreatePost, showingLeaderboard: $showingLeaderboard)
                    .environmentObject(themeManager)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
                    .zIndex(3)
            }
            
            // Create Post View Overlay
            if showingCreatePost {
                CreatePostView(isPresented: $showingCreatePost, onPostCreated: onPostCreated, showingSearch: $showingSearch, showingProfile: $showingProfile, showingLeaderboard: $showingLeaderboard, showingNotifications: $showingNotifications)
                    .environmentObject(themeManager)
                    .zIndex(2)
            }
            
            // Leaderboard View Overlay
            if showingLeaderboard {
                LeaderboardView(isPresented: $showingLeaderboard, showingProfile: $showingProfile, showingSearch: $showingSearch, showingCreatePost: $showingCreatePost, showingNotifications: $showingNotifications)
                    .environmentObject(themeManager)
                    .zIndex(3)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingNotifications)
        .animation(.easeInOut(duration: 0.3), value: navigationDirection)
    }
}

// Carousel-specific bottom navigation bar for HomeView
struct CarouselBottomNavigationBar: View {
    @EnvironmentObject var themeManager: ThemeManager
    let currentPage: Int // 0=home, 1=search, 2=create, 3=leaderboard, 4=profile
    let onNavigate: (Int) -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                // Home Button
                Button(action: {}) {
                    Image(systemName: "house.fill")
                        .foregroundColor(currentPage == 0 ? .white : .gray)
                        .font(.body)
                }
                
                Spacer()
                
                // Search Button
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(currentPage == 1 ? .white : .gray)
                        .font(.body)
                }
                
                Spacer()
                
                // Create Post Button (Center)
                Button(action: {}) {
                    Image(systemName: "plus")
                        .foregroundColor(themeManager.colors.primaryBackground)
                        .font(.body)
                        .fontWeight(.bold)
                        .frame(width: 32, height: 32)
                        .background(currentPage == 2 ? Color.blue : Color.white)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Trophy Button (Leaderboard)
                Button(action: {}) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(currentPage == 3 ? .white : .gray)
                        .font(.body)
                }
                
                Spacer()
                
                // Profile Button
                Button(action: {}) {
                    Image(systemName: "person.fill")
                        .foregroundColor(currentPage == 4 ? .white : .gray)
                        .font(.body)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 14)
            .background(themeManager.colors.primaryBackground)
        }
    }
}

// Simplified navigation bar for overlay views
struct SharedBottomNavigationBar: View {
    @EnvironmentObject var themeManager: ThemeManager
    let currentPage: Int // 0=home, 1=search, 2=create, 3=leaderboard, 4=profile
    let onNavigate: (Int) -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                // Home Button
                Button(action: {}) {
                    Image(systemName: "house.fill")
                        .foregroundColor(currentPage == 0 ? .white : .gray)
                        .font(.body)
                }
                
                Spacer()
                
                // Search Button
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(currentPage == 1 ? .white : .gray)
                        .font(.body)
                }
                
                Spacer()
                
                // Create Post Button (Center)
                Button(action: {}) {
                    Image(systemName: "plus")
                        .foregroundColor(themeManager.colors.primaryBackground)
                        .font(.body)
                        .fontWeight(.bold)
                        .frame(width: 32, height: 32)
                        .background(currentPage == 2 ? Color.blue : Color.white)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Trophy Button (Leaderboard)
                Button(action: {}) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(currentPage == 3 ? .white : .gray)
                        .font(.body)
                }
                
                Spacer()
                
                // Profile Button
                Button(action: {}) {
                    Image(systemName: "person.fill")
                        .foregroundColor(currentPage == 4 ? .white : .gray)
                        .font(.body)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 14)
            .background(themeManager.colors.primaryBackground)
        }
    }
}


#Preview {
    HomeView()
        .environmentObject(ThemeManager.shared)
}
