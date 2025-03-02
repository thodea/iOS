//
//  LoginView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 2/28/25.
//


import SwiftUI
import WebKit

struct LoginView: View {
    @State private var email: String = ""
    @State private var emailCopy: String = ""
    @State private var emailSent: Bool = false
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    @State private var selectedURL: URL?
    @State private var isError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        Color(red: 17/255, green: 24/255, blue: 39/255)
        .ignoresSafeArea()
        .overlay {
            VStack(spacing: 12) {
                if !emailSent {
                    VStack {
                        HStack(spacing: 20) {
                            SocialLoginButton(imageName: "https://cdn.nikpevnev.com/assets/store/design/google.webp") {
                                signIn(provider: "google")
                            }
                            Spacer()
                            SocialLoginButton(imageName: "https://cdn.nikpevnev.com/assets/store/design/microsoft.webp") {
                                signIn(provider: "microsoft")
                            }
                            Spacer()
                            SocialLoginButton(imageName: "https://cdn.nikpevnev.com/assets/store/design/yahoo.webp") {
                                signIn(provider: "yahoo")
                            }
                        }.frame(maxWidth: .infinity, minHeight: 75)
                            .padding(.horizontal)
                        
                        HStack {
                                    ZStack {
                                        Divider().frame(height: 1)
                                    .background(Color(red: 17/255, green: 93/255, blue: 180/255))
                                    }
                                    
                                    Text("Or")
                                        .padding(.vertical, 10)
                                        .foregroundColor(Color(red: 17/255, green: 93/255, blue: 180/255))
                                    
                                    ZStack {
                                        Divider().frame(height: 1)
                                    .background(Color(red: 17/255, green: 93/255, blue: 180/255))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 4)
                                .padding(.horizontal)
                            
                        TextField(
                                "",
                                text: $email,
                                prompt: Text(isError ? errorMessage : "Email")
                                    .foregroundColor(isError ? Color(red: 255/255, green: 131/255, blue: 131/255) : .gray)
                                    .font(.title2)
                            )
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal)
                            .overlay(
                                VStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(Color(red: 30 / 255, green: 58 / 255, blue: 138 / 255))
                                        .frame(height: 3)
                                }
                                .padding(.horizontal)
                            )                                        .padding(.bottom, 12)
                        
                        //TextField("", text: $email)
                            

                        
                        Button(action: {
                            userLogIn()
                        }) {
                            Text("Enter")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(Color(red: 30/255, green: 58/255, blue: 138/255))
                                .foregroundColor(.white)
                                .cornerRadius(5)
                                .padding(.horizontal)
                        }.padding(.bottom, 18)
                        
                    }
                    .background(Color(red: 17/255, green: 24/255, blue: 39/255)) // Ensure background to prevent transparency
                    .clipShape(RoundedRectangle(cornerRadius: 4)) // Clips the view properly
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)

                    )
                    .shadow(color: Color.black.opacity(1), radius: 4, x: 1, y: 2)
                    
                    Text("By entering you agree to")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    
                    HStack {
                        Text("Terms of Use")
                            .onTapGesture {
                                selectedURL = URL(string: "https://thodea.com/policy/terms")
                                showTermsSheet = true 
                            }
                            .sheet(isPresented: $showTermsSheet) {
                                FullScreenModalView(url: URL(string: "https://thodea.com/policy/terms")!)
                            }
                            .foregroundColor(.blue)
                        Text("and").foregroundColor(.gray)                                .font(.system(size: 18))

                        Text("Privacy Policy")
                            .onTapGesture {
                                selectedURL = URL(string: "https://thodea.com/policy/privacy")
                                showPrivacySheet = true
                            }
                            .sheet(isPresented: $showPrivacySheet) {
                                FullScreenModalView(url: URL(string: "https://thodea.com/policy/privacy")!)
                            }
                            .foregroundColor(.blue)
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.green)
                        Text("Check email to log in")
                            .font(.title2).foregroundColor(.white.opacity(0.85))
                            .padding(.top, 12)
                    }
                }
            }
            .padding()
        }
    }

    
    func signIn(provider: String) {
        //print("Sign in with \(provider)")
    }
    

    func userLogIn() {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        if emailPredicate.evaluate(with: email) {
            emailSent = true
            isError = false

            // Simulate email sending
            Task {
                await sendEmail(email: email)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    email = ""
                }
            }
        } else {
            emailCopy = email
            email = ""
            isError = true
            errorMessage = "Enter a valid email"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isError = false
                errorMessage = ""
                email = emailCopy
            }
        }
    }
    
    func sendEmail(email: String) async {
           // Simulated async email function
           //print("Sending email to \(email)")
       }
}

struct SocialLoginButton: View {
    let imageName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ImageView(imageURL: imageName, size: 40);
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
