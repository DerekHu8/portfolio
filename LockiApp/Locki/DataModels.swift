//
//  DataModels.swift
//  Locki
//
//  Created for comprehensive data modeling
//

import Foundation
import FirebaseFirestore

// MARK: - User & Profile Models

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var displayName: String
    var profession: String
    var bio: String
    var profilePictureData: Data?
    var email: String?
    var isVerified: Bool
    var joinDate: Date
    var lastActiveDate: Date
    var isActive: Bool
    
    // Privacy & Settings
    var isProfilePublic: Bool
    var allowsMessages: Bool
    var notificationsEnabled: Bool
    
    init(username: String, displayName: String, profession: String = "", bio: String = "", email: String? = nil) {
        self.username = username
        self.displayName = displayName
        self.profession = profession
        self.bio = bio
        self.email = email
        self.isVerified = false
        self.joinDate = Date()
        self.lastActiveDate = Date()
        self.isActive = true
        self.isProfilePublic = true
        self.allowsMessages = true
        self.notificationsEnabled = true
    }
}

struct UserStats: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var totalHours: Int
    var totalMinutes: Int
    var currentStreak: Int
    var longestStreak: Int
    var totalPosts: Int
    var totalLikes: Int
    var totalComments: Int
    var buddyCount: Int
    var lastPostDate: Date?
    var lastActivityDate: Date
    var weeklyHours: [String: Int] // Week ending date -> hours
    var monthlyHours: [String: Int] // Month -> hours
    
    init(userId: String) {
        self.userId = userId
        self.totalHours = 0
        self.totalMinutes = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalPosts = 0
        self.totalLikes = 0
        self.totalComments = 0
        self.buddyCount = 0
        self.lastActivityDate = Date()
        self.weeklyHours = [:]
        self.monthlyHours = [:]
    }
}

// MARK: - Post Models

struct Post: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var username: String
    var title: String
    var description: String
    var hours: String
    var minutes: String
    var imageData: Data?
    var timestamp: Date
    var isActive: Bool
    var likeCount: Int
    var commentCount: Int
    var shareCount: Int
    var isLikedByUser: Bool
    var tags: [String]
    var location: String?
    var visibility: PostVisibility
    
    init(userId: String, username: String, title: String, description: String, hours: String, minutes: String, imageData: Data? = nil) {
        self.userId = userId
        self.username = username
        self.title = title
        self.description = description
        self.hours = hours
        self.minutes = minutes
        self.imageData = imageData
        self.timestamp = Date()
        self.isActive = true
        self.likeCount = 0
        self.commentCount = 0
        self.shareCount = 0
        self.isLikedByUser = false
        self.tags = []
        self.visibility = .publicPost
    }
}

enum PostVisibility: String, Codable, CaseIterable {
    case publicPost = "public"
    case buddiesOnly = "buddies_only"
    case privatePost = "private"
}

struct PostLike: Identifiable, Codable {
    @DocumentID var id: String?
    var postId: String
    var userId: String
    var username: String
    var timestamp: Date
    
    init(postId: String, userId: String, username: String) {
        self.postId = postId
        self.userId = userId
        self.username = username
        self.timestamp = Date()
    }
}

struct PostComment: Identifiable, Codable {
    @DocumentID var id: String?
    var postId: String
    var userId: String
    var username: String
    var content: String
    var timestamp: Date
    var likeCount: Int
    var isActive: Bool
    
    init(postId: String, userId: String, username: String, content: String) {
        self.postId = postId
        self.userId = userId
        self.username = username
        self.content = content
        self.timestamp = Date()
        self.likeCount = 0
        self.isActive = true
    }
}

// MARK: - Leaderboard Models

struct LeaderboardUser: Identifiable, Codable {
    var id = UUID()
    var userId: String
    var username: String
    var displayName: String
    var profileImage: String
    var totalHours: Int
    var dailyStreak: Int
    var weeklyHours: Int
    var monthlyHours: Int
    var rank: Int?
    var isVerified: Bool
    
    init(userId: String, username: String, displayName: String, profileImage: String, totalHours: Int, dailyStreak: Int) {
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.profileImage = profileImage
        self.totalHours = totalHours
        self.dailyStreak = dailyStreak
        self.weeklyHours = 0
        self.monthlyHours = 0
        self.isVerified = false
    }
}

enum LeaderboardSortType: String, CaseIterable {
    case hours = "hours"
    case streak = "streak"
    case weekly = "weekly"
    case monthly = "monthly"
}

// MARK: - Messaging Models

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var conversationId: String
    var senderId: String
    var senderUsername: String
    var receiverId: String
    var receiverUsername: String
    var content: String
    var messageType: MessageType
    var timestamp: Date
    var isRead: Bool
    var isDelivered: Bool
    var attachmentData: Data?
    var attachmentType: AttachmentType?
    
    init(conversationId: String, senderId: String, senderUsername: String, receiverId: String, receiverUsername: String, content: String, messageType: MessageType = .text) {
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderUsername = senderUsername
        self.receiverId = receiverId
        self.receiverUsername = receiverUsername
        self.content = content
        self.messageType = messageType
        self.timestamp = Date()
        self.isRead = false
        self.isDelivered = false
    }
}

enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case post = "post"
    case system = "system"
}

