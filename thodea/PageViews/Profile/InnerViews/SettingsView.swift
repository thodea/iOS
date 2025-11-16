//
//  SettingsView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/26/24.
//

//
//  SearchView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/22/24.
//

import SwiftUI
import WebKit
import FirebaseDatabase


struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel // Add this
    // State to manage the confirmation modal
    @State private var showConfirmation: Bool = false
    @State private var pendingAction: ActionType? = nil
    @State private var userCount: Int = 0 // Track selected tab
    @State private var showSafariView = false
    @State private var selectedURL: URL?
    @State private var isDeleting: Bool = false
    
    // Enum to define the possible actions requiring confirmation
    enum ActionType {
        case logout
        case delete
        
        var confirmationMessage: String {
            switch self {
            case .logout:
                return "LOG OUT?"
            case .delete:
                return "DELETE ACCOUNT?"
            }
        }
    }

    var body: some View {
            VStack(spacing: 16) {
                // Search TextField
                HStack(){
                    BioButton()
                }.frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Button(action: {
                        pendingAction = .logout
                        showConfirmation = true
                    }) {
                        Text("LOG OUT")
                            .padding(4).padding(.horizontal, 4)
                            .background(Color(red: 147 / 255, green: 197 / 255, blue: 253 / 255)) // Background color
                            .foregroundColor(.black.opacity(0.9)) // Text color
                            .cornerRadius(2) // Rounded corners
                            .fontWeight(.bold)
                            .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)// Bold text
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                HStack {
                    Button(action: {
                       pendingAction = .delete
                       showConfirmation = true
                   }) {
                        Text("DELETE")
                            .padding(4).padding(.horizontal, 4) // Add padding for button-like appearance
                            .background(Color(red: 252 / 255, green: 165 / 255, blue: 165 / 255)) // Background color
                            .foregroundColor(.black) // Text color
                            .cornerRadius(2) // Rounded corners
                            .fontWeight(.bold) // Bold text
                            .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
        
                HStack(){
                    Text("users: \(userCount)")
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8).font(.system(size: 19)).foregroundColor(.white.opacity(0.6))
                
                // --- NEW ABOUT BUTTON ADDED HERE ---
                HStack {
                    Button(action: {
                        selectedURL = URL(string: "https://thodea.com/about") // Use your actual About URL
                        showSafariView = true
                    }) {
                        Text("About")
                            .padding(4).padding(.horizontal, 4)
                            // Applying styling similar to your Next.js Tailwind classes (from-indigo-400 to-blue-300)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color(red: 129/255, green: 140/255, blue: 248/255), Color(red: 147/255, green: 197/255, blue: 253/255)]), startPoint: .top, endPoint: .bottomLeading)
                            )
                            .foregroundColor(Color(red: 31/255, green: 41/255, blue: 55/255))
                            .cornerRadius(2) // Rounded corners
                            .fontWeight(.bold)
                            .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                // ------------------------------------
                
                Spacer()

                // Terms of Service and Privacy Policy Links
                HStack(spacing: 16) {

                   Text("Terms")
                        .onTapGesture {
                            selectedURL = URL(string: "https://thodea.com/policy/terms")
                            showSafariView = true
                        }
                        .sheet(isPresented: $showSafariView) {
                                    if let url = selectedURL {
                                        FullScreenModalView(url: url)
                                    } else {
                                        Text("Invalid URL")
                                    }
                                } 
                       .foregroundColor(.blue)
                                        
                    Text("Privacy")
                        .onTapGesture {
                            selectedURL = URL(string: "https://thodea.com/policy/privacy")
                            showSafariView = true
                        }
                        .sheet(isPresented: $showSafariView) {
                                    if let url = selectedURL {
                                        FullScreenModalView(url: url)
                                    } else {
                                        Text("Invalid URL")
                                    }
                                }
                        .foregroundColor(.blue)

                }
                
                .font(.system(size: 20))
                .frame(maxWidth: .infinity, alignment: .center)
                //.border(.green, width: 2)
                
            }
            .onChange(of: selectedURL) { newURL in }
            .padding()
            .frame(maxWidth: .infinity).background(Color(red: 17/255, green: 24/255, blue: 39/255)).foregroundColor(.white.opacity(0.9))
            .foregroundColor(.white.opacity(0.9))
            .navigationBarBackButtonHidden(true) // Hides the default back button
                .navigationBarItems(leading: Button(action: {
                    self.presentationMode.wrappedValue.dismiss() // Custom back button action
                }) {
                    Image(systemName: "chevron.left") // Custom back button icon
                        .foregroundColor(.blue.opacity(0.8)) // Color of the icon
                })
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchUserCount()
            }
            // Overlay for both the loader and the custom confirmation modal
            .overlay {
                if isDeleting {
                    // Show Loader for Deleting action
                    LoaderView()
                } else if showConfirmation, let action = pendingAction {
                    // Show Confirmation Modal
                    ConfirmationModalView(
                        message: action.confirmationMessage,
                        onConfirm: {
                            // Execute the pending action
                            switch action {
                            case .logout:
                                authViewModel.signOut()
                                presentationMode.wrappedValue.dismiss()
                                print("LOG OUT confirmed")
                            case .delete:
                                Task {
                                    isDeleting = true // Start loading state
                                    await authViewModel.deleteAccount()
                                    presentationMode.wrappedValue.dismiss()
                                    isDeleting = false // End loading state
                                    print("DELETE confirmed")
                                }
                            }
                            // Hide the modal regardless of action
                            showConfirmation = false
                            pendingAction = nil
                        },
                        onCancel: {
                            // Cancel the action and hide the modal
                            showConfirmation = false
                            pendingAction = nil
                            print("Action cancelled")
                        }
                    )
                }
            }
            .toolbar{
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
           


    }
    func fetchUserCount() {
        let ref = Database.database().reference().child("users")
        
        ref.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                let count = Int(snapshot.value as? Int ?? 0)

                DispatchQueue.main.async {
                    self.userCount = count
                }
            } else {
                DispatchQueue.main.async {
                    self.userCount = 0
                }
            }
        }
    }
}




