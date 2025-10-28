import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var selectedNavItem: String = "login"
    
    var body: some View {
        NavigationStack {
            VStack {
                // Show appropriate view based on auth state
                if authViewModel.userSession != nil {
                    // User is logged in - show main app
                    if selectedNavItem == "post" { PostView(selectedNavItem: $selectedNavItem) }
                    if selectedNavItem == "feed" { FeedView() }
                    if selectedNavItem == "search" { SearchView() }
                    if selectedNavItem == "profile" { ProfileView() }
                } else {
                    // User is not logged in - show login
                    LoginView()
                }
                
                Spacer()
                
                // Show footer only when logged in
                if authViewModel.userSession != nil {
                    Footer(selectedNavItem: $selectedNavItem)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 17/255, green: 24/255, blue: 39/255))
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
