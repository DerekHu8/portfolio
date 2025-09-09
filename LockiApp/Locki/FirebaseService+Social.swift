//
//  FirebaseService+Social.swift
//  Locki
//
//  Social features: Buddies, Messaging, Leaderboards, Search
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Buddy System

extension FirebaseService {
    
    func sendBuddyRequest(to userId: String) async throws {
        do {
            let currentUserID = try getCurrentUserID()
            let currentUser = try await getCurrentUser()
            let targetUser = try await getUser(userId: userId)
            
            // Check if relationship already exists
            let existingRelationship = try await getBuddyRelationship(followerId: currentUserID, followingId: userId)
            if existingRelationship != nil {
                throw FirebaseError.unknownError("Buddy relationship already exists")
            }
            
            let buddyRelationship = BuddyRelationship(
                followerId: currentUserID,
                followerUsername: currentUser.username,
                followingId: userId,
                followingUsername: targetUser.username
            )
            
            // Add buddy relationship
            _ = try db.collection("buddyRelationships").addDocument(from: buddyRelationship)
            
            // Create notification for the target user
            var notification = AppNotification(
                userId: userId,
                title: "New Buddy Request",
                message: "\(currentUser.username) wants to be your buddy",
                notificationType: .follow
            )
            notification.relatedUserId = currentUserID
            notification.relatedUsername = currentUser.username
            
            try await createNotification(notification)
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func acceptBuddyRequest(from userId: String) async throws {
        do {
            let currentUserID = try getCurrentUserID()
            
            // Find the buddy relationship
            let querySnapshot = try await db.collection("buddyRelationships")
                .whereField("followerId", isEqualTo: userId)
                .whereField("followingId", isEqualTo: currentUserID)
                .whereField("isActive", isEqualTo: true)
                .limit(to: 1)
                .getDocuments()
            
            guard let relationshipDoc = querySnapshot.documents.first else {
                throw FirebaseError.documentNotFound
            }
            
            let batch = db.batch()
            
            // Update the existing relationship to active
            batch.updateData(["isActive": true], forDocument: relationshipDoc.reference)
            
            // Create mutual relationship
            let currentUser = try await getCurrentUser()
            let requesterUser = try await getUser(userId: userId)
            
            var mutualRelationship = BuddyRelationship(
                followerId: currentUserID,
                followerUsername: currentUser.username,
                followingId: userId,
                followingUsername: requesterUser.username
            )
            mutualRelationship.isMutual = true
            
            let mutualRef = db.collection("buddyRelationships").document()
            try batch.setData(from: mutualRelationship, forDocument: mutualRef)
            
            // Update original relationship to mutual
            batch.updateData(["isMutual": true], forDocument: relationshipDoc.reference)
            
            // Update buddy counts
            let currentUserStatsRef = db.collection("userStats").document(currentUserID)
            batch.updateData(["buddyCount": FieldValue.increment(Int64(1))], forDocument: currentUserStatsRef)
            
            let requesterStatsRef = db.collection("userStats").document(userId)
            batch.updateData(["buddyCount": FieldValue.increment(Int64(1))], forDocument: requesterStatsRef)
            
            try await batch.commit()
            
            // Create notification for the original requester
            var notification = AppNotification(
                userId: userId,
                title: "Buddy Request Accepted",
                message: "\(currentUser.username) accepted your buddy request",
                notificationType: .follow
            )
            notification.relatedUserId = currentUserID
            notification.relatedUsername = currentUser.username
            
            try await createNotification(notification)
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func removeBuddy(userId: String) async throws {
        do {
            let currentUserID = try getCurrentUserID()
            
            // Find both relationship documents
            let querySnapshot1 = try await db.collection("buddyRelationships")
                .whereField("followerId", isEqualTo: currentUserID)
                .whereField("followingId", isEqualTo: userId)
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            let querySnapshot2 = try await db.collection("buddyRelationships")
                .whereField("followerId", isEqualTo: userId)
                .whereField("followingId", isEqualTo: currentUserID)
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            let batch = db.batch()
            
            // Deactivate relationships
            for document in querySnapshot1.documents {
                batch.updateData(["isActive": false], forDocument: document.reference)
            }
            
            for document in querySnapshot2.documents {
                batch.updateData(["isActive": false], forDocument: document.reference)
            }
            
            // Update buddy counts
            let currentUserStatsRef = db.collection("userStats").document(currentUserID)
            batch.updateData(["buddyCount": FieldValue.increment(Int64(-1))], forDocument: currentUserStatsRef)
            
            let targetUserStatsRef = db.collection("userStats").document(userId)
            batch.updateData(["buddyCount": FieldValue.increment(Int64(-1))], forDocument: targetUserStatsRef)
            
            try await batch.commit()
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getBuddies(userId: String, limit: Int = 50) async throws -> [BuddyRelationship] {
        do {
            let querySnapshot = try await db.collection("buddyRelationships")
                .whereField("followerId", isEqualTo: userId)
                .whereField("isActive", isEqualTo: true)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            return try querySnapshot.documents.compactMap { document in
                try document.data(as: BuddyRelationship.self)
            }
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getBuddyIds(userId: String) async throws -> [String] {
        let buddies = try await getBuddies(userId: userId)
        return buddies.map { $0.followingId }
    }
    
    private func getBuddyRelationship(followerId: String, followingId: String) async throws -> BuddyRelationship? {
        do {
            let querySnapshot = try await db.collection("buddyRelationships")
                .whereField("followerId", isEqualTo: followerId)
                .whereField("followingId", isEqualTo: followingId)
                .whereField("isActive", isEqualTo: true)
                .limit(to: 1)
                .getDocuments()
            
            guard let document = querySnapshot.documents.first else {
                return nil
            }
            
            return try document.data(as: BuddyRelationship.self)
        } catch {
            throw handleFirestoreError(error)
        }
    }
}

// MARK: - Messaging System

extension FirebaseService {
    
    func createConversation(with userId: String) async throws -> String {
        do {
            let currentUserID = try getCurrentUserID()
            let currentUser = try await getCurrentUser()
            let targetUser = try await getUser(userId: userId)
            
            // Check if conversation already exists
            if let existingConversationId = try await getExistingConversationId(userId1: currentUserID, userId2: userId) {
                return existingConversationId
            }
            
            let conversation = Conversation(
                participants: [currentUserID, userId].sorted(),
                participantUsernames: [currentUser.username, targetUser.username]
            )
            
            let documentRef = try db.collection("conversations").addDocument(from: conversation)
            return documentRef.documentID
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func sendMessage(conversationId: String, content: String, messageType: MessageType = .text) async throws -> String {
        do {
            let currentUserID = try getCurrentUserID()
            let currentUser = try await getCurrentUser()
            
            // Get conversation to find receiver
            let conversation = try await getConversation(conversationId: conversationId)
            let receiverId = conversation.participants.first { $0 != currentUserID } ?? ""
            let receiverUsername = conversation.participantUsernames.first { $0 != currentUser.username } ?? ""
            
            let message = Message(
                conversationId: conversationId,
                senderId: currentUserID,
                senderUsername: currentUser.username,
                receiverId: receiverId,
                receiverUsername: receiverUsername,
                content: content,
                messageType: messageType
            )
            
            let batch = db.batch()
            
            // Add message
            let messageRef = db.collection("messages").document()
            try batch.setData(from: message, forDocument: messageRef)
            
            // Update conversation with last message
            let conversationRef = db.collection("conversations").document(conversationId)
            batch.updateData([
                "lastMessage": content,
                "lastMessageTimestamp": FieldValue.serverTimestamp(),
                "lastMessageSenderId": currentUserID,
                "unreadCount.\(receiverId)": FieldValue.increment(Int64(1))
            ], forDocument: conversationRef)
            
            try await batch.commit()
            
            // Create notification
            var notification = AppNotification(
                userId: receiverId,
                title: "New Message",
                message: "\(currentUser.username): \(content)",
                notificationType: .message
            )
            notification.relatedUserId = currentUserID
            notification.relatedUsername = currentUser.username
            
            try await createNotification(notification)
            
            return messageRef.documentID
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getConversations(limit: Int = 50) async throws -> [Conversation] {
        do {
            let currentUserID = try getCurrentUserID()
            
            let querySnapshot = try await db.collection("conversations")
                .whereField("participants", arrayContains: currentUserID)
                .whereField("isActive", isEqualTo: true)
                .limit(to: limit)
                .getDocuments()
            
            return try querySnapshot.documents.compactMap { document in
                try document.data(as: Conversation.self)
            }
            .sorted { $0.lastMessageTimestamp > $1.lastMessageTimestamp }
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getMessages(conversationId: String, limit: Int = 50, lastDocument: DocumentSnapshot? = nil) async throws -> (messages: [Message], lastDocument: DocumentSnapshot?) {
        do {
            var query = db.collection("messages")
                .whereField("conversationId", isEqualTo: conversationId)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
            
            if let lastDocument = lastDocument {
                query = query.start(afterDocument: lastDocument)
            }
            
            let querySnapshot = try await query.getDocuments()
            
            let messages = try querySnapshot.documents.compactMap { document in
                try document.data(as: Message.self)
            }
            
            return (messages: messages.reversed(), lastDocument: querySnapshot.documents.last)
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func markMessagesAsRead(conversationId: String) async throws {
        do {
            let currentUserID = try getCurrentUserID()
            
            // Mark messages as read
            let messagesQuery = try await db.collection("messages")
                .whereField("conversationId", isEqualTo: conversationId)
                .whereField("receiverId", isEqualTo: currentUserID)
                .whereField("isRead", isEqualTo: false)
                .getDocuments()
            
            let batch = db.batch()
            
            for document in messagesQuery.documents {
                batch.updateData(["isRead": true], forDocument: document.reference)
            }
            
            // Reset unread count in conversation
            let conversationRef = db.collection("conversations").document(conversationId)
            batch.updateData(["unreadCount.\(currentUserID)": 0], forDocument: conversationRef)
            
            try await batch.commit()
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    private func getConversation(conversationId: String) async throws -> Conversation {
        do {
            let document = try await db.collection("conversations").document(conversationId).getDocument()
            
            guard document.exists else {
                throw FirebaseError.documentNotFound
            }
            
            return try document.data(as: Conversation.self)
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    private func getExistingConversationId(userId1: String, userId2: String) async throws -> String? {
        do {
            let querySnapshot = try await db.collection("conversations")
                .whereField("participants", arrayContains: userId1)
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            for document in querySnapshot.documents {
                let conversation = try document.data(as: Conversation.self)
                if conversation.participants.contains(userId2) {
                    return document.documentID
                }
            }
            
            return nil
        } catch {
            throw handleFirestoreError(error)
        }
    }
}

// MARK: - Leaderboard System

extension FirebaseService {
    
    func getLeaderboard(sortType: LeaderboardSortType, limit: Int = 50) async throws -> [LeaderboardUser] {
        do {
            var orderField: String
            
            switch sortType {
            case .hours:
                orderField = "totalHours"
            case .streak:
                orderField = "currentStreak"
            case .weekly:
                orderField = "weeklyHours"
            case .monthly:
                orderField = "monthlyHours"
            }
            
            let querySnapshot = try await db.collection("userStats")
                .order(by: orderField, descending: true)
                .limit(to: limit)
                .getDocuments()
            
            var leaderboardUsers: [LeaderboardUser] = []
            
            for (index, document) in querySnapshot.documents.enumerated() {
                let userStats = try document.data(as: UserStats.self)
                let user = try await getUser(userId: userStats.userId)
                
                var leaderboardUser = LeaderboardUser(
                    userId: userStats.userId,
                    username: user.username,
                    displayName: user.displayName,
                    profileImage: "person.fill", // You can enhance this with actual profile images
                    totalHours: userStats.totalHours,
                    dailyStreak: userStats.currentStreak
                )
                leaderboardUser.rank = index + 1
                leaderboardUser.weeklyHours = getCurrentWeekHours(from: userStats.weeklyHours)
                leaderboardUser.monthlyHours = getCurrentMonthHours(from: userStats.monthlyHours)
                leaderboardUser.isVerified = user.isVerified
                
                leaderboardUsers.append(leaderboardUser)
            }
            
            return leaderboardUsers
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getUserRank(userId: String, sortType: LeaderboardSortType) async throws -> Int {
        do {
            let userStats = try await getUserStats(userId: userId)
            
            var orderField: String
            var userValue: Int
            
            switch sortType {
            case .hours:
                orderField = "totalHours"
                userValue = userStats.totalHours
            case .streak:
                orderField = "currentStreak"
                userValue = userStats.currentStreak
            case .weekly:
                orderField = "weeklyHours"
                userValue = getCurrentWeekHours(from: userStats.weeklyHours)
            case .monthly:
                orderField = "monthlyHours"
                userValue = getCurrentMonthHours(from: userStats.monthlyHours)
            }
            
            let querySnapshot = try await db.collection("userStats")
                .whereField(orderField, isGreaterThan: userValue)
                .getDocuments()
            
            return querySnapshot.documents.count + 1
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    private func getCurrentWeekHours(from weeklyHours: [String: Int]) -> Int {
        let calendar = Calendar.current
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let weekKey = formatter.string(from: weekEnd)
        
        return weeklyHours[weekKey] ?? 0
    }
    
    private func getCurrentMonthHours(from monthlyHours: [String: Int]) -> Int {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let year = calendar.component(.year, from: Date())
        let monthKey = "\(year)-\(String(format: "%02d", month))"
        
        return monthlyHours[monthKey] ?? 0
    }
}

// MARK: - Search System

extension FirebaseService {
    
    func searchUsers(query: String, limit: Int = 20) async throws -> [SearchResult] {
        do {
            let lowercaseQuery = query.lowercased()
            
            // Search by username
            let usernameQuery = try await db.collection("users")
                .whereField("username", isGreaterThanOrEqualTo: lowercaseQuery)
                .whereField("username", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
                .whereField("isActive", isEqualTo: true)
                .limit(to: limit)
                .getDocuments()
            
            // Search by display name
            let displayNameQuery = try await db.collection("users")
                .whereField("displayName", isGreaterThanOrEqualTo: lowercaseQuery)
                .whereField("displayName", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
                .whereField("isActive", isEqualTo: true)
                .limit(to: limit)
                .getDocuments()
            
            var searchResults: [SearchResult] = []
            var seenUserIds = Set<String>()
            
            // Process username results
            for document in usernameQuery.documents {
                let user = try document.data(as: User.self)
                if let userId = user.id, !seenUserIds.contains(userId) {
                    seenUserIds.insert(userId)
                    
                    let result = SearchResult(
                        type: .user,
                        userId: userId,
                        username: user.username,
                        displayName: user.displayName,
                        relevanceScore: calculateRelevanceScore(query: query, username: user.username, displayName: user.displayName)
                    )
                    searchResults.append(result)
                }
            }
            
            // Process display name results
            for document in displayNameQuery.documents {
                let user = try document.data(as: User.self)
                if let userId = user.id, !seenUserIds.contains(userId) {
                    seenUserIds.insert(userId)
                    
                    let result = SearchResult(
                        type: .user,
                        userId: userId,
                        username: user.username,
                        displayName: user.displayName,
                        relevanceScore: calculateRelevanceScore(query: query, username: user.username, displayName: user.displayName)
                    )
                    searchResults.append(result)
                }
            }
            
            // Sort by relevance and return limited results
            return Array(searchResults.sorted { $0.relevanceScore > $1.relevanceScore }.prefix(limit))
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func searchPosts(query: String, limit: Int = 20) async throws -> [SearchResult] {
        do {
            let lowercaseQuery = query.lowercased()
            
            // Search by title
            let titleQuery = try await db.collection("posts")
                .whereField("title", isGreaterThanOrEqualTo: lowercaseQuery)
                .whereField("title", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
                .whereField("isActive", isEqualTo: true)
                .whereField("visibility", isEqualTo: PostVisibility.publicPost.rawValue)
                .limit(to: limit)
                .getDocuments()
            
            var searchResults: [SearchResult] = []
            
            for document in titleQuery.documents {
                let post = try document.data(as: Post.self)
                
                let result = SearchResult(
                    type: .post,
                    postId: post.id,
                    postTitle: post.title,
                    relevanceScore: calculatePostRelevanceScore(query: query, title: post.title, description: post.description)
                )
                searchResults.append(result)
            }
            
            return searchResults.sorted { $0.relevanceScore > $1.relevanceScore }
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func searchUsersForProfiles(query: String, limit: Int = 10) async throws -> [User] {
        do {
            let lowercaseQuery = query.lowercased()
            
            // Search by username
            let usernameQuery = try await db.collection("users")
                .whereField("username", isGreaterThanOrEqualTo: lowercaseQuery)
                .whereField("username", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
                .whereField("isActive", isEqualTo: true)
                .limit(to: limit)
                .getDocuments()
            
            // Search by display name
            let displayNameQuery = try await db.collection("users")
                .whereField("displayName", isGreaterThanOrEqualTo: lowercaseQuery)
                .whereField("displayName", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
                .whereField("isActive", isEqualTo: true)
                .limit(to: limit)
                .getDocuments()
            
            var users: [User] = []
            var seenUserIds = Set<String>()
            
            // Process username results
            for document in usernameQuery.documents {
                let user = try document.data(as: User.self)
                if let userId = user.id, !seenUserIds.contains(userId) {
                    seenUserIds.insert(userId)
                    users.append(user)
                }
            }
            
            // Process display name results
            for document in displayNameQuery.documents {
                let user = try document.data(as: User.self)
                if let userId = user.id, !seenUserIds.contains(userId) {
                    seenUserIds.insert(userId)
                    users.append(user)
                }
            }
            
            // Sort by relevance (username matches first, then display name matches)
            return users.sorted { user1, user2 in
                let score1 = calculateRelevanceScore(query: query, username: user1.username, displayName: user1.displayName)
                let score2 = calculateRelevanceScore(query: query, username: user2.username, displayName: user2.displayName)
                return score1 > score2
            }
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func saveSearchHistory(query: String, resultType: SearchResultType?) async throws {
        do {
            let userID = try getCurrentUserID()
            
            let searchHistory = SearchHistory(
                userId: userID,
                searchTerm: query,
                resultType: resultType
            )
            
            _ = try db.collection("searchHistory").addDocument(from: searchHistory)
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getSearchHistory(limit: Int = 10) async throws -> [SearchHistory] {
        do {
            let userID = try getCurrentUserID()
            
            let querySnapshot = try await db.collection("searchHistory")
                .whereField("userId", isEqualTo: userID)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            return try querySnapshot.documents.compactMap { document in
                try document.data(as: SearchHistory.self)
            }
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    private func calculateRelevanceScore(query: String, username: String, displayName: String) -> Double {
        let lowercaseQuery = query.lowercased()
        let lowercaseUsername = username.lowercased()
        let lowercaseDisplayName = displayName.lowercased()
        
        var score = 0.0
        
        // Exact matches get highest score
        if lowercaseUsername == lowercaseQuery {
            score += 100.0
        } else if lowercaseDisplayName == lowercaseQuery {
            score += 90.0
        }
        // Prefix matches
        else if lowercaseUsername.hasPrefix(lowercaseQuery) {
            score += 80.0
        } else if lowercaseDisplayName.hasPrefix(lowercaseQuery) {
            score += 70.0
        }
        // Contains matches
        else if lowercaseUsername.contains(lowercaseQuery) {
            score += 60.0
        } else if lowercaseDisplayName.contains(lowercaseQuery) {
            score += 50.0
        }
        
        return score
    }
    
    private func calculatePostRelevanceScore(query: String, title: String, description: String) -> Double {
        let lowercaseQuery = query.lowercased()
        let lowercaseTitle = title.lowercased()
        let lowercaseDescription = description.lowercased()
        
        var score = 0.0
        
        // Title matches are more important
        if lowercaseTitle.contains(lowercaseQuery) {
            score += 80.0
        }
        
        if lowercaseDescription.contains(lowercaseQuery) {
            score += 40.0
        }
        
        return score
    }
}