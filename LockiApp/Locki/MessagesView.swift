//
//  MessagesView.swift
//  Locki
//
//  Created by Derek Hu on 8/2/25.
//

import SwiftUI

struct MessageContact {
    let id = UUID()
    let name: String
    let lastMessage: String
    let timestamp: String
    let isActive: Bool
    let hasJoinButton: Bool
}

struct MessagesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    
    init(isPresented: Binding<Bool> = .constant(true)) {
        self._isPresented = isPresented
    }
    
    // Sample contact data based on the screenshot
    private let contacts = [
        MessageContact(name: "Duke '29", lastMessage: "angelina (bme and pre...", timestamp: "24m", isActive: true, hasJoinButton: true),
        MessageContact(name: "P WILD gonna be WILD 😂", lastMessage: "14 active today", timestamp: "", isActive: false, hasJoinButton: false),
        MessageContact(name: "Carolyn Fu", lastMessage: "Active 4m ago", timestamp: "", isActive: false, hasJoinButton: false),
        MessageContact(name: "elina", lastMessage: "Real i did one in Taipei and we started ...", timestamp: "4h", isActive: false, hasJoinButton: false),
        MessageContact(name: "Erin Liau", lastMessage: "Active now", timestamp: "", isActive: true, hasJoinButton: false),
        MessageContact(name: "Justin", lastMessage: "Justin sent an attachment.", timestamp: "5h", isActive: false, hasJoinButton: false),
        MessageContact(name: "Bigs and sum", lastMessage: "1 active today", timestamp: "", isActive: false, hasJoinButton: false)
    ]
    
    var body: some View {
        ZStack {
            // Background
            themeManager.colors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Header
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
                    
                    // Messages icon and title
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.title2)
                        
                        Text("Messages")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.colors.primaryText)
                    }
                    
                    Spacer()
                    
                    // Pencil icon button (replacing "Requests")
                    Button(action: {
                        // Handle compose message
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.title2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Messages List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(contacts, id: \.id) { contact in
                            MessageContactRowView(contact: contact)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

struct MessageContactRowView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let contact: MessageContact
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            ZStack {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(themeManager.colors.primaryText)
                            .font(.title3)
                    )
                
                // Active indicator
                if contact.isActive {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(themeManager.colors.primaryBackground, lineWidth: 2)
                                )
                        }
                    }
                    .frame(width: 50, height: 50)
                }
            }
            
            // Contact Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(contact.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.colors.primaryText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Timestamp or JOIN button
                    if contact.hasJoinButton {
                        Button(action: {
                            // Handle join action
                        }) {
                            Text("JOIN")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.colors.primaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.green)
                                .cornerRadius(16)
                        }
                    } else if !contact.timestamp.isEmpty {
                        Text(contact.timestamp)
                            .font(.subheadline)
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                Text(contact.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.clear)
        .overlay(
            // Bottom divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
                .padding(.leading, 70), // Align with text content
            alignment: .bottom
        )
    }
}

#Preview {
    MessagesView()
        .environmentObject(ThemeManager.shared)
}