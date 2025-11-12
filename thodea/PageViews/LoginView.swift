//
//  LoginView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 2/28/25.
//


import SwiftUI
import WebKit
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @State private var email: String = ""
    @State private var emailCopy: String = ""
    @State private var emailSent: Bool = false
    @State private var webURLToPresent: URL? // Use an Optional URL
    @State private var isError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isSigningIn: Bool
    @EnvironmentObject var viewModel: AuthViewModel
    
    init(isSigningIn: Bool = false) {
        _isSigningIn = State(initialValue: isSigningIn)
        // Note: The '_isSigningIn' syntax is required to initialize a State property
    }
    
    var body: some View {
        ZStack {
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
                                // ----------------------------------------------------
                                // ✨ New Modifiers for Lowercase Input ✨
                                // ----------------------------------------------------
                                // 1. Prevents the device's keyboard from capitalizing the first letter
                                .textInputAutocapitalization(.never)
                                // 2. Converts the input to lowercase every time the text changes
                                .onChange(of: email) { newValue in
                                    // This closure receives the new value after the text changes
                                    email = newValue.lowercased()
                                }
                                // ----------------------------------------------------
                                .overlay(
                                    VStack {
                                        Spacer()
                                        Rectangle()
                                            .fill(Color(red: 30 / 255, green: 58 / 255, blue: 138 / 255))
                                            .frame(height: 3)
                                    }
                                    .padding(.horizontal)
                                )
                                .padding(.bottom, 12)
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
                                        // **KEY CHANGE**: Set the URL and the sheet will automatically appear
                                        webURLToPresent = URL(string: "https://thodea.com/policy/terms")
                                    }
                                    .foregroundColor(.blue)
                                
                                Text("and").foregroundColor(.gray)
                                    .font(.system(size: 18))
                                
                                Text("Privacy Policy")
                                    .onTapGesture {
                                        // **KEY CHANGE**: Set the URL and the sheet will automatically appear
                                        webURLToPresent = URL(string: "https://thodea.com/policy/privacy")
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
                .sheet(item: $webURLToPresent) { url in
                    // Use the url from the binding unwrapped as 'url'
                    FullScreenModalView(url: url)
                        // .presentationDetents is good for a partial slide up,
                        // but SFSafariViewController is typically Full Screen
                }
                
                .overlay {
                    if isSigningIn {
                        LoaderView() // <-- Calls the custom LoaderView below
                    }
                }
        }
    }
    
    
    func signIn(provider: String) {
        print("Sign in with \(provider)")
            
        switch provider.lowercased() {
        case "google":
            Task {
                await viewModel.signInWithGoogle()
            }
        case "microsoft":
            Task {
                await viewModel.signInWithMicrosoft()
            }
        case "yahoo":
            Task {
                await viewModel.signInWithYahoo()
            }
        default:
            print("❌ Unsupported provider:", provider)
        }
    }
    
    
    func userLogIn() {
        // 1. Convert the email to lowercase for consistent validation and usage
        let lowercaseEmail = email.lowercased()
        
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        // Note: The regex is case-insensitive by default in NSPredicate when using the standard pattern,
        // but converting the input to lowercase is still best practice for comparison/storage.
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        // 2. Use the lowercaseEmail for evaluation
        if emailPredicate.evaluate(with: lowercaseEmail) {
            emailSent = true
            isError = false
            
            // Use the lowercaseEmail for the actual API call/email sending
            Task {
                await viewModel.sendEmail(to: lowercaseEmail)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    // Keep 'email' as the original input or set it to lowercase if you prefer the UI to reflect the lowercase version
                    email = ""
                }
            }
        } else {
            // ... (Error handling remains the same)
            emailCopy = email // The original, potentially mixed-case input is saved here
            email = ""
            isError = true
            errorMessage = "Enter a valid email"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isError = false
                errorMessage = ""
                email = emailCopy
            }
        }
    }
    
}
    /*func sendEmail(email: String) async {
        sendSignInLink(to: email.lowercased())
           // Simulated async email function
           print("Sending email to \(email.lowercased())")
       }
}*/

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


struct LoaderView: View {
    
    // State to control the dot animation index (0, 1, or 2)
    @State private var dotIndex: Int = 0
    // Timer to update the dotIndex every 0.3 seconds
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        // 1. Muting Background Layer
        ZStack {
            Color.black.opacity(0.4) // Adjust opacity for "muting" effect

            
            // 2. Centered Loader
            HStack(spacing: 8) {
                // Dot 1
                Circle()
                    .fill(.white)
                    .frame(width: 10, height: 10)
                    .opacity(dotIndex == 0 ? 1.0 : 0.3)
                
                // Dot 2
                Circle()
                    .fill(.white)
                    .frame(width: 10, height: 10)
                    .opacity(dotIndex == 1 ? 1.0 : 0.3)

                // Dot 3
                Circle()
                    .fill(.white)
                    .frame(width: 10, height: 10)
                    .opacity(dotIndex == 2 ? 1.0 : 0.3)
            }
            .onReceive(timer) { _ in
                // Cycle the dotIndex (0 -> 1 -> 2 -> 0 -> ...)
                withAnimation(.easeInOut(duration: 0.3)) {
                    dotIndex = (dotIndex + 1) % 3
                }
            }
        }.ignoresSafeArea()
    }
}

// Extension to conform URL to Identifiable for the .sheet(item:) modifier
extension URL: @retroactive Identifiable {
    public var id: String {
        self.absoluteString
    }
}
