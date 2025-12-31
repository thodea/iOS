import SwiftUI
import PhotosUI

struct WebViewData: Identifiable {
    let id = UUID()
    let url: URL
}

struct ProfileView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var authViewModel: AuthViewModel // Add this

    var body: some View {
        
        ZStack(alignment: .top) {
            Color(red: 17/255, green: 24/255, blue: 39/255)
            .ignoresSafeArea()
            ProfileBasicView(username: authViewModel.currentUser?.username ?? "")
        }.disabled(authViewModel.isUploading)
    }
}


struct SettingsSVG: View {
    var body: some View {
        ZStack {
            // Outer Circle
            
            Circle()
                .fill(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255)) // Transparent outer circle
                .frame(width: 26, height: 26)
        

            // Middle Circle
            Circle()
                .fill(Color(red: 17/255, green: 24/255, blue: 39/255)) // Red middle circle
                .frame(width: 22, height: 22)
            
            Circle()
                .fill(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255)) // Transparent outer circle
                .frame(width: 10, height: 10)
                .offset(y: -4)
            
            // Inner Circle
            Circle()
                .fill(Color(red: 17/255, green: 24/255, blue: 39/255)) // Gray inner circle
                .frame(width: 6, height: 6)
                .offset(y: -4)
            
            Circle()
                .fill(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255)) // Transparent outer circle
                .frame(width: 22, height: 22)
                .offset(y: 13)
                .mask(
                    Circle()
                        .frame(width: 22, height: 22) // Defines the cropping area
                )
            
            Circle()
                .fill(Color(red: 17/255, green: 24/255, blue: 39/255)) // Gray inner circle
                .frame(width: 20, height: 20)
                .offset(y: 14)
                .mask(
                    Circle()
                        .frame(width: 22, height: 22) // Defines the cropping area
                )
     
        }
        .frame(width: 24, height: 24)
        
    }
    
}

struct TabButton: View {
    var title: String
    @Binding var selectedTab: String
    var bioInfo: Bool
    var count: Int
    
    var body: some View {
        VStack {
            Button(action: {
                selectTab(title: title)
            }) {
                VStack(spacing: 4) {
                    HStack {
                        Text(title)
                            .fontWeight(selectedTab == title ? .medium : .regular).fixedSize()
                        if count > 0 {
                            Text("\(formatNumber(count))").fixedSize()
                        } else if title == "thoughts" {
                            Text("0")
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, selectedTab == title ? 0 : 5)
                    .background(selectedTab == title ? Color.clear : Color.clear)
                    .cornerRadius(5)
                    .foregroundColor(.white.opacity(0.9))
                    if selectedTab == title {
                        BottomBorder()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    private func selectTab(title: String) {
        selectedTab = title
    }
}

struct BottomBorder: View {
    let color: Color = Color(red: 7/255, green: 89/255, blue: 133/255)
    let width: CGFloat = 2
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: width)
            .edgesIgnoringSafeArea(.horizontal)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}

@ViewBuilder
func modalButton(title: String, action: (() -> Void)? = nil) -> some View {

    let isHelp = (title == "Image Help")

    let bgColor = isHelp
        ? Color.black
        : Color(red: 3/255, green: 105/255, blue: 161/255)

    let textColor = Color(red: 229/255, green: 231/255, blue: 235/255)

    Button(action: { if !isHelp { action?() } }) {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: 150)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(bgColor)
            )
            .foregroundColor(textColor)
    }
    .buttonStyle(.plain)
    .allowsHitTesting(!isHelp)
}


