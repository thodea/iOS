import SwiftUI
import PhotosUI

struct WebViewData: Identifiable {
    let id = UUID()
    let url: URL
}

struct ProfileView: View {
    @State private var userName: String = "John Doe" // Sample username
    @State private var userImage: String = "profile_picture"
    @State private var selectedTab: String = "thoughts"
    @State private var bioInfo: Bool = true
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var authViewModel: AuthViewModel // Add this
    @State private var webViewData: WebViewData?
    @State private var isImageMenuOpen = false
    //@State private var isUploading = false
    // 2. ADD STATE VARIABLES FOR PHOTO SELECTION
    @State private var showPhotosPicker = false
    @State private var selectedPickerItem: PhotosPickerItem? = nil
    @State private var profileImageData: Data? = nil
    @State private var isPreviewOpen = false
    let uploadService = UploadService(signedPostEndpoint: URL(string: "https://thodea.com/api/uploadURL")!)
    //@State private var isDeleting = false

    var body: some View {
        
        ZStack(alignment: .top) {
            Color(red: 17/255, green: 24/255, blue: 39/255)
            .ignoresSafeArea()
                VStack(spacing: 4) {
                    // Uploading overlay
                    
                    HStack() {
                        
                        VStack {
                            NavigationLink(destination: SettingsView()) {
                                SettingsSVG()
                                    .font(.headline)
                                    .frame(maxWidth: 50, maxHeight: .infinity, alignment: .leading)
                            }
                        }
                        
                        //.border(.green, width: 2)
                        if let user = viewModel.currentUser {
                            Text(user.username)
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else {
                            ProgressView() // or nothing
                        }
                        
                        ZStack(alignment: .topTrailing) {
                            // Envelope Image
                            
                            NavigationLink(destination: ChatsView()) {
                                Image(systemName: "envelope")
                                    .foregroundColor(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255))
                                    .font(.title2)
                                    .frame(maxWidth: 50, maxHeight: .infinity, alignment: .trailing)
                            }
                            
                            
                            // Orange Circle at top-right corner
                            /*Circle()
                             .fill(Color(red: 161 / 255, green: 98 / 255, blue: 7 / 255))
                             .frame(width: 10, height: 10)
                             .offset(x: 2, y: -2) */
                        }
                        .frame(width: 50, height: 24)// Adjust position if needed
                    }
                    .frame(maxWidth: .infinity, maxHeight: 30, alignment: .leading)
                    //.border(.gray, width: 4)
                    .padding(.bottom, 4)
                    
                    
                    HStack(spacing: 4) {
                        ZStack {
                            // Rounded rectangle with border and shadow
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.clear)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray, lineWidth: 1) // Border
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            // 3. LOGIC TO SHOW SELECTED IMAGE OR DEFAULT ICON
                            if let data = viewModel.profileImageData, let uiImage = UIImage(data: data) {
                                // Show the selected photo
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill() // Ensures photo fills the square
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12)) // Clips the overflowing image
                            } else {
                                // Smaller image inside the rounded rectangle
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(10) // Add padding to make it smaller
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 100, height: 100)
                        .onTapGesture {
                            if viewModel.profileImageData == nil {
                                // Directly open picker if no profile image
                                showPhotosPicker = true
                            } else {
                                // If image exists, open the menu
                                isImageMenuOpen = true
                            }
                        }
                        
                        
                        VStack() {
                            // 1. Followers Link
                            NavigationLink(destination: FollowsView(
                                username: viewModel.currentUser?.username ?? "",
                                listType: "followers",
                                dateDisabled: false
                            )) {
                                HStack {
                                    let followers = abs(viewModel.currentUser?.followers ?? 0)
                                    Text("\(formatNumber(followers)) \(followers == 1 ? "follower" : "followers")")
                                        .font(.system(size: 17)).fixedSize()
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(Color(red: 2 / 255, green: 132 / 255, blue: 199 / 255))
                                            .frame(height: 3)
                                            .padding(0)
                                        
                                        Rectangle()
                                            .fill(Color(red: 7 / 255, green: 89 / 255, blue: 133 / 255))
                                            .frame(width: 8, height: 8, alignment: .trailing)
                                            .padding(0)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                            .buttonStyle(.plain) // Prevents blue text coloring
                            
                            // 2. Following Link
                            NavigationLink(destination: FollowsView(
                                username: viewModel.currentUser?.username ?? "",
                                listType: "following",
                                dateDisabled: false
                            )) {
                                HStack {
                                    Text("\(formatNumber(viewModel.currentUser?.followings ?? 0)) following")
                                        .font(.system(size: 17)).fixedSize()
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(Color(red: 2 / 255, green: 132 / 255, blue: 199 / 255))
                                            .frame(height: 3)
                                            .padding(0)
                                        
                                        Rectangle()
                                            .fill(Color(red: 7 / 255, green: 89 / 255, blue: 133 / 255))
                                            .frame(width: 8, height: 8, alignment: .trailing)
                                            .padding(0)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                            .buttonStyle(.plain) // Prevents blue text coloring

                        }
                        .padding(.leading, 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 100) // Set height for row
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    
                    if let bio = viewModel.currentUser?.bio, !bio.isEmpty {
                        HStack {
                            Text(bio.toMarkdown())
                                .font(.system(size: 17)) // Adjust size to match styling
                                .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255)) // Matches text-gray-400
                                .lineLimit(3) // Matches max-h-[50px] + truncate behavior
                                .tint(.blue)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true) // Ensures text wraps properly
                                .environment(\.openURL, OpenURLAction { url in
                                    // We trigger the sheet by setting this variable to a new struct
                                    webViewData = WebViewData(url: url)
                                    return .handled
                                })
                            Spacer() // Pushes text to the left
                        }
                        .padding(.top, 6) // Matches mt-4
                        //.border(Color.red, width: 2)
                    }
                    
                    VStack {
                        HStack {
                            TabButton(title: "thoughts", selectedTab: $selectedTab, bioInfo: bioInfo, count: viewModel.currentUser?.thoughts ?? 0)
                            TabButton(title: "loved", selectedTab: $selectedTab, bioInfo: bioInfo, count: 0)
                            TabButton(title: "mentions", selectedTab: $selectedTab, bioInfo: bioInfo, count: 0)
                        }
                        .padding(.top, bioInfo ? 2 : 4)  // Adjust the margin based on `bioInfo`
                        .frame(maxHeight: 50)
                    }
                    
                    //.border(Color.green, width: 2)
                    
                }.padding()
                .sheet(item: $webViewData) { data in
                    FullScreenModalView(url: data.url)
                        .edgesIgnoringSafeArea(.all)
                }
                // 4. ATTACH THE PHOTO PICKER MODIFIER TO THE MAIN VIEW
                .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPickerItem, matching: .images)
                // 5. HANDLE DATA LOADING WHEN SELECTION CHANGES
                .onChange(of: selectedPickerItem) { newItem in
                    Task {
                        guard let item = newItem else { return }
                        
                        await MainActor.run {
                            //isImageMenuOpen = true
                            authViewModel.isUploading = true
                        }
                        
                        do {
                            // 🧹 If user already has an uploaded image → remove it first
                            if viewModel.profileImageData != nil {
                                try await viewModel.removeProfileImage(skipLocalCleanup: true)
                            }
                            
                            // Load new image data
                            guard let data = try? await item.loadTransferable(type: Data.self) else {
                                await MainActor.run { authViewModel.isUploading = false }
                                return
                            }
                            
                            let ext = await item.fileExtension() ?? "jpg"
                            await MainActor.run {
                                viewModel.profileImageData = data
                                viewModel.profileImageExtension = ext
                            }
                            
                            print("Loaded: \(ext)")
                            
                            // 🚀 Continue to upload new image
                            performImageUploadAndFinish()
                            
                        } catch {
                            print("Error replacing image: \(error)")
                            await MainActor.run {
                                authViewModel.isUploading = false
                                isImageMenuOpen = false
                            }
                        }
                    }
                }
                .fullScreenCover(isPresented: $isImageMenuOpen) {
                    ZStack {
                        
                        // 🔹 Background tap closes menu (same as onClick in React)
                        Color(red: 17/255, green: 24/255, blue: 39/255)
                            .ignoresSafeArea()
                            .onTapGesture {
                                if !authViewModel.isUploading {
                                    isImageMenuOpen = false
                                }
                            }
                        
                        // TOP-aligned menu
                        VStack(alignment: .center, spacing: 0) {
                            // Image Help
                            modalButton(title: "Image Help")
                            
                            // Preview
                            modalButton(title: "Preview") {
                                isImageMenuOpen = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isPreviewOpen = true
                                }
                            }
                            .padding(.top, 24)
                            
                            // Remove
                            modalButton(title: "Remove") {
                                Task {
                                    do {
                                        isImageMenuOpen = false
                                        await MainActor.run {authViewModel.isDeleting = true; authViewModel.isUploading = true }
                                        selectedPickerItem = nil
                                        try await authViewModel.removeProfileImage()
                                        
                                        await MainActor.run {
                                            authViewModel.isDeleting = false
                                            authViewModel.isUploading = false
                                            isImageMenuOpen = false
                                        }
                                    } catch {
                                        await MainActor.run {
                                            authViewModel.isDeleting = false
                                            authViewModel.isUploading = false
                                            isImageMenuOpen = false
                                        }
                                        print("Delete failed: \(error)")
                                    }
                                }
                            }
                            .padding(.top, 24)
                            
                            // Upload
                            modalButton(title: "Upload") {
                                // 1. Close the menu immediately
                                isImageMenuOpen = false
                                
                                // 2. Add a tiny delay to allow the menu to dismiss cleanly
                                // before the picker tries to present itself.
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    showPhotosPicker = true
                                }
                            }
                            .padding(.top, 24)
                            
                            Spacer()   // pushes buttons to start at top
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 30)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .background(Color.clear)
                    }
                    .background(Color.clear)
                }
                .fullScreenCover(isPresented: $isPreviewOpen) {
                    
                    // Check if the image data exists before showing the preview
                    if let data = viewModel.profileImageData, let uiImage = UIImage(data: data) {
                        
                        ZStack {
                            // 1. Full-screen background (like the white/black div in Next.js)
                            Color.black.opacity(0.95)
                                .ignoresSafeArea()
                            
                            // 2. The centered image
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            VStack {
                                HStack {
                                    Spacer()
                                    Button {
                                        isPreviewOpen = false
                                        // Optional: Re-open the Image Menu for 'Image Help' or 'Remove'
                                        isImageMenuOpen = true
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .symbolRenderingMode(.hierarchical)
                                            .font(.largeTitle)
                                            .foregroundColor(.blue)
                                            .foregroundStyle(.gray)
                                            .padding(2)
                                    }
                                }
                                Spacer()
                            }
                        }
                        // 4. Tap gesture on the whole view to close it and reopen the menu
                        .onTapGesture {
                            isPreviewOpen = false
                            // Re-open the Image Menu
                            isImageMenuOpen = true
                        }
                        
                    } else {
                        // Fallback if image data is somehow missing
                        Text("No image to preview")
                            .onAppear {
                                isPreviewOpen = false // Close the preview if no image exists
                            }
                    }
                }
        }.disabled(authViewModel.isUploading)
    }
    
    func performImageUploadAndFinish() {
        guard let data = viewModel.profileImageData,
              let username = viewModel.currentUser?.username else {
            // handle missing data
            return
        }

        Task {
            await MainActor.run { authViewModel.isUploading = true }
            do {
                // Use original file name if you have; fallback to "photo.jpg"
                let ext = viewModel.profileImageExtension ?? "jpg"
                let originalFilename = "photo.\(ext)"
                let ok = try await uploadService.uploadImageData(data, originalFilename: originalFilename, username: username)
                if ok {
                    // Build final public URL that matches your bucket path
                    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                    let remoteFilename = "https://storage.googleapis.com/thodea_assets/user/\(username)/asset\(timestamp).\(ext)" // match your canonical url pattern
                    // Option A: update Firestore directly
                    try await updateProfileUrlInFirestore(username: username, url: remoteFilename)

                    // Update UI state on main thread
                    await MainActor.run {
                        viewModel.profileImageData = data
                        authViewModel.isUploading = false
                        isImageMenuOpen = false
                        // set local view-model fields describing loaded:true etc.
                    }
                } else {
                    throw UploadError.uploadFailed
                }
            } catch {
                await MainActor.run {
                    authViewModel.isUploading = false
                    isImageMenuOpen = false
                }
                // show an alert
                print("Upload failed: \(error)")
            }
        }
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


