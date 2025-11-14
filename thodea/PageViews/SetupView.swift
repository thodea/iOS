//
//  SetupView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 3/1/25.
//


import SwiftUI
import WebKit
import FirebaseFirestore // 👈 Add Firestore import
import FirebaseDatabase // 👈 Add Realtime Database import

struct SetupView: View {
    @State private var username: String = ""
    @State private var usernameCopy: String = ""
    @State private var emailSent: Bool = false
    @State private var showSafariView = false
    @State private var selectedURL: URL?
    @State private var isError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false // 👈 For "isProcessing"
    @FocusState private var isUsernameFieldFocused: Bool // 👈 To control focus
    @EnvironmentObject var authViewModel: AuthViewModel // Add this
    @Environment(\.presentationMode) var presentationMode
    // Define the error color for reuse
    private var errorColor = Color(red: 255/255, green: 131/255, blue: 131/255)
    private var primaryBorderColor = Color(red: 30 / 255, green: 58 / 255, blue: 138 / 255)

    var body: some View {
        Color(red: 17/255, green: 24/255, blue: 39/255)
        .ignoresSafeArea()
        .overlay {
            VStack(spacing: 12) {
                HStack() {
                    Text("Set username").font(.system(size: 26)).foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Button(action: {
                        // LOG OUT action
                        authViewModel.signOut()
                        presentationMode.wrappedValue.dismiss()
                        print("LOG OUT tapped")
                    }) {
                        Image(systemName: "arrow.left.to.line.square")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .foregroundColor(Color(red: 37/255, green: 99/255, blue: 235/255))
                    }
                }.padding(.horizontal)
                VStack() {
                    TextField(
                        "",
                        text: $username,
                        prompt: Text(isError ? errorMessage : "username")
                            .foregroundColor(isError ? errorColor : .gray) // 👈 Uses errorColor
                            .font(.title2)
                    )
                    .focused($isUsernameFieldFocused) // 👈 Bind focus state
                    .onChange(of: username) { newValue in
                        DispatchQueue.main.async {
                            let regex = "^[a-z0-9_]*$" // Only allows lowercase letters, numbers, and underscores
                            let filteredValue = newValue.lowercased().prefix(14) // Convert to lowercase & limit length
                            let finalValue = String(filteredValue).filter { String($0).range(of: regex, options: .regularExpression) != nil }

                            if username != finalValue {
                                username = finalValue
                            }
                        }
                    }
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal)
                    .overlay(
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(isError ? errorColor : primaryBorderColor)
                                .frame(height: 3)
                        }
                        .padding(.horizontal)
                    )
                    .autocapitalization(.none) // 👈 Match autoCapitalize="none"



                    
                    Text("a-z, 0-9, _ only 14 char max")
                        .font(.system(size: 14))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 12)
                                    //.border(.red, width: 2)
                                    .padding(.horizontal)
                }
                
                if username != "" {
                    Button(action: {
                        Task {
                            await nextButtonTapped()
                        }
                    }) {
                        // We apply all the common modifiers *outside* the if/else
                        Group {
                            if isLoading {
                                // --- This is the new part ---
                                // Replicates `flex flex-row`
                                HStack(spacing: 10) { // `spacing: 10` is similar to `ml-2`
                                    Text("Creating")
                                    
                                    // This is the SwiftUI equivalent of the spinning SVG
                                    ProgressView()
                                        // Style it to match your design
                                        .tint(.white.opacity(0.7)) // `opacity-30`
                                        .frame(width: 24, height: 24) // `w-6 h-6`
                                }
                                // --- End of new part ---
                            } else {
                                Text("Next")
                            }
                        }
                        .font(.title2.weight(.semibold)) // Match `font-semibold`
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color(red: 30/255, green: 58/255, blue: 138/255))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                        .padding(.horizontal)
                        
                    }
                    .disabled(isLoading) // 🔥 Also add this to prevent double-taps
                    .padding(.bottom, 18)
                }

                Spacer()
            }
            //.border(.red, width: 2)
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .frame(maxWidth: .infinity, alignment: .top)
            .foregroundColor(.white)
        }
    }
    
    private func nextButtonTapped() async {
            isLoading = true
            isUsernameFieldFocused = false // Unfocus the text field
            
            let fdb = Firestore.firestore()
            let docRef = fdb.collection("user").document(username)
            
            do {
                let docSnap = try await docRef.getDocument()
                
                if docSnap.exists {
                    // --- Username taken (JS "if" block) ---
                    print("exists")
                    usernameCopy = username // Save the current username
                    errorMessage = "username taken"
                    isError = true
                    username = "" // Clear text field to show error in prompt
                    errorMessage = "username taken"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isError = false
                        errorMessage = ""
                        username = usernameCopy
                        isUsernameFieldFocused = true // Refocus (JS "focus()")
                        isLoading = false
                        
                    }
                    
           
                } else {
                    // --- Username available, register (JS "else" block) ---
                    print("doesnt exist")
                    // Get email from your auth view model
                    guard let userEmail = authViewModel.userSession?.email else {
                        print("Error: User email is not available.")
                        errorMessage = "An error occurred. Please try again."
                        isError = true
                        isLoading = false
                        return
                    }
                    
                    // Call the registration function
                    // This function will handle errors and update the auth state
                    await handleUserRegistration(username: username, userEmail: userEmail)
                    
                    // On success, handleUserRegistration will update the authViewModel,
                    // which should trigger navigation away from this view automatically.
                    // We only set isLoading = false on failure (which is done inside handleUserRegistration).
                }
            } catch {
                // --- General error (JS "catch" block for getDoc) ---
                print("Error checking username: \(error)")
                errorMessage = "Error: \(error.localizedDescription)"
                isError = true
                isLoading = false
            }
        }

        private func handleUserRegistration(username: String, userEmail: String) async {
            let fdb = Firestore.firestore()
            let db = Database.database().reference() // Realtime DB root
            
            let userRef = fdb.collection("user").document(username)
            let realtimeRef = db.child("user").child(username)
            
            // Data for Firestore
            let firestoreData: [String: Any] = [
                "registeredAt": Timestamp(date: Date()), // Use Firestore's Timestamp
                "darkMode": true,
                "username": username,
                "email": userEmail
            ]
            
            // Data for Realtime Database
            let realtimeData: [String: Any] = [
                "followers": 0,
                "following": 0,
                "thoughts": 0,
                "registeredAt": Date().timeIntervalSince1970 * 1000 // Milliseconds since epoch
            ]
            
            do {
                // Use a TaskGroup to run both writes concurrently (JS "Promise.all")
                try await withThrowingTaskGroup(of: Void.self) { group in
                    
                    // 1. Firestore Write
                    group.addTask {
                        try await userRef.setData(firestoreData)
                    }
                    
                    // 2. Realtime Database Write
                    group.addTask {
                        try await realtimeRef.setValue(realtimeData)
                    }
                    
                    // Wait for both to complete
                    try await group.waitForAll()
                }
                
                print("User registered successfully in both Firestore and Realtime Database")
                
                // Success: Refresh the user data in the view model.
                // This will update the app's state and trigger navigation.
                await authViewModel.fetchUser() // (Assuming you have a function like this)
                
                // No need to set isLoading = false, as the view will be dismissed.
                
            } catch {
                // --- Error handling (JS "catch" block) ---
                print("Error registering user: \(error)")
                errorMessage = "Registration failed. Please try again."
                isError = true
                isLoading = false // Set loading to false on failure
            }
        }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
    }
}
