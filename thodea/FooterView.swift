import SwiftUI

struct Footer: View {
    @Binding var selectedNavItem: String
    
    var body: some View {
        HStack {
            // Post button
            Button(action: { selectedNavItem = "post" }) {
                HStack {
                    PostIcon(selected: selectedNavItem == "post")
                        .frame(width: 55, height: 55) // Make sure the icon is small enough
                        .padding(.horizontal, 14)
                        .padding(.vertical, 2)
                }
                .background(
                    selectedNavItem == "post" ? Color.blue.opacity(0.2) : Color.clear
                )
                .clipShape(Capsule())
                .opacity(0.5) // Optional to mimic `opacity-50`
            }
            Spacer()
            // Feed button
            Button(action: { selectedNavItem = "feed" }) {
                HStack {
                    FeedIcon(selected: selectedNavItem == "feed")
                        .frame(width: 55, height: 55) // Make sure the icon is small enough
                        .padding(.horizontal, 14)
                        .padding(.vertical, 2)
                }
                .background(
                    selectedNavItem == "feed" ? Color.blue.opacity(0.2) : Color.clear
                )
                .clipShape(Capsule())
                .opacity(0.5) // Optional to mimic `opacity-50`
            }
            Spacer()
            // Search button
            Button(action: { selectedNavItem = "search" }) {
                HStack {
                    SearchIcon(selected: selectedNavItem == "search")
                        .frame(width: 55, height: 55) // Make sure the icon is small enough
                        .padding(.horizontal, 14)
                        .padding(.vertical, 2)
                }
                .background(
                    selectedNavItem == "search" ? Color.blue.opacity(0.2) : Color.clear
                )
                .clipShape(Capsule())
                .opacity(0.5) // Optional to mimic `opacity-50`
            }
            Spacer()
            // Profile button
            Button(action: { selectedNavItem = "profile" }) {
                HStack {
                    ProfileIcon(selected: selectedNavItem == "profile")
                        .frame(width: 55, height: 55) // Make sure the icon is small enough
                        .padding(.horizontal, 14)
                        .padding(.vertical, 2)
                }
                .background(
                    selectedNavItem == "profile" ? Color.blue.opacity(0.2) : Color.clear
                )
                .clipShape(Capsule())
                .opacity(0.5) // Optional to mimic `opacity-50`
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .cornerRadius(0)
        .shadow(radius: 5)
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        //.border(Color.green, width: 2)
    }
}



// Post Icon (SVG-like)
struct PostIcon: View {
    var selected: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                            .frame(width: 4, height: 40)
                            .foregroundColor(.gray.opacity(0.5))
            
            RoundedRectangle(cornerRadius: 8)
                            .frame(width: 40, height: 4)
                            .foregroundColor(.gray.opacity(0.5))
        }
        //.border(Color.green, width: 2)
    }
}

struct FeedIcon: View {
    var selected: Bool
    
    var body: some View {
        ZStack {
            // Vertical Line 1
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 4, height: 32)
                .position(x: 15, y: 27)
                .foregroundColor(.gray.opacity(0.5))
            
            // Vertical Line 2
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 4, height: 45)
                .position(x: 27.5, y: 27)
                .foregroundColor(.gray.opacity(0.5))
            
            // Vertical Line 3
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 4, height: 32)
                .position(x: 40, y: 27)
                .foregroundColor(.gray.opacity(0.5))
        }
    }
}

// Search Icon (SVG-like)
struct SearchIcon: View {
    var selected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.5), lineWidth: 4)
                .frame(width: 40, height: 40)
            
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 16, height: 16)
        }
    }
    
}

struct ProfileIcon: View {
    var selected: Bool
    
    var body: some View {
        ZStack {
            // Vertical Line with rounded corners
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 4, height: 40) // Adjust height as needed
                .position(x: 28, y: 27)
                .foregroundColor(.gray.opacity(0.5))
        }
    }
}
