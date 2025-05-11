//
//  AuthViewModel.swift
//  thodea
//
//  Created by Nikolay Pevnev on 3/5/25.
//

import Foundation
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
    init() {
        
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
    
    func createUser(withEmail email: String, fullname: String) async throws {
        
    }
    
    func signOut()  {
        
    }
    
    func deleteAccount() {
        
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
