//
//  AuthViewModel.swift
//  thodea
//
//  Created by Nikolay Pevnev on 3/5/25.
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore
import FirebaseFirestore
import FirebaseDatabase // 👈 Add Realtime Database import
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isLoadingUser: Bool = true
    @Published var isProcessing: Bool = false
    @Published var layerOneLoaded: Bool = false
    @AppStorage("user_exists_in_firestore") var userExistsInFirestore: Bool?
    
    init() {
        self.userSession = Auth.auth().currentUser
        print(userSession?.email as Any)
        // Check if userExistsInFirestore has been defined (is not nil)
        if self.userExistsInFirestore != nil {
            // If it's defined (i.e., a value has been set previously)
            self.layerOneLoaded = true
        } else {
            // It's nil (undefined), so layerOneLoaded remains false
            self.layerOneLoaded = false
        }
    
        if self.userSession != nil  && self.userExistsInFirestore == true {
            Task {
                await loadUserSession()
            }
        }
    }
    
    func singIn(withEmail email: String, link: String) async throws {
        if Auth.auth().isSignIn(withEmailLink: link) {
            Auth.auth().signIn(withEmail: email, link: link) { authResult, error in
                    if let error = error {
                        print("Error signing in: \(error.localizedDescription)")
                        return
                    }
                    
                    self.userSession = authResult?.user
                }
        }
    }
    
    // MARK: - Google Sign-In
    @MainActor
    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ Missing Firebase client ID")
            return
        }
        
        self.isProcessing = true
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Unable to find root view controller")
            return
        }
        
        do {
            // Present Google Sign-In flow
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            // Rest of your code remains the same...
            guard let idToken = result.user.idToken?.tokenString else {
                print("❌ Missing ID token")
                return
            }
            
            let accessToken = result.user.accessToken.tokenString
            
            // Firebase credential from Google tokens
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // Sign in to Firebase with Google credential
            let authResult = try await Auth.auth().signIn(with: credential)
            let user = authResult.user
            self.userSession = user
            
            // 🔍 Check Firestore for existing user document
            if let email = user.email {
                let (userInfo, username) = await fetchUserDataByEmail(email)
                if let userInfo = userInfo {
                    // Safely extract registeredAt from userInfo
                    let registeredAt = userInfo["registeredAt"] as? Timestamp
                    let date = registeredAt?.dateValue() ?? Date() // fallback to current date if missing

                    self.currentUser = User(
                        username: username ?? "",
                        registeredAt: date,
                        darkMode: true
                    )
                    
                    self.userExistsInFirestore = true
                    self.isLoadingUser = false
                } else {
                    // User does not exist in Firestore — navigate to Setup
                    self.userExistsInFirestore = false
                    self.currentUser = nil
                }
                self.layerOneLoaded = true
            }
    
            //print("✅ Google Sign-In successful for \(user.email ?? "unknown user")")
            
            // Equivalent of your Next.js loginData
            /*let loginData: [String: Any] = [
                "uidData": user.uid,
                "emailData": user.email ?? "",
                "createdAtDate": Date()
            ]*/
            
            //print("📦 Login Data:", loginData)
            
        } catch {
            print("❌ Google Sign-In failed:", error.localizedDescription)
        }
        self.isProcessing = false
    }
    
    // MARK: - Microsoft Sign-In
    @MainActor
    func signInWithMicrosoft() async {
        let provider = OAuthProvider(providerID: "microsoft.com")
        self.isProcessing = true
        provider.customParameters = ["prompt": "select_account"]
        // Optional: Add custom parameters or scopes if needed (e.g., for Azure AD tenant)
        // provider.customParameters = ["tenant": "TENANT_ID"] // Use for specific Azure AD tenants
        // provider.scopes = ["mail.read", "calendars.read"] // Request additional scopes

        do {
            // Present the Microsoft Sign-In flow
            let authResult = try await Auth.auth().signIn(with: provider, uiDelegate: getRootViewController() as? AuthUIDelegate)
            print(authResult)
            let user = authResult.user
            self.userSession = user

            // ** 🔍 Your Existing Firestore/User Loading Logic **
            if let email = user.email {
                let (userInfo, username) = await fetchUserDataByEmail(email)
                if let userInfo = userInfo {
                    let registeredAt = userInfo["registeredAt"] as? Timestamp
                    let date = registeredAt?.dateValue() ?? Date()

                    self.currentUser = User(
                        username: username ?? "",
                        registeredAt: date,
                        darkMode: true
                    )
                    
                    self.userExistsInFirestore = true
                    self.isLoadingUser = false
                } else {
                    self.userExistsInFirestore = false
                    self.currentUser = nil
                }
                self.layerOneLoaded = true
            }
            
            print("✅ Microsoft Sign-In successful for \(user.email ?? "unknown user")")
            
        } catch {
            print("❌ Microsoft Sign-In failed:", error.localizedDescription)
        }
        self.isProcessing = false
    }
    
    // MARK: - Yahoo Sign-In 🚀
        @MainActor
        func signInWithYahoo() async {
            // Use the generic OAuthProvider with the Yahoo provider ID
            let provider = OAuthProvider(providerID: "yahoo.com")
            provider.customParameters = ["prompt": "login"]
            self.isProcessing = true

            // Optional: Add scopes to request specific user data from Yahoo.
            // The 'profile' and 'email' scopes are often implicitly included but
            // can be explicitly added if required for specific data or confirmation.
            // provider.scopes = ["profile", "email"]

            do {
                // Present the Yahoo Sign-In flow using the root view controller
                let authResult = try await Auth.auth().signIn(with: provider, uiDelegate: getRootViewController() as? AuthUIDelegate)
                print(authResult)
                let user = authResult.user
                self.userSession = user

                // ** 🔍 Your Existing Firestore/User Loading Logic **
                if let email = user.email {
                    let (userInfo, username) = await fetchUserDataByEmail(email)
                    if let userInfo = userInfo {
                        let registeredAt = userInfo["registeredAt"] as? Timestamp
                        let date = registeredAt?.dateValue() ?? Date()

                        self.currentUser = User(
                            username: username ?? "",
                            registeredAt: date,
                            darkMode: true
                        )
                        
                        self.userExistsInFirestore = true
                        self.isLoadingUser = false
                    } else {
                        self.userExistsInFirestore = false
                        self.currentUser = nil
                    }
                    self.layerOneLoaded = true
                }
                
                print("✅ Yahoo Sign-In successful for \(user.email ?? "unknown user")")
                
            } catch {
                print("❌ Yahoo Sign-In failed:", error.localizedDescription)
            }
            self.isProcessing = false
        }

    // Helper function to find the root view controller (similar to your Google sign-in)
    private func getRootViewController() -> UIViewController {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            fatalError("❌ Unable to find root view controller")
        }
        return rootViewController
    }
    
    @MainActor
    func loadUserSession() async {
        guard let user = Auth.auth().currentUser else {
            self.userExistsInFirestore = false
            self.isLoadingUser = false
            return
        }

        self.userSession = user

        if let email = user.email {
            let (userInfo, username) = await fetchUserDataByEmail(email)
            if let userInfo = userInfo {
                let registeredAt = userInfo["registeredAt"] as? Timestamp
                let date = registeredAt?.dateValue() ?? Date()

                self.currentUser = User(
                    username: username ?? "",
                    registeredAt: date,
                    darkMode: true
                )

            }
        }

        self.isLoadingUser = false
    }
    
    func fetchUserDataByEmail(_ email: String) async -> (userInfo: [String: Any]?, username: String?) {
            let db = Firestore.firestore()
            let userRef = db.collection("user")
            let query = userRef.whereField("email", isEqualTo: email)

            do {
                let snapshot = try await query.getDocuments()
                if let document = snapshot.documents.first {
                    let data = document.data()
                    let username = document.documentID
                    return (data, username)
                } else {
                    return (nil, nil)
                }
            } catch {
                print("❌ Error fetching user data: \(error.localizedDescription)")
                return (nil, nil)
            }
        }

    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
            self.userExistsInFirestore = nil
            self.layerOneLoaded = false
            print("✅ Signed out successfully")
        } catch {
            print("❌ Error signing out:", error.localizedDescription)
        }
    }
    

    @MainActor // 👈 1. Ensures all state updates are 100% thread-safe
    func deleteAccount() async {
        
        // 2. Get the current user AND username *before* deleting
        guard let _ = Auth.auth().currentUser, // Check if user session exists (Auth deletion is removed)
              let username = self.currentUser?.username, !username.isEmpty else {
            print("❌ Cannot delete: User or username is not loaded.")
            return
        }
        
        // 3. Set up references to all the data you created
        let fdb = Firestore.firestore()
        let db = Database.database().reference()
        
        let firestoreRef = fdb.collection("user").document(username)
        let realtimeRef = db.child("user").child(username)

        do {
            // 4. Use a TaskGroup to delete everything in parallel
            try await withThrowingTaskGroup(of: Void.self) { group in
                
                // Task 2: Delete from Firestore
                group.addTask {
                    try await firestoreRef.delete()
                }
                
                // Task 3: Delete from Realtime Database
                group.addTask {
                    try await realtimeRef.removeValue()
                }
                
                // Wait for all 3 tasks to complete
                try await group.waitForAll()
            }
            
            // 5. Success: Clear all local user state
            print("✅ Account and all associated data deleted successfully.")
            signOut()

        } catch {
            print("❌ Error deleting account or data: \(error.localizedDescription)")
            // Note: If this error is "requiresRecentLogin",
            // you will need to prompt the user to re-authenticate.
        }
    }
    
    @MainActor
    func fetchUser() async {
        self.isLoadingUser = true
        await loadUserSession()
        self.userExistsInFirestore = true
    }
    
    func sendEmail(to email: String) async {
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: "https://www.thodea.com") // Your domain
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)

        do {
            // CORRECT: Call the async/throws version
            try await Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings)
            
            // Success code goes here, after a successful 'try await'
            // The error closure is removed.
           /* UserDefaults.standard.set(email, forKey: "Email")
            print("Check your email for the sign-in link.")*/
            
        } catch { // The 'catch' block is now reachable because 'sendSignInLink' throws an error
            print("Error sending sign-in link: \(error.localizedDescription)")
        }
    }
    
}


