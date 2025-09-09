//
//  LeaderboardView.swift
//  Locki
//
//  Created by Derek Hu on 8/1/25.
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    @Binding var showingProfile: Bool
    @Binding var showingSearch: Bool
    @Binding var showingCreatePost: Bool
    @Binding var showingNotifications: Bool
    @State private var sortType: LeaderboardSortType = .hours
    
    init(isPresented: Binding<Bool> = .constant(true), showingProfile: Binding<Bool> = .constant(false), showingSearch: Binding<Bool> = .constant(false), showingCreatePost: Binding<Bool> = .constant(false), showingNotifications: Binding<Bool> = .constant(false)) {
        self._isPresented = isPresented
        self._showingProfile = showingProfile
        self._showingSearch = showingSearch
        self._showingCreatePost = showingCreatePost
        self._showingNotifications = showingNotifications
    }
    
    // Sample leaderboard data
    private let users = [
        LeaderboardUser(userId: "1", username: "alex_chen", displayName: "Alex Chen", profileImage: "person.fill", totalHours: 145, dailyStreak: 12),
        LeaderboardUser(userId: "2", username: "sarah_j", displayName: "Sarah J", profileImage: "person.fill", totalHours: 132, dailyStreak: 18),
        LeaderboardUser(userId: "3", username: "mike_wilson", displayName: "Mike Wilson", profileImage: "person.fill", totalHours: 128, dailyStreak: 8),
        LeaderboardUser(userId: "4", username: "emma_davis", displayName: "Emma Davis", profileImage: "person.fill", totalHours: 119, dailyStreak: 15),
        LeaderboardUser(userId: "5", username: "john_doe", displayName: "John Doe", profileImage: "person.fill", totalHours: 108, dailyStreak: 22),
        LeaderboardUser(userId: "6", username: "lisa_park", displayName: "Lisa Park", profileImage: "person.fill", totalHours: 98, dailyStreak: 6),
        LeaderboardUser(userId: "7", username: "tom_brown", displayName: "Tom Brown", profileImage: "person.fill", totalHours: 87, dailyStreak: 11),
        LeaderboardUser(userId: "8", username: "anna_white", displayName: "Anna White", profileImage: "person.fill", totalHours: 76, dailyStreak: 9),
        LeaderboardUser(userId: "9", username: "david_lee", displayName: "David Lee", profileImage: "person.fill", totalHours: 65, dailyStreak: 14),
        LeaderboardUser(userId: "10", username: "kate_jones", displayName: "Kate Jones", profileImage: "person.fill", totalHours: 54, dailyStreak: 7)
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
        ZStack {
            // Background
            themeManager.colors.primaryBackground
                .ignoresSafeArea()
            
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
                            .foregroundColor(sortType == .hours ? themeManager.colors.primaryBackground : themeManager.colors.primaryText)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(sortType == .hours ? themeManager.colors.primaryText : Color.clear)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(themeManager.colors.primaryText, lineWidth: sortType == .hours ? 0 : 1)
                            )
                    }
                    
                    // Daily Streak Button
                    Button(action: {
                        sortType = .streak
                    }) {
                        Text("Daily Streak")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(sortType == .streak ? themeManager.colors.primaryBackground : themeManager.colors.primaryText)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(sortType == .streak ? themeManager.colors.primaryText : Color.clear)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(themeManager.colors.primaryText, lineWidth: sortType == .streak ? 0 : 1)
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
                                    showingProfile = true
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 100)
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
                        showingProfile = false
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
                        // Already on leaderboard page, do nothing
                    }) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(themeManager.colors.primaryText)
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
    }
}

struct LeaderboardRowView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let user: LeaderboardUser
    let rank: Int
    let sortType: LeaderboardSortType
    let onTap: () -> Void
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return Color.yellow // Gold
        case 2:
            return Color.gray // Silver
        case 3:
            return Color.orange // Bronze
        default:
            return Color.white
        }
    }
    
    private var statValue: String {
        switch sortType {
        case .hours:
            return "\(user.totalHours)h"
        case .streak:
            return "\(user.dailyStreak) days"
        case .weekly:
            return "\(user.weeklyHours)h"
        case .monthly:
            return "\(user.monthlyHours)h"
        }
    }
    
    private var statTitle: String {
        switch sortType {
        case .hours:
            return "Hours"
        case .streak:
            return "Daily Streak"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Rank Number
                Text("\(rank)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(rankColor)
                    .frame(width: 30)
                
                // Profile Picture
                Circle()
                    .fill(Color.gray)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: user.profileImage)
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.title3)
                    )
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.username)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.colors.primaryText)
                    
                    Text(statTitle)
                        .font(.caption)
                        .foregroundColor(themeManager.colors.secondaryText)
                }
                
                Spacer()
                
                // Stat Value
                Text(statValue)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.colors.primaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(themeManager.colors.secondaryBackground)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LeaderboardView(isPresented: .constant(true), showingProfile: .constant(false))
        .environmentObject(ThemeManager.shared)
}