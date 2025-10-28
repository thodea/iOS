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

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
    init() {
       self.userSession = Auth.auth().currentUser
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
            
            //print("✅ Google Sign-In successful for \(user.email ?? "unknown user")")
            
            // Equivalent of your Next.js loginData
            let loginData: [String: Any] = [
                "uidData": user.uid,
                "emailData": user.email ?? "",
                "createdAtDate": Date()
            ]
            
            //print("📦 Login Data:", loginData)
            
        } catch {
            print("❌ Google Sign-In failed:", error.localizedDescription)
        }
    }
    
    func createUser(withEmail email: String, fullname: String) async throws {
        
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            print("✅ Signed out successfully")
        } catch {
            print("❌ Error signing out:", error.localizedDescription)
        }
    }
    
    func deleteAccount() {
        Auth.auth().currentUser?.delete { error in
            if let error = error {
                print("❌ Error deleting account:", error.localizedDescription)
            } else {
                self.userSession = nil
                print("✅ Account deleted successfully")
            }
        }
    }
    
    func fetchUser() async {
        
    }
    
    func sendEmail(to email: String) async {
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: "https://www.thodea.com") // Your domain
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)

        do {
            try await Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings)
                /*{ error in
                if let error = error {
                    print("Error sending sign-in link: \(error)")
                    return
                }
                // Save email locally for verification later
                UserDefaults.standard.set(email, forKey: "Email")
                print("Check your email for the sign-in link.")
            }*/
        }
        catch {
            print(error.localizedDescription)
        }
       
    }
    
}


