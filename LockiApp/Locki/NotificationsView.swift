//
//  NotificationsView.swift
//  Locki
//
//  Created by Derek Hu on 7/31/25.
//

import SwiftUI
import FirebaseFirestore

struct NotificationItem {
    let id = UUID()
    let type: NotificationType
    let username: String
    let message: String
    let timestamp: String
    let isRead: Bool
    
    init(type: NotificationType, username: String, message: String, timestamp: String, isRead: Bool) {
        self.type = type
        self.username = username
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
    }
    
    var icon: String {
        switch type {
        case .follow:
            return "person.badge.plus"
        case .like:
            return "heart.fill"
        case .comment:
            return "message.fill"
        case .message:
            return "envelope.fill"
        case .achievement:
            return "trophy.fill"
        case .reminder:
            return "bell.fill"
        case .system:
            return "info.circle.fill"
        case .buddyRequest:
            return "person.badge.plus"
        case .post:
            return "doc.text.fill"
        }
    }
    
    var iconColor: Color {
        switch type {
        case .follow:
            return .blue
        case .like:
            return .red
        case .comment:
            return .green
        case .message:
            return .purple
        case .achievement:
            return .yellow
        case .reminder:
            return .orange
        case .system:
            return .gray
        case .buddyRequest:
            return .blue
        case .post:
            return .cyan
        }
    }
}

struct NotificationsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    @Binding var showingSearch: Bool
    @Binding var showingProfile: Bool
    @Binding var showingCreatePost: Bool
    @Binding var showingLeaderboard: Bool
    
    // Firebase integration
    @State private var notifications: [NotificationItem] = []
    @State private var isLoading = true
    @State private var notificationListener: ListenerRegistration?
    
    init(isPresented: Binding<Bool> = .constant(true), showingSearch: Binding<Bool> = .constant(false), showingProfile: Binding<Bool> = .constant(false), showingCreatePost: Binding<Bool> = .constant(false), showingLeaderboard: Binding<Bool> = .constant(false)) {
        self._isPresented = isPresented
        self._showingSearch = showingSearch
        self._showingProfile = showingProfile
        self._showingCreatePost = showingCreatePost
        self._showingLeaderboard = showingLeaderboard
    }
    
    // MARK: - Firebase Integration Functions
    
    private func loadNotifications() {
        Task {
            do {
                let appNotifications = try await FirebaseService.shared.getUserNotifications()
                let notificationItems = appNotifications.map { convertToNotificationItem($0) }
                
                DispatchQueue.main.async {
                    self.notifications = notificationItems
                    self.isLoading = false
                }
            } catch {
                print("Error loading notifications: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func setupNotificationListener() {
        notificationListener = FirebaseService.shared.listenToNotifications { appNotifications in
            let notificationItems = appNotifications.map { self.convertToNotificationItem($0) }
            self.notifications = notificationItems
            self.isLoading = false
        }
    }
    
    private func convertToNotificationItem(_ appNotification: AppNotification) -> NotificationItem {
        let timeAgo = formatTimeAgo(from: appNotification.timestamp)
        
        return NotificationItem(
            type: appNotification.notificationType,
            username: appNotification.relatedUsername ?? "Unknown",
            message: appNotification.message,
            timestamp: timeAgo,
            isRead: appNotification.isRead
        )
    }
    
    private func formatTimeAgo(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "\(Int(timeInterval))s"
        } else if timeInterval < 3600 {
            return "\(Int(timeInterval / 60))m"
        } else if timeInterval < 86400 {
            return "\(Int(timeInterval / 3600))h"
        } else {
            return "\(Int(timeInterval / 86400))d"
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            themeManager.colors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header
                HStack(spacing: 12) {
                    // Back Button
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                    
                    // Bell Icon
                    Image(systemName: "bell.fill")
                        .foregroundColor(themeManager.colors.primaryText)
                        .font(.title2)
                    
                    // Notifications Title
                    Text("Notifications")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.colors.primaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Notifications List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if isLoading {
                            // Loading indicator
                            VStack(spacing: 16) {
                                ProgressView()
                                    .tint(themeManager.colors.primaryText)
                                
                                Text("Loading notifications...")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.colors.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                        } else if notifications.isEmpty {
                            // Empty state
                            Text("No notifications to view right now")
                                .font(.subheadline)
                                .foregroundColor(themeManager.colors.secondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 50)
                        } else {
                            // Notifications list
                            ForEach(notifications, id: \.id) { notification in
                                NotificationRowView(notification: notification)
                                    .padding(.horizontal, 20)
                                    .onTapGesture {
                                        // Mark notification as read when tapped
                                        markNotificationAsRead(notification)
                                    }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            setupNotificationListener()
        }
        .onDisappear {
            notificationListener?.remove()
        }
    }
    
    // MARK: - Helper Functions
    
    private func markNotificationAsRead(_ notification: NotificationItem) {
        if !notification.isRead {
            // Update locally first for instant feedback
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = NotificationItem(
                    type: notification.type,
                    username: notification.username,
                    message: notification.message,
                    timestamp: notification.timestamp,
                    isRead: true
                )
            }
            
            // Note: In a full implementation, you would need to track the Firebase notification ID
            // and call FirebaseService.shared.markNotificationAsRead(notificationId: id)
            // For now, this provides the UI feedback
        }
    }
}

struct NotificationRowView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let notification: NotificationItem
    
    var body: some View {
        HStack(spacing: 8) {
            // Unread Indicator (Left side)
            HStack {
                if !notification.isRead {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                } else {
                    // Invisible spacer to maintain alignment
                    Circle()
                        .fill(.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 6)
            
            // Notification Type Icon
            ZStack {
                Circle()
                    .fill(notification.iconColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: notification.icon)
                    .foregroundColor(notification.iconColor)
                    .font(.title3)
            }
            
            // Notification Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.username)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.colors.primaryText)
                    
                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.secondaryText)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Timestamp aligned to the right
                    Text(notification.timestamp)
                        .font(.caption)
                        .foregroundColor(themeManager.colors.secondaryText.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(notification.isRead ? Color.clear : themeManager.colors.secondaryBackground.opacity(0.3))
        )
        .overlay(
            // Bottom divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
                .padding(.leading, 66), // Align with text content
            alignment: .bottom
        )
    }
}

#Preview {
    NotificationsView(isPresented: .constant(true))
        .environmentObject(ThemeManager.shared)
}
