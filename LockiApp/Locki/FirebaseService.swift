//
//  FirebaseService.swift
//  Locki
//
//  Firebase service layer for all database operations
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import Combine

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    internal let db = Firestore.firestore()
    internal let storage = Storage.storage()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Error Handling
    
    enum FirebaseError: Error, LocalizedError {
        case userNotAuthenticated
        case dataEncodingError
        case dataDecodingError
        case documentNotFound
        case insufficientPermissions
        case networkError
        case unknownError(String)
        
        var errorDescription: String? {
            switch self {
            case .userNotAuthenticated:
                return "User is not authenticated"
            case .dataEncodingError:
                return "Failed to encode data"
            case .dataDecodingError:
                return "Failed to decode data"
            case .documentNotFound:
                return "Document not found"
            case .insufficientPermissions:
                return "Insufficient permissions"
            case .networkError:
                return "Network error occurred"
            case .unknownError(let message):
                return message
            }
        }
    }
    
    // MARK: - Helper Methods
    
    internal func getCurrentUserID() throws -> String {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw FirebaseError.userNotAuthenticated
        }
        return userID
    }
    
    internal func handleFirestoreError(_ error: Error) -> FirebaseError {
        let nsError = error as NSError
        
        switch nsError.code {
        case FirestoreErrorCode.permissionDenied.rawValue:
            return .insufficientPermissions
        case FirestoreErrorCode.notFound.rawValue:
            return .documentNotFound
        case FirestoreErrorCode.unavailable.rawValue,
             FirestoreErrorCode.deadlineExceeded.rawValue:
            return .networkError
        default:
            return .unknownError(error.localizedDescription)
        }
    }
}

// MARK: - User Management

extension FirebaseService {
    