enum AttachmentType: String, Codable {
    case image = "image"
    case gif = "gif"
}

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    var participants: [String] // User IDs
    var participantUsernames: [String]
    var lastMessage: String
    var lastMessageTimestamp: Date
    var lastMessageSenderId: String
    var isActive: Bool
    var unreadCount: [String: Int] // UserId -> unread count
    
    init(participants: [String], participantUsernames: [String]) {
        self.participants = participants
        self.participantUsernames = participantUsernames
        self.lastMessage = ""
        self.lastMessageTimestamp = Date()
        self.lastMessageSenderId = ""
        self.isActive = true
        self.unreadCount = [:]
    }
}

// MARK: - Notification Models

struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var message: String
    var notificationType: NotificationType
    var relatedUserId: String?
    var relatedUsername: String?
    var relatedPostId: String?
    var timestamp: Date
    var isRead: Bool
    var actionData: [String: String]? // Additional data for actions
    
    init(userId: String, title: String, message: String, notificationType: NotificationType) {
        self.userId = userId
        self.title = title
        self.message = message
        self.notificationType = notificationType
        self.timestamp = Date()
        self.isRead = false
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case like = "like"
    case comment = "comment"
    case follow = "follow"
    case message = "message"
    case achievement = "achievement"
    case reminder = "reminder"
    case system = "system"
    case buddyRequest = "buddyRequest"
    case post = "post"
}

// MARK: - Buddy/Follow Models

struct BuddyRelationship: Identifiable, Codable {
    @DocumentID var id: String?
    var followerId: String
    var followerUsername: String
    var followingId: String
    var followingUsername: String
    var timestamp: Date
    var isActive: Bool
    var isMutual: Bool
    
    init(followerId: String, followerUsername: String, followingId: String, followingUsername: String) {
        self.followerId = followerId
        self.followerUsername = followerUsername
        self.followingId = followingId
        self.followingUsername = followingUsername
        self.timestamp = Date()
        self.isActive = true
        self.isMutual = false
    }
}

// MARK: - Search Models

struct SearchResult: Identifiable {
    var id = UUID()
    var type: SearchResultType
    var userId: String?
    var username: String?
    var displayName: String?
    var postId: String?
    var postTitle: String?
    var relevanceScore: Double
    
    init(type: SearchResultType, userId: String? = nil, username: String? = nil, displayName: String? = nil, postId: String? = nil, postTitle: String? = nil, relevanceScore: Double = 0.0) {
        self.type = type
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.postId = postId
        self.postTitle = postTitle
        self.relevanceScore = relevanceScore
    }
}

enum SearchResultType: String, Codable, CaseIterable {
    case user = "user"
    case post = "post"
    case tag = "tag"
}

struct SearchHistory: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var searchTerm: String
    var timestamp: Date
    var resultType: SearchResultType?
    
    init(userId: String, searchTerm: String, resultType: SearchResultType? = nil) {
        self.userId = userId
        self.searchTerm = searchTerm
        self.timestamp = Date()
        self.resultType = resultType
    }
}

// MARK: - Achievement Models

struct Achievement: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var iconName: String
    var category: AchievementCategory
    var requirement: Int
    var isSecret: Bool
    var points: Int
    
    init(title: String, description: String, iconName: String, category: AchievementCategory, requirement: Int, points: Int = 10) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.category = category
        self.requirement = requirement
        self.isSecret = false
        self.points = points
    }
}

struct UserAchievement: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var achievementId: String
    var unlockedDate: Date
    var progress: Int
    var isCompleted: Bool
    
    init(userId: String, achievementId: String, progress: Int = 0) {
        self.userId = userId
        self.achievementId = achievementId
        self.progress = progress
        self.isCompleted = false
        self.unlockedDate = Date()
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case productivity = "productivity"
    case social = "social"
    case streak = "streak"
    case time = "time"
    case milestone = "milestone"
}

// MARK: - Settings Models

struct UserSettings: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    
    // Notification Settings
    var pushNotificationsEnabled: Bool
    var emailNotificationsEnabled: Bool
    var likeNotifications: Bool
    var commentNotifications: Bool
    var followNotifications: Bool
    var messageNotifications: Bool
    var achievementNotifications: Bool
    
    // Privacy Settings
    var profileVisibility: ProfileVisibility
    var showOnlineStatus: Bool
    var allowSearchByEmail: Bool
    var allowSearchByUsername: Bool
    
    // App Settings
    var theme: AppTheme
    var language: String
    var autoSaveEnabled: Bool
    var dataUsageMode: DataUsageMode
    
    init(userId: String) {
        self.userId = userId
        self.pushNotificationsEnabled = true
        self.emailNotificationsEnabled = true
        self.likeNotifications = true
        self.commentNotifications = true
        self.followNotifications = true
        self.messageNotifications = true
        self.achievementNotifications = true
        self.profileVisibility = .publicProfile
        self.showOnlineStatus = true
        self.allowSearchByEmail = true
        self.allowSearchByUsername = true
        self.theme = .dark
        self.language = "en"
        self.autoSaveEnabled = true
        self.dataUsageMode = .normal
    }
}

enum ProfileVisibility: String, Codable, CaseIterable {
    case publicProfile = "public"
    case buddiesOnly = "buddies_only"
    case privateProfile = "private"
}

enum AppTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
}

enum DataUsageMode: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
}