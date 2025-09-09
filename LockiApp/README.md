# Locki – Productivity Tracking iOS App

Locki is an iOS productivity app designed to help students and professionals log study/work sessions, track progress over time, and stay accountable with peers.  
Built with **Swift/SwiftUI** and backed by **Firebase**, Locki combines productivity tracking with social features like leaderboards and messaging.  

---

## Features
- **Stopwatch-based session logging** – Start/stop timers to record productivity sessions.  
- **Daily streak tracking** – Visualize consistency and stay motivated.  
- **Global leaderboard** – Compare progress and streaks with friends or globally.  
- **Messaging system** – Chat with friends and share progress updates.  
- **Notifications** – Get reminders for goals and achievements.  
- **Profile customization** – Personalize user profiles and track history.  

---

## Tech Stack
- **Frontend:** Swift, SwiftUI  
- **Backend:** Firebase (Authentication, Firestore Database, Cloud Storage, Notifications)  
- **Tools:** GitHub, Xcode, VS Code  
- **Languages:** Swift, Python (for data analysis prototypes)  

---

## Architecture Overview
Locki follows a **client-server architecture**:  

- **Frontend (iOS App):**  
  - SwiftUI handles UI components and reactive state management.  
  - Stopwatch, leaderboard, and chat features implemented with modular views.  

- **Backend (Firebase):**  
  - **Authentication:** Secure sign-in & sign-up (email, Apple, Google planned).  
  - **Firestore Database:** Real-time data sync for sessions, leaderboards, and chats.  
  - **Cloud Storage:** Profile images and attachments.  
  - **Notifications:** Push reminders for productivity streaks.  

---

## Getting Started
### Prerequisites
- macOS with Xcode 15+ installed  
- iOS 17+ Simulator or physical device  
- CocoaPods or Swift Package Manager for dependencies  

## How to Run
1. Clone repo  
2. Open `Locki.xcodeproj` in Xcode  
3. Select simulator/device → Build & Run
