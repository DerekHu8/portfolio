//
//  FirebaseService+Notifications.swift
//  Locki
//
//  Notification system and achievements
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Notification System

extension FirebaseService {
    
    func createNotification(_ notification: AppNotification) async throws {
        do {
            _ = try db.collection("notifications").addDocument(from: notification)
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getUserNotifications(limit: Int = 50) async throws -> [AppNotification] {
        do {
            let userID = try getCurrentUserID()
            
            let querySnapshot = try await db.collection("notifications")
                .whereField("userId", isEqualTo: userID)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            return try querySnapshot.documents.compactMap { document in
                try document.data(as: AppNotification.self)
            }
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func markNotificationAsRead(notificationId: String) async throws {
        do {
            try await db.collection("notifications").document(notificationId).updateData([
                "isRead": true
            ])
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func markAllNotificationsAsRead() async throws {
        do {
            let userID = try getCurrentUserID()
            
            let querySnapshot = try await db.collection("notifications")
                .whereField("userId", isEqualTo: userID)
                .whereField("isRead", isEqualTo: false)
                .getDocuments()
            
            let batch = db.batch()
            
            for document in querySnapshot.documents {
                batch.updateData(["isRead": true], forDocument: document.reference)
            }
            
            try await batch.commit()
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getUnreadNotificationCount() async throws -> Int {
        do {
            let userID = try getCurrentUserID()
            
            let querySnapshot = try await db.collection("notifications")
                .whereField("userId", isEqualTo: userID)
                .whereField("isRead", isEqualTo: false)
                .getDocuments()
            
            return querySnapshot.documents.count
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func deleteNotification(notificationId: String) async throws {
        do {
            try await db.collection("notifications").document(notificationId).delete()
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    // MARK: - Specific Notification Creators
    
    func createLikeNotification(postId: String, postOwnerId: String, likerUsername: String) async throws {
        let currentUserID = try getCurrentUserID()
        guard postOwnerId != currentUserID else { return } // Don't notify self
        
        var notification = AppNotification(
            userId: postOwnerId,
            title: "New Like",
            message: "\(likerUsername) liked your post",
            notificationType: .like
        )
        notification.relatedUserId = currentUserID
        notification.relatedUsername = likerUsername
        notification.relatedPostId = postId
        
        try await createNotification(notification)
    }
    
    func createCommentNotification(postId: String, postOwnerId: String, commenterUsername: String, commentContent: String) async throws {
        let currentUserID = try getCurrentUserID()
        guard postOwnerId != currentUserID else { return } // Don't notify self
        
        let truncatedContent = String(commentContent.prefix(50))
        var notification = AppNotification(
            userId: postOwnerId,
            title: "New Comment",
            message: "\(commenterUsername): \(truncatedContent)",
            notificationType: .comment
        )
        notification.relatedUserId = currentUserID
        notification.relatedUsername = commenterUsername
        notification.relatedPostId = postId
        
        try await createNotification(notification)
    }
    
    func createFollowNotification(followedUserId: String, followerUsername: String) async throws {
        let currentUserID = try getCurrentUserID()
        var notification = AppNotification(
            userId: followedUserId,
            title: "New Buddy Request",
            message: "\(followerUsername) wants to be your buddy",
            notificationType: .follow
        )
        notification.relatedUserId = currentUserID
        notification.relatedUsername = followerUsername
        
        try await createNotification(notification)
    }
    
    func createAchievementNotification(achievementTitle: String, achievementDescription: String) async throws {
        let userID = try getCurrentUserID()
        
        var notification = AppNotification(
            userId: userID,
            title: "Achievement Unlocked! 🏆",
            message: "\(achievementTitle): \(achievementDescription)",
            notificationType: .achievement
        )
        
        try await createNotification(notification)
    }
}

// MARK: - Achievement System

extension FirebaseService {
    
    func createAchievement(_ achievement: Achievement) async throws -> String {
        do {
            let documentRef = try db.collection("achievements").addDocument(from: achievement)
            return documentRef.documentID
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getAllAchievements() async throws -> [Achievement] {
        do {
            let querySnapshot = try await db.collection("achievements")
                .order(by: "category")
                .getDocuments()
            
            return try querySnapshot.documents.compactMap { document in
                try document.data(as: Achievement.self)
            }
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getUserAchievements() async throws -> [UserAchievement] {
        do {
            let userID = try getCurrentUserID()
            
            let querySnapshot = try await db.collection("userAchievements")
                .whereField("userId", isEqualTo: userID)
                .order(by: "unlockedDate", descending: true)
                .getDocuments()
            
            return try querySnapshot.documents.compactMap { document in
                try document.data(as: UserAchievement.self)
            }
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func updateAchievementProgress(achievementId: String, progress: Int) async throws {
        do {
            let userID = try getCurrentUserID()
            
            // Check if user achievement already exists
            let querySnapshot = try await db.collection("userAchievements")
                .whereField("userId", isEqualTo: userID)
                .whereField("achievementId", isEqualTo: achievementId)
                .limit(to: 1)
                .getDocuments()
            
            if let existingDoc = querySnapshot.documents.first {
                // Update existing progress
                try await existingDoc.reference.updateData([
                    "progress": progress
                ])
                
                // Check if achievement is completed
                let userAchievement = try existingDoc.data(as: UserAchievement.self)
                let achievement = try await getAchievement(achievementId: achievementId)
                
                if !userAchievement.isCompleted && progress >= achievement.requirement {
                    try await completeAchievement(achievementId: achievementId, userAchievementId: existingDoc.documentID)
                }
            } else {
                // Create new user achievement
                let userAchievement = UserAchievement(
                    userId: userID,
                    achievementId: achievementId,
                    progress: progress
                )
                
                let documentRef = try db.collection("userAchievements").addDocument(from: userAchievement)
                
                // Check if achievement is completed immediately
                let achievement = try await getAchievement(achievementId: achievementId)
                if progress >= achievement.requirement {
                    try await completeAchievement(achievementId: achievementId, userAchievementId: documentRef.documentID)
                }
            }
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    private func completeAchievement(achievementId: String, userAchievementId: String) async throws {
        do {
            // Mark achievement as completed
            try await db.collection("userAchievements").document(userAchievementId).updateData([
                "isCompleted": true,
                "unlockedDate": FieldValue.serverTimestamp()
            ])
            
            // Get achievement details for notification
            let achievement = try await getAchievement(achievementId: achievementId)
            
            // Create achievement notification
            try await createAchievementNotification(
                achievementTitle: achievement.title,
                achievementDescription: achievement.description
            )
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    private func getAchievement(achievementId: String) async throws -> Achievement {
        do {
            let document = try await db.collection("achievements").document(achievementId).getDocument()
            
            guard document.exists else {
                throw FirebaseError.documentNotFound
            }
            
            return try document.data(as: Achievement.self)
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    // MARK: - Achievement Checkers
    
    func checkProductivityAchievements(totalHours: Int, currentStreak: Int) async throws {
        // Check various productivity milestones
        let achievements = try await getAllAchievements()
        
        for achievement in achievements {
            switch achievement.category {
            case .productivity:
                if achievement.title.contains("Hours") {
                    try await updateAchievementProgress(achievementId: achievement.id ?? "", progress: totalHours)
                }
            case .streak:
                if achievement.title.contains("Streak") {
                    try await updateAchievementProgress(achievementId: achievement.id ?? "", progress: currentStreak)
                }
            default:
                break
            }
        }
    }
    
    func checkSocialAchievements(buddyCount: Int, totalLikes: Int, totalComments: Int) async throws {
        let achievements = try await getAllAchievements()
        
        for achievement in achievements {
            if achievement.category == .social {
                if achievement.title.contains("Buddy") || achievement.title.contains("Friend") {
                    try await updateAchievementProgress(achievementId: achievement.id ?? "", progress: buddyCount)
                } else if achievement.title.contains("Like") {
                    try await updateAchievementProgress(achievementId: achievement.id ?? "", progress: totalLikes)
                } else if achievement.title.contains("Comment") {
                    try await updateAchievementProgress(achievementId: achievement.id ?? "", progress: totalComments)
                }
            }
        }
    }
    
    func checkMilestoneAchievements(totalPosts: Int, daysActive: Int) async throws {
        let achievements = try await getAllAchievements()
        
        for achievement in achievements {
            if achievement.category == .milestone {
                if achievement.title.contains("Post") {
                    try await updateAchievementProgress(achievementId: achievement.id ?? "", progress: totalPosts)
                } else if achievement.title.contains("Day") {
                    try await updateAchievementProgress(achievementId: achievement.id ?? "", progress: daysActive)
                }
            }
        }
    }
}

// MARK: - Real-time Listeners

extension FirebaseService {
    
    func listenToNotifications(completion: @escaping ([AppNotification]) -> Void) -> ListenerRegistration {
        guard let userID = currentUserID else {
            return db.collection("notifications").addSnapshotListener { _, _ in }
        }
        
        return db.collection("notifications")
            .whereField("userId", isEqualTo: userID)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching notifications: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let notifications = documents.compactMap { document -> AppNotification? in
                    try? document.data(as: AppNotification.self)
                }
                
                DispatchQueue.main.async {
                    completion(notifications)
                }
            }
    }
    
    func listenToMessages(conversationId: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        return db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let messages = documents.compactMap { document -> Message? in
                    try? document.data(as: Message.self)
                }
                
                DispatchQueue.main.async {
                    completion(messages)
                }
            }
    }
    
    func listenToConversations(completion: @escaping ([Conversation]) -> Void) -> ListenerRegistration {
        guard let userID = currentUserID else {
            return db.collection("conversations").addSnapshotListener { _, _ in }
        }
        
        return db.collection("conversations")
            .whereField("participants", arrayContains: userID)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching conversations: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let conversations = documents.compactMap { document -> Conversation? in
                    try? document.data(as: Conversation.self)
                }
                .sorted { $0.lastMessageTimestamp > $1.lastMessageTimestamp }
                
                DispatchQueue.main.async {
                    completion(conversations)
                }
            }
    }
}

// MARK: - Analytics and Reporting

extension FirebaseService {
    
    func trackUserActivity(activityType: String, metadata: [String: Any] = [:]) async throws {
        do {
            let userID = try getCurrentUserID()
            
            var activityData: [String: Any] = [
                "userId": userID,
                "activityType": activityType,
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            // Merge metadata
            for (key, value) in metadata {
                activityData[key] = value
            }
            
            _ = try await db.collection("userActivity").addDocument(data: activityData)
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getUserActivityStats(days: Int = 30) async throws -> [String: Any] {
        do {
            let userID = try getCurrentUserID()
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            
            let querySnapshot = try await db.collection("userActivity")
                .whereField("userId", isEqualTo: userID)
                .whereField("timestamp", isGreaterThan: startDate)
                .getDocuments()
            
            var stats: [String: Any] = [
                "totalActivities": querySnapshot.documents.count,
                "activitiesByType": [String: Int](),
                "activitiesByDay": [String: Int]()
            ]
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            for document in querySnapshot.documents {
                let data = document.data()
                
                // Count by type
                if let activityType = data["activityType"] as? String {
                    var activitiesByType = stats["activitiesByType"] as? [String: Int] ?? [:]
                    activitiesByType[activityType] = (activitiesByType[activityType] ?? 0) + 1
                    stats["activitiesByType"] = activitiesByType
                }
                
                // Count by day
                if let timestamp = data["timestamp"] as? Timestamp {
                    let dateString = dateFormatter.string(from: timestamp.dateValue())
                    var activitiesByDay = stats["activitiesByDay"] as? [String: Int] ?? [:]
                    activitiesByDay[dateString] = (activitiesByDay[dateString] ?? 0) + 1
                    stats["activitiesByDay"] = activitiesByDay
                }
            }
            
            return stats
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
}