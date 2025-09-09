//
//  CreateAccountView.swift
//  Locki
//
//  Created by Derek Hu on 7/31/25.
//

import SwiftUI

struct CreateAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var username = ""
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    
    var body: some View {
        ZStack {
            // Background
            themeManager.colors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Title Section
                VStack(spacing: 8) {
                    Text("Create a Locki Account!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.colors.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("Get started sharing your productivity!")
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)
                
                // Input Fields
                VStack(spacing: 16) {
                    // Username Field
                    ZStack(alignment: .leading) {
                        if username.isEmpty {
                            Text("Username")
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.leading, 16)
                        }
                        TextField("", text: $username)
                            .autocapitalization(.none)
                            .foregroundColor(themeManager.colors.primaryText)
                            .padding(.leading, 16)
                    }
                    .frame(height: 54)
                    .background(themeManager.colors.secondaryBackground)
                    .cornerRadius(27)
                    
                    // Email Field
                    ZStack(alignment: .leading) {
                        if email.isEmpty {
                            Text("Email")
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.leading, 16)
                        }
                        TextField("", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(themeManager.colors.primaryText)
                            .padding(.leading, 16)
                    }
                    .frame(height: 54)
                    .background(themeManager.colors.secondaryBackground)
                    .cornerRadius(27)
                    
                    // Password Field
                    ZStack(alignment: .leading) {
                        HStack {
                            if password.isEmpty {
                                Text("Password")
                                    .foregroundColor(.gray.opacity(0.6))
                                    .padding(.leading, 16)
                                Spacer()
                            }
                        }
                        
                        HStack {
                            if isPasswordVisible {
                                TextField("", text: $password)
                                    .foregroundColor(themeManager.colors.primaryText)
                                    .padding(.leading, 16)
                            } else {
                                SecureField("", text: $password)
                                    .foregroundColor(themeManager.colors.primaryText)
                                    .padding(.leading, 16)
                            }
                            
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                    .frame(height: 54)
                    .background(themeManager.colors.secondaryBackground)
                    .cornerRadius(27)
                }
                
                // Forgot Password
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        // Handle forgot password
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.9))
                }
                .padding(.bottom, 8)
                
                // Error Message
                if let errorMessage = firebaseManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .multilineTextAlignment(.center)
                }
                
                // Sign Up Button
                Button(action: {
                    Task {
                        let success = await firebaseManager.signUp(
                            email: email,
                            password: password,
                            username: username,
                            displayName: username.isEmpty ? "" : username
                        )
                        // Navigation to HomeView is handled automatically by authentication state									
                    }
                }) {
                    HStack {
                        if firebaseManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        }
                        Text(firebaseManager.isLoading ? "Creating Account..." : "Sign up")
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .cornerRadius(27)
                }
                .disabled(firebaseManager.isLoading)
                .padding(.bottom, 20)
                
                // Or Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("Or")
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.secondaryText)
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                }
                .padding(.bottom, 16)
                
                // Social Sign Up Buttons
                VStack(spacing: 12) {
                    // Google Sign Up
                    Button(action: {
                        Task {
                            await firebaseManager.signInWithGoogle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(themeManager.colors.primaryText)
                                .font(.title3)
                            
                            Text("Sign up With Google")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.primaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(themeManager.colors.secondaryBackground)
                        .cornerRadius(27)
                    }
                    
                    // Apple Sign Up
                    Button(action: {
                        Task {
                            await firebaseManager.signInWithApple()
                        }
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                                .foregroundColor(themeManager.colors.primaryText)
                                .font(.title3)
                            
                            Text("Sign up With Apple")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.primaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(themeManager.colors.secondaryBackground)
                        .cornerRadius(27)
                    }
                }
                
                Spacer()
                
                // Sign In Link
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(themeManager.colors.secondaryText)
                    
                    Button("Sign In") {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            dismiss()
                        }
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.9))
                }
                .font(.subheadline)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
        }
        .onChange(of: firebaseManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
    }
}

struct CustomSignUpTextFieldStyle: TextFieldStyle {
    @EnvironmentObject var themeManager: ThemeManager
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .frame(height: 54)
            .background(themeManager.colors.secondaryBackground)
            .cornerRadius(27)
            .foregroundColor(themeManager.colors.primaryText)
    }
}

#Preview {
    CreateAccountView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(FirebaseManager.shared)
}
