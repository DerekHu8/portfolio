//
//  AccountCreationView.swift
//  Locki
//
//  Created by Derek Hu on 7/31/25.
//

import SwiftUI

struct AccountCreationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var firebaseManager = FirebaseManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var showingCreateAccount = false
    
    var body: some View {
        ZStack {
            // Background
            themeManager.colors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Title Section
                VStack(spacing: 8) {
                    Text("Welcome to Locki!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.colors.primaryText)
                    
                    Text("Share your productive time with others")
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.secondaryText)
                }
                .padding(.bottom, 40)
                
                // Input Fields
                VStack(spacing: 16) {
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
                
                // Sign In Button
                Button(action: {
                    Task {
                        _ = await firebaseManager.signIn(email: email, password: password)
                    }
                }) {
                    HStack {
                        if firebaseManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        }
                        Text(firebaseManager.isLoading ? "Signing in..." : "Sign in")
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
                
                // Social Sign In Buttons
                VStack(spacing: 12) {
                    // Google Sign In
                    Button(action: {
                        Task {
                            await firebaseManager.signInWithGoogle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(themeManager.colors.primaryText)
                                .font(.title3)
                            
                            Text("Sign in With Google")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.primaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(themeManager.colors.secondaryBackground)
                        .cornerRadius(27)
                    }
                    
                    // Apple Sign In
                    Button(action: {
                        Task {
                            await firebaseManager.signInWithApple()
                        }
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                                .foregroundColor(themeManager.colors.primaryText)
                                .font(.title3)
                            
                            Text("Sign in With Apple")
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
                
                // Register Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(themeManager.colors.secondaryText)
                    
                    Button("Register") {
                        showingCreateAccount = true
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.9))
                }
                .font(.subheadline)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
        }
        .fullScreenCover(isPresented: $showingCreateAccount) {
            CreateAccountView()
                .environmentObject(themeManager)
                .environmentObject(firebaseManager)
        }
        .transaction { transaction in
            if showingCreateAccount {
                transaction.disablesAnimations = true
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
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
    AccountCreationView()
        .environmentObject(ThemeManager.shared)
}
