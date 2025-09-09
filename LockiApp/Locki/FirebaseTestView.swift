//
//  FirebaseTestView.swift
//  Locki
//
//  Created for Firebase Testing
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct FirebaseTestView: View {
    @State private var testResults: [String] = []
    @State private var isLoading = false
    @State private var testPosts: [Post] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Firebase Connection Test")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                // Test Results Display
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(testResults, id: \.self) { result in
                            Text(result)
                                .padding(.horizontal)
                                .foregroundColor(result.contains("✅") ? .green : result.contains("❌") ? .red : .primary)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Test Buttons
                VStack(spacing: 12) {
                    Button(action: testFirebaseConnection) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Test Firebase Connection")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    Button(action: testSavePost) {
                        Text("Test Save Post")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    Button(action: testFetchPosts) {
                        Text("Test Fetch Posts")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    Button(action: clearResults) {
                        Text("Clear Results")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Fetched Posts Display
                if !testPosts.isEmpty {
                    Text("Fetched Posts (\(testPosts.count))")
                        .font(.headline)
                        .padding(.top)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(testPosts) { post in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(post.username): \(post.title)")
                                        .font(.headline)
                                    Text(post.description)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("Time: \(post.hours)h \(post.minutes)m")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Firebase Test Functions
    
    func testFirebaseConnection() {
        isLoading = true
        addResult("🔄 Testing Firebase connection...")
        
        // Check if Firebase is configured
        guard FirebaseApp.app() != nil else {
            isLoading = false
            addResult("❌ Firebase not configured. Check FirebaseApp.configure() in App.swift")
            return
        }
        
        addResult("✅ Firebase app configured")
        
        let db = Firestore.firestore()
        
        // Try to access Firestore settings as a connection test
        db.collection("test").limit(to: 1).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    let errorCode = (error as NSError).code
                    let errorDomain = (error as NSError).domain
                    
                    self.addResult("❌ Firestore Error:")
                    self.addResult("   Code: \(errorCode)")
                    self.addResult("   Domain: \(errorDomain)")
                    self.addResult("   Message: \(error.localizedDescription)")
                    
                    if errorCode == 7 { // PERMISSION_DENIED
                        self.addResult("💡 Fix: Update Firestore Security Rules to allow read/write")
                    }
                } else {
                    self.addResult("✅ Firestore connection successful!")
                    self.addResult("✅ Document count: \(snapshot?.documents.count ?? 0)")
                }
            }
        }
    }
    
    func testSavePost() {
        isLoading = true
        addResult("🔄 Testing save post...")
        
        // Create a test post
        let testPost = Post(
            userId: "test_user_id",
            username: "@testuser",
            title: "Firebase Test Post",
            description: "This is a test post to verify Firebase save functionality",
            hours: "2",
            minutes: "30"
        )
        
        savePost(testPost)
    }
    
    func testFetchPosts() {
        isLoading = true
        addResult("🔄 Testing fetch posts...")
        
        fetchPosts()
    }
    
    func savePost(_ post: Post) {
        let db = Firestore.firestore()
        
        do {
            let documentRef = try db.collection("posts").addDocument(from: post)
            DispatchQueue.main.async {
                self.isLoading = false
                self.addResult("✅ Post saved successfully with ID: \(documentRef.documentID)")
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.addResult("❌ Error saving post: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchPosts() {
        let db = Firestore.firestore()
        
        db.collection("posts")
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.addResult("❌ Error fetching posts: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.addResult("❌ No documents found")
                        return
                    }
                    
                    var fetchedPosts: [Post] = []
                    
                    for document in documents {
                        do {
                            let post = try document.data(as: Post.self)
                            fetchedPosts.append(post)
                        } catch {
                            self.addResult("❌ Error decoding post: \(error.localizedDescription)")
                        }
                    }
                    
                    self.testPosts = fetchedPosts
                    self.addResult("✅ Successfully fetched \(fetchedPosts.count) posts")
                }
            }
    }
    
    // MARK: - Helper Functions
    
    func addResult(_ result: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        testResults.append("[\(timestamp)] \(result)")
    }
    
    func clearResults() {
        testResults.removeAll()
        testPosts.removeAll()
    }
}

// MARK: - Preview

#Preview {
    FirebaseTestView()
}