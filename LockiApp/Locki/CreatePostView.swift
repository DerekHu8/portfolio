//
//  CreatePostView.swift
//  Locki
//
//  Created by Derek Hu on 7/31/25.
//

import SwiftUI
import FirebaseFirestore

// Post model moved to DataModels.swift - using comprehensive version

struct CreatePostView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    @State private var postTitle = ""
    @State private var postDescription = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    // Stopwatch functionality
    @State private var elapsedTime: TimeInterval = 0
    @State private var isTimerRunning = false
    @State private var timer: Timer?
    @State private var startTime: Date?
    @Binding var showingSearch: Bool
    @Binding var showingProfile: Bool
    @Binding var showingLeaderboard: Bool
    @Binding var showingNotifications: Bool
    
    let onPostCreated: (Post) -> Void
    
    init(isPresented: Binding<Bool> = .constant(true), onPostCreated: @escaping (Post) -> Void = { _ in }, showingSearch: Binding<Bool> = .constant(false), showingProfile: Binding<Bool> = .constant(false), showingLeaderboard: Binding<Bool> = .constant(false), showingNotifications: Binding<Bool> = .constant(false)) {
        self._isPresented = isPresented
        self.onPostCreated = onPostCreated
        self._showingSearch = showingSearch
        self._showingProfile = showingProfile
        self._showingLeaderboard = showingLeaderboard
        self._showingNotifications = showingNotifications
    }
    
    // Check if all required fields are filled
    private var canPost: Bool {
        !postTitle.isEmpty && !postDescription.isEmpty && elapsedTime > 0 && selectedImage != nil
    }
    
    // Format elapsed time for display
    private var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) % 3600 / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // Get hours and minutes for post creation
    private var timeWorked: (hours: String, minutes: String) {
        let totalMinutes = Int(elapsedTime) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return (hours: String(hours), minutes: String(minutes))
    }
    
    // MARK: - Stopwatch Functions
    
    private func startTimer() {
        guard !isTimerRunning else { return }
        
        isTimerRunning = true
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = self.startTime {
                self.elapsedTime += 0.1
            }
        }
    }
    
    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        startTime = nil
    }
    
    private func resetTimer() {
        stopTimer()
        elapsedTime = 0
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
                    
                    // Title
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
                        // Stopwatch Section
                        VStack(alignment: .center, spacing: 24) {
                            Text("Time Worked")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.primaryText)
                                .fontWeight(.medium)
                            
                            // Large Timer Display
                            VStack(spacing: 16) {
                                // Timer Circle Background
                                ZStack {
                                    Circle()
                                        .fill(themeManager.colors.secondaryBackground)
                                        .frame(width: 220, height: 220)
                                        .shadow(color: themeManager.colors.shadowColor, radius: 10, x: 0, y: 5)
                                    
                                    // Timer Text
                                    Text(formattedTime)
                                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                                        .foregroundColor(themeManager.colors.primaryText)
                                }
                                
                                // Timer Status Text
                                Text(isTimerRunning ? "Timer Running" : elapsedTime > 0 ? "Timer Stopped" : "Ready to Start")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .fontWeight(.medium)
                            }
                            
                            // Control Buttons
                            HStack(spacing: 16) {
                                // Start/Stop Button
                                Button(action: {
                                    if isTimerRunning {
                                        stopTimer()
                                    } else {
                                        startTimer()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                        
                                        Text(isTimerRunning ? "Stop" : "Start")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: 100, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(isTimerRunning ? Color.red : Color.green)
                                            .shadow(color: (isTimerRunning ? Color.red : Color.green).opacity(0.3), radius: 5, x: 0, y: 2)
                                    )
                                }
                                
                                // Reset Button
                                Button(action: {
                                    resetTimer()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 16, weight: .semibold))
                                        
                                        Text("Reset")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(themeManager.colors.primaryText)
                                    .frame(width: 100, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(themeManager.colors.secondaryBackground)
                                            .shadow(color: themeManager.colors.shadowColor, radius: 5, x: 0, y: 2)
                                    )
                                }
                                .disabled(elapsedTime == 0)
                                .opacity(elapsedTime == 0 ? 0.5 : 1.0)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Title Input Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Post Title")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.primaryText)
                                .fontWeight(.medium)
                            
                            ZStack(alignment: .leading) {
                                if postTitle.isEmpty {
                                    Text("Enter a title for your post...")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.leading, 16)
                                }
                                TextField("", text: $postTitle)
                                    .foregroundColor(themeManager.colors.primaryText)
                                    .padding(.leading, 16)
                            }
                            .frame(height: 54)
                            .background(themeManager.colors.secondaryBackground)
                            .cornerRadius(27)
                        }
                        .padding(.horizontal, 20)
                        
                        // Description Input Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.primaryText)
                                .fontWeight(.medium)
                            
                            ZStack(alignment: .topLeading) {
                                if postDescription.isEmpty {
                                    Text("Describe your productivity session...")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.leading, 20)
                                        .padding(.top, 18)
                                }
                                TextEditor(text: $postDescription)
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
                        
                        // Image Attachment Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Attach Image")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.primaryText)
                                .fontWeight(.medium)
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(themeManager.colors.secondaryBackground)
                                        .frame(height: 200)
                                    
                                    if let selectedImage = selectedImage {
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                    } else {
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 32))
                                                .foregroundColor(themeManager.colors.secondaryText)
                                            
                                            Text("Tap to add image")
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.colors.secondaryText)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Spacer to push post button to bottom
                        Spacer(minLength: 80)
                    }
                    .padding(.bottom, 100)
                }
            }
            
            // Post Button (Bottom Right)
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        // Stop the timer if it's running
                        if isTimerRunning {
                            stopTimer()
                        }
                        
                        // Create the post using stopwatch time
                        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
                        let time = timeWorked
                        let newPost = Post(
                            userId: "current_user_id", // Will be replaced with actual user ID from auth
                            username: "@yourusername", // You can make this dynamic later
                            title: postTitle,
                            description: postDescription,
                            hours: time.hours,
                            minutes: time.minutes,
                            imageData: imageData
                        )
                        
                        // Pass the post back to the parent
                        onPostCreated(newPost)
                        
                        // Dismiss the view
                        isPresented = false
                    }) {
                        HStack(spacing: 8) {
                            Text("Post")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeManager.colors.primaryText)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(themeManager.colors.primaryText)
                        }
                        .frame(width: 110, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(canPost ? Color(red: 0.2, green: 0.6, blue: 1.0) : Color.gray.opacity(0.3))
                        )
                    }
                    .disabled(!canPost)
                    .padding(.trailing, 20)
                    .padding(.bottom, 70)
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
                        // Already on create post page, do nothing
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(themeManager.colors.primaryBackground)
                            .font(.body)
                            .fontWeight(.bold)
                            .frame(width: 32, height: 32)
                            .background(Color.blue)
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
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onDisappear {
            // Clean up timer when view disappears
            stopTimer()
        }
    }
}

// Simple Image Picker (placeholder for now)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    CreatePostView()
        .environmentObject(ThemeManager.shared)
}
