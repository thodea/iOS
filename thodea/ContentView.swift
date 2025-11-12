import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var selectedNavItem: String = "login"
    
    var body: some View {
        NavigationStack {
            VStack {
                // Show appropriate view based on auth state
                if authViewModel.userSession != nil {
                    
                    if authViewModel.layerOneLoaded == false  {
                        LoginView(isSigningIn: true) // show with loaderview instead
                    } else {
                        if authViewModel.userExistsInFirestore == false {
                            // ISSUE: when user exists in Firestore, this flushes before Feed
                            SetupView()
                        } else {
                            if authViewModel.isLoadingUser {
                                Loader()
                            } else {
                                switch selectedNavItem {
                                case "post": PostView(selectedNavItem: $selectedNavItem)
                                case "feed": FeedView()
                                case "search": SearchView()
                                case "profile": ProfileView()
                                default: FeedView()
                                }
                            }
                        }
                    }
                   
                    
                } else {
                    if authViewModel.isProcessing == false  {
                        LoginView(isSigningIn: false)
                    } else {
                        LoginView(isSigningIn: true)
                    }
                }
                
                Spacer()
                
                // Show footer only when logged in
                if authViewModel.currentUser != nil {
                    Footer(selectedNavItem: $selectedNavItem)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 17/255, green: 24/255, blue: 39/255))
            .ignoresSafeArea(.all, edges: .bottom)
            .foregroundColor(.white)
            .onAppear {
                // Automatically show feed when user is logged in
                if authViewModel.userSession != nil {
                    selectedNavItem = "feed"
                }
            }
            .onChange(of: authViewModel.userSession) { newUserSession in
                // Update navigation when auth state changes
                if newUserSession != nil {
                    selectedNavItem = "feed"
                } else {
                    selectedNavItem = "login"
                }
            }
        }.environmentObject(authViewModel)
    }
}

#Preview {
    ContentView()
}