    func createUser(_ user: User) async throws {
        do {
            let userID = try getCurrentUserID()
            var userToSave = user
            userToSave.id = userID
            
            try db.collection("users").document(userID).setData(from: userToSave)
            
            // Create associated user stats
            let userStats = UserStats(userId: userID)
            try db.collection("userStats").document(userID).setData(from: userStats)
            
            // Create user settings
            let userSettings = UserSettings(userId: userID)
            try db.collection("userSettings").document(userID).setData(from: userSettings)
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getUser(userId: String) async throws -> User {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            guard document.exists else {
                throw FirebaseError.documentNotFound
            }
            
            return try document.data(as: User.self)
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getCurrentUser() async throws -> User {
        let userID = try getCurrentUserID()
        return try await getUser(userId: userID)
    }
    
    func updateUser(_ user: User) async throws {
        do {
            let userID = try getCurrentUserID()
            try db.collection("users").document(userID).setData(from: user, merge: true)
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func updateUserStats(_ stats: UserStats) async throws {
        do {
            let userID = try getCurrentUserID()
            try db.collection("userStats").document(userID).setData(from: stats, merge: true)
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getUserStats(userId: String) async throws -> UserStats {
        do {
            let document = try await db.collection("userStats").document(userId).getDocument()
            
            guard document.exists else {
                throw FirebaseError.documentNotFound
            }
            
            return try document.data(as: UserStats.self)
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func updateUserSettings(_ settings: UserSettings) async throws {
        do {
            let userID = try getCurrentUserID()
            try db.collection("userSettings").document(userID).setData(from: settings, merge: true)
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getUserSettings() async throws -> UserSettings {
        do {
            let userID = try getCurrentUserID()
            let document = try await db.collection("userSettings").document(userID).getDocument()
            
            guard document.exists else {
                // Return default settings if none exist
                return UserSettings(userId: userID)
            }
            
            return try document.data(as: UserSettings.self)
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func uploadProfileImage(_ imageData: Data) async throws -> String {
        do {
            let userID = try getCurrentUserID()
            let imageRef = storage.reference().child("profile_images/\(userID).jpg")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            _ = try await imageRef.putData(imageData, metadata: metadata)
            let downloadURL = try await imageRef.downloadURL()
            
            return downloadURL.absoluteString
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
    }
}

// MARK: - Post Management

extension FirebaseService {
    
    func createPost(_ post: Post) async throws -> String {
        do {
            let userID = try getCurrentUserID()
            var postToSave = post
            postToSave.userId = userID
            
            // Upload image if present
            if let imageData = post.imageData {
                let imageURL = try await uploadPostImage(imageData)
                postToSave.imageData = nil // Don't store raw data
                // You might want to add an imageURL field to your Post model
            }
            
            let documentRef = try db.collection("posts").addDocument(from: postToSave)
            
            // Update user stats
            try await incrementUserPostCount()
            try await updateUserProductivityHours(hours: Int(post.hours) ?? 0, minutes: Int(post.minutes) ?? 0)
            
            return documentRef.documentID
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getPost(postId: String) async throws -> Post {
        do {
            let document = try await db.collection("posts").document(postId).getDocument()
            
            guard document.exists else {
                throw FirebaseError.documentNotFound
            }
            
            return try document.data(as: Post.self)
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getUserPosts(userId: String, limit: Int = 20) async throws -> [Post] {
        do {
            let querySnapshot = try await db.collection("posts")
                .whereField("userId", isEqualTo: userId)
                .whereField("isActive", isEqualTo: true)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            return try querySnapshot.documents.compactMap { document in
                try document.data(as: Post.self)
            }
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getFeedPosts(limit: Int = 20) async throws -> [Post] {
        do {
            let userID = try getCurrentUserID()
            
            // Get user's buddy list
            let buddyIds = try await getBuddyIds(userId: userID)
            var allUserIds = buddyIds
            allUserIds.append(userID) // Include user's own posts
            
            // Firestore 'in' queries are limited to 10 items, so we might need to batch this
            let batchSize = 10
            var allPosts: [Post] = []
            
            for i in stride(from: 0, to: allUserIds.count, by: batchSize) {
                let endIndex = min(i + batchSize, allUserIds.count)
                let batch = Array(allUserIds[i..<endIndex])
                
                let querySnapshot = try await db.collection("posts")
                    .whereField("userId", in: batch)
                    .whereField("isActive", isEqualTo: true)
                    .limit(to: limit * 2) // Get more to filter locally
                    .getDocuments()
                
                let posts = try querySnapshot.documents.compactMap { document in
                    try document.data(as: Post.self)
                }
                .filter { post in
                    // Filter by visibility locally to avoid composite index
                    post.visibility == .publicPost || post.visibility == .buddiesOnly
                }
                
                allPosts.append(contentsOf: posts)
            }
            
            // Sort all posts by timestamp and return limited results
            return Array(allPosts.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func updatePost(_ post: Post) async throws {
        do {
            guard let postId = post.id else {
                throw FirebaseError.documentNotFound
            }
            
            try db.collection("posts").document(postId).setData(from: post, merge: true)
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func deletePost(postId: String) async throws {
        do {
            // Soft delete by setting isActive to false
            try await db.collection("posts").document(postId).updateData([
                "isActive": false
            ])
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func uploadPostImage(_ imageData: Data) async throws -> String {
        do {
            let userID = try getCurrentUserID()
            let imageId = UUID().uuidString
            let imageRef = storage.reference().child("post_images/\(userID)/\(imageId).jpg")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            _ = try await imageRef.putData(imageData, metadata: metadata)
            let downloadURL = try await imageRef.downloadURL()
            
            return downloadURL.absoluteString
        } catch {
            throw FirebaseError.unknownError(error.localizedDescription)
        }
    }
    
    internal func incrementUserPostCount() async throws {
        let userID = try getCurrentUserID()
        try await db.collection("userStats").document(userID).updateData([
            "totalPosts": FieldValue.increment(Int64(1))
        ])
    }
    
    internal func updateUserProductivityHours(hours: Int, minutes: Int) async throws {
        let userID = try getCurrentUserID()
        let totalMinutes = (hours * 60) + minutes
        
        try await db.collection("userStats").document(userID).updateData([
            "totalMinutes": FieldValue.increment(Int64(totalMinutes)),
            "totalHours": FieldValue.increment(Int64(hours)),
            "lastActivityDate": FieldValue.serverTimestamp()
        ])
    }
}

// MARK: - Like Management

extension FirebaseService {
    
    func likePost(postId: String) async throws {
        do {
            let userID = try getCurrentUserID()
            let currentUser = try await getCurrentUser()
            
            // Get post details to find the post owner
            let post = try await getPost(postId: postId)
            
            let postLike = PostLike(postId: postId, userId: userID, username: currentUser.username)
            
            // Use a batch write to ensure atomicity
            let batch = db.batch()
            
            // Add the like
            let likeRef = db.collection("postLikes").document()
            try batch.setData(from: postLike, forDocument: likeRef)
            
            // Increment like count on post
            let postRef = db.collection("posts").document(postId)
            batch.updateData(["likeCount": FieldValue.increment(Int64(1))], forDocument: postRef)
            
            // Update user stats
            let userStatsRef = db.collection("userStats").document(userID)
            batch.updateData(["totalLikes": FieldValue.increment(Int64(1))], forDocument: userStatsRef)
            
            try await batch.commit()
            
            // Create like notification
            try await createLikeNotification(
                postId: postId,
                postOwnerId: post.userId,
                likerUsername: currentUser.username
            )
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func unlikePost(postId: String) async throws {
        do {
            let userID = try getCurrentUserID()
            
            // Find the like document
            let querySnapshot = try await db.collection("postLikes")
                .whereField("postId", isEqualTo: postId)
                .whereField("userId", isEqualTo: userID)
                .getDocuments()
            
            guard let likeDocument = querySnapshot.documents.first else {
                return // Like doesn't exist, nothing to do
            }
            
            // Use a batch write to ensure atomicity
            let batch = db.batch()
            
            // Remove the like
            batch.deleteDocument(likeDocument.reference)
            
            // Decrement like count on post
            let postRef = db.collection("posts").document(postId)
            batch.updateData(["likeCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
            
            // Update user stats
            let userStatsRef = db.collection("userStats").document(userID)
            batch.updateData(["totalLikes": FieldValue.increment(Int64(-1))], forDocument: userStatsRef)
            
            try await batch.commit()
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func isPostLikedByUser(postId: String) async throws -> Bool {
        do {
            let userID = try getCurrentUserID()
            
            let querySnapshot = try await db.collection("postLikes")
                .whereField("postId", isEqualTo: postId)
                .whereField("userId", isEqualTo: userID)
                .limit(to: 1)
                .getDocuments()
            
            return !querySnapshot.documents.isEmpty
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getPostLikes(postId: String, limit: Int = 50) async throws -> [PostLike] {
        do {
            let querySnapshot = try await db.collection("postLikes")
                .whereField("postId", isEqualTo: postId)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            return try querySnapshot.documents.compactMap { document in
                try document.data(as: PostLike.self)
            }
        } catch {
            throw handleFirestoreError(error)
        }
    }
}

// MARK: - Comment Management

extension FirebaseService {
    
    func addComment(postId: String, content: String) async throws -> String {
        do {
            let userID = try getCurrentUserID()
            let currentUser = try await getCurrentUser()
            
            // Get post details to find the post owner
            let post = try await getPost(postId: postId)
            
            let comment = PostComment(postId: postId, userId: userID, username: currentUser.username, content: content)
            
            // Use a batch write to ensure atomicity
            let batch = db.batch()
            
            // Add the comment
            let commentRef = db.collection("postComments").document()
            try batch.setData(from: comment, forDocument: commentRef)
            
            // Increment comment count on post
            let postRef = db.collection("posts").document(postId)
            batch.updateData(["commentCount": FieldValue.increment(Int64(1))], forDocument: postRef)
            
            // Update user stats
            let userStatsRef = db.collection("userStats").document(userID)
            batch.updateData(["totalComments": FieldValue.increment(Int64(1))], forDocument: userStatsRef)
            
            try await batch.commit()
            
            // Create comment notification
            try await createCommentNotification(
                postId: postId,
                postOwnerId: post.userId,
                commenterUsername: currentUser.username,
                commentContent: content
            )
            
            return commentRef.documentID
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func getPostComments(postId: String, limit: Int = 50) async throws -> [PostComment] {
        do {
            let querySnapshot = try await db.collection("postComments")
                .whereField("postId", isEqualTo: postId)
                .whereField("isActive", isEqualTo: true)
                .order(by: "timestamp", descending: false)
                .limit(to: limit)
                .getDocuments()
            
            return try querySnapshot.documents.compactMap { document in
                try document.data(as: PostComment.self)
            }
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func updateComment(commentId: String, content: String) async throws {
        do {
            try await db.collection("postComments").document(commentId).updateData([
                "content": content
            ])
        } catch {
            throw handleFirestoreError(error)
        }
    }
    
    func deleteComment(commentId: String, postId: String) async throws {
        do {
            let userID = try getCurrentUserID()
            
            // Use a batch write to ensure atomicity
            let batch = db.batch()
            
            // Soft delete the comment
            let commentRef = db.collection("postComments").document(commentId)
            batch.updateData(["isActive": false], forDocument: commentRef)
            
            // Decrement comment count on post
            let postRef = db.collection("posts").document(postId)
            batch.updateData(["commentCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
            
            // Update user stats
            let userStatsRef = db.collection("userStats").document(userID)
            batch.updateData(["totalComments": FieldValue.increment(Int64(-1))], forDocument: userStatsRef)
            
            try await batch.commit()
            
        } catch {
            throw handleFirestoreError(error)
        }
    }
}