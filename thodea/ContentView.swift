import SwiftUI

struct ContentView: View {
    @State private var selectedNavItem: String = "feed" // Track selected tab
    
    var body: some View {
        NavigationStack {
            VStack {
                if selectedNavItem == "post" {PostView(selectedNavItem: $selectedNavItem)}
                if selectedNavItem == "feed" {FeedView()}
                if selectedNavItem == "search" {SearchView()}
                if selectedNavItem == "profile" {ProfileView()}
                if selectedNavItem == "login" {LoginView()}
                //if selectedNavItem == "settings" {SettingsView()}

                // Content view without tab items
                // or any other main content view you want to show initially

                Spacer() // This makes the content area flexible and pushes the footer to the bottom
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 17/255, green: 24/255, blue: 39/255))
            .foregroundColor(.white) // Set text color to white globally
            .overlay(
                Group {
                        if selectedNavItem != "login" {
                            Footer(selectedNavItem: $selectedNavItem)
                                .frame(maxWidth: .infinity)
                        }
                    },
                    alignment: .bottom
            ).edgesIgnoringSafeArea(.bottom)
            //.border(Color.green, width: 2)
        }
    }
}

#Preview {
    ContentView()
}