struct BioButton: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("Add bio")
                .font(.title3)
                .fixedSize()
                .fontWeight(.bold)
                //.border(.red, width: 2)
            
            //rgb(147 197 253
            Circle()
                .fill(Color(red: 147/255, green: 197/255, blue: 253/255)) // Set the color of the circle to blue
                .frame(width: 10, height: 10, alignment: .leading)
                .padding(.horizontal, 8)
                //.border(.green, width: 2)// Set a fixed size for the circle
        }
        //.border(.green, width: 2) // Border for visualization
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator // Set the navigation delegate
        webView.isOpaque = true // Allow transparency
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        var urlString = url.absoluteString
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        if let validURL = URL(string: urlString) {
            let request = URLRequest(url: validURL)
            uiView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        private var spinner: UIActivityIndicatorView?

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // Show spinner when the page starts loading
            if spinner == nil {
                spinner = UIActivityIndicatorView(style: .large)
                spinner?.color = UIColor(red: 17/255, green: 24/255, blue: 39/255, alpha: 1) // Set custom color
                spinner?.center = webView.center
                spinner?.startAnimating()
                webView.addSubview(spinner!)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Hide spinner when the page finishes loading
            spinner?.stopAnimating()
            spinner?.removeFromSuperview()
            spinner = nil
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            // Hide spinner if the page fails to load
            spinner?.stopAnimating()
            spinner?.removeFromSuperview()
            spinner = nil
        }
    }
}

struct ConfirmationModalView: View {
    let message: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        // Full screen, semi-transparent background (the "layer")
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Tapping outside cancels the action
                    onCancel()
                }
            
            // The modal content box
            VStack(spacing: 15) {
                // Text replicating:
                // <div className="flex flex-row bg-transparent text-white font-bold rounded-sm min-w-[130px] text-center items-center justify-center">{modalText}</div>
                Text(message)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                
                // Buttons replicating:
                // <div className="flex flex-row mt-4 text-black font-bold rounded-sm min-w-[150px] text-center items-center justify-center">...</div>
                HStack(spacing: 16) {
                    // YES Button (Confirm)
                    Button(action: onConfirm) {
                        Text("Yes")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255).opacity(0.7)) // purple-400 opacity 70
                            .foregroundColor(.black)
                            .cornerRadius(4)
                            .shadow(color: .black, radius: 4, x: 0, y: 2)
                    }
                    
                    // NO Button (Cancel)
                    Button(action: onCancel) {
                        Text("No")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(red: 8 / 255, green: 145 / 255, blue: 178 / 255)) // cyan-600
                            .foregroundColor(.black)
                            .cornerRadius(4)
                            .shadow(color: .black, radius: 4, x: 0, y: 2)
                    }
                }
                .frame(minWidth: 150) // min-w-[150px] equivalent
            }
            .padding(20)
            .background(Color(red: 17/255, green: 24/255, blue: 39/255)) // Dark background for the modal itself
            .cornerRadius(10)
            .padding(.horizontal, 40)
        }
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
