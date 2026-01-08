//
//  ProfileBasicView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/28/25.
//

import SwiftUI
import PhotosUI
import Firebase // Ensure you have Firebase imports for the fetch logic
import FirebaseDatabase
import FirebaseFirestore

struct ProfileBasicView: View {
    let username: String
    let isNavigated: Bool
    @State private var userName: String = "John Doe" // Sample username
    @State private var userImage: String = "profile_picture"
    @State private var selectedTab: String = "thoughts"
    @State private var bioInfo: Bool = true
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var authViewModel: AuthViewModel // Add this
    @Environment(\.presentationMode) var presentationMode
    @State private var webViewData: WebViewData?
    @State private var isImageMenuOpen = false
    //@State private var isUploading = false
    // 2. ADD STATE VARIABLES FOR PHOTO SELECTION
    @State private var showPhotosPicker = false
    @State private var selectedPickerItem: PhotosPickerItem? = nil
    @State private var profileImageData: Data? = nil
    @State private var isPreviewOpen = false
    let uploadService = UploadService(signedPostEndpoint: URL(string: "https://thodea.com/api/uploadURL")!)
    
    @State private var isLoading: Bool = true
    // 1. Check if we are looking at our own profile
    var isCurrentUser: Bool {
        return viewModel.currentUser?.username == username
    }
    @State private var fetchedUser: ProfileInfo?
    @State private var fetchedProfileImageData: Data?
    //@State private var isDeleting = false

    // TEST [REMOVE]
    @State private var isFollowingLocal: Bool = false
    private let followService = Follow()
    @State private var showLimitAlert = false // 🔔 For the 250 limit
    
    private var hasProfileUrl: Bool {
        if isCurrentUser {
            // If it's me, check my local view model
            guard let url = viewModel.currentUser?.profileUrl else { return false }
            return !url.isEmpty
        } else {
            // If it's another user:
            // 1. If fetchedUser is nil, we are still loading profile info -> Return true (Wait)
            // 2. If fetchedUser is loaded, check if they have a URL
            guard let user = fetchedUser else { return true }
            guard let url = user.profileUrl else { return false }
            return !url.isEmpty
        }
    }
    
    var displayBio: String? {
        isCurrentUser ? viewModel.currentUser?.bio : fetchedUser?.bio
    }
    
    var displayFollowers: Int {
        isCurrentUser ? (viewModel.currentUser?.followers ?? 0) : (fetchedUser?.followers ?? 0)
    }
    
    var displayFollowing: Int {
        isCurrentUser ? (viewModel.currentUser?.followings ?? 0) : (fetchedUser?.following ?? 0)
    }
    
    var displayThoughts: Int {
        isCurrentUser ? (viewModel.currentUser?.thoughts ?? 0) : (fetchedUser?.thoughts ?? 0)
    }
    
    var displayImageData: Data? {
        isCurrentUser ? viewModel.profileImageData : fetchedProfileImageData
    }
    
    var body: some View {
        
        ZStack {
            // 🔹 Screen background
            Color(red: 17/255, green: 24/255, blue: 39/255)
                .ignoresSafeArea()
            
            VStack(spacing: 4) {
                // Uploading overlay
                
                
                if isCurrentUser && !isNavigated {
                    HStack() {
                        
                        //if viewModel.currentUser?.username == username {
                        VStack {
                            NavigationLink(destination: SettingsView()) {
                                SettingsSVG()
                                    .font(.headline)
                                    .frame(maxWidth: 50, alignment: .leading)
                            }
                        }
                        
                        //.border(.green, width: 2) if username !== viewModel.currentUser.username
                        Text(username)
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        ZStack(alignment: .topTrailing) {
                            // Envelope Image
                            
                            NavigationLink(destination: ChatsView()) {
                                Image(systemName: "envelope")
                                    .foregroundColor(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255))
                                    .font(.title2)
                                    .frame(maxWidth: 50, alignment: .trailing)
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
                }
                
                HStack(spacing: 4) {
                    ZStack {
                        // Rounded rectangle with border and shadow
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .frame(width: 100, height: 100)
                            .shadow(color: Color.black.opacity(0.6), radius: 4, x: 0, y: 2)
                        
                        // 3. LOGIC TO SHOW SELECTED IMAGE OR DEFAULT ICON
                        if let data = displayImageData, let uiImage = UIImage(data: data) {
                            // Show the selected photo
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill() // Ensures photo fills the square
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12)) // Clips the overflowing image
                        } else if hasProfileUrl {
                            // STATE B: URL exists (Loading) -> Show Transparent
                            // This prevents the "person.fill" from flashing while waiting for download
                            Color.clear
                            
                        } else {
                            // STATE C: No URL exists at all -> Show Default Person Icon
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .padding(10)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 100, height: 100)
                    .onTapGesture {
                        if isCurrentUser {
                            if viewModel.profileImageData == nil {
                                showPhotosPicker = true
                            } else {
                                isImageMenuOpen = true
                            }
                        } else {
                            // For other users, maybe just open preview
                            if displayImageData != nil {
                                isPreviewOpen = true
                            }
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
                                let followers = abs(displayFollowers)
                                Text("\(formatNumber(followers)) \(followers == 1 ? "follower" : "followers")")
                                    .font(.system(size: 17)).fixedSize()
                                    .foregroundColor(.white.opacity(0.9))
                                
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
                                Text("\(formatNumber(displayFollowing)) following")
                                    .font(.system(size: 17)).fixedSize()
                                    .foregroundColor(.white.opacity(0.9))
                                
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
                        
                        if !isCurrentUser {
                            
                            let amIFollowing = fetchedUser?.isFollowing ?? false
                                                        
                            FollowActionRow(isFollowing: amIFollowing) {
                                var transaction = Transaction()
                                transaction.animation = nil

                                withTransaction(transaction) {
                                    handleFollowToggle()
                                    //isFollowingLocal.toggle()
                                }
                            }
                            .disabled(isLoading)
                            .opacity(isLoading ? 0.5 : 1)
                            .frame(maxHeight: .infinity, alignment: .center)
                        }

                    }
                    .padding(.leading, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: 100) // Set height for row
                .padding(.top, 4)
                .padding(.bottom, 4)
                
                if let bio = displayBio, !bio.isEmpty {
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
                Spacer()
            }
            .padding(isCurrentUser && !isNavigated ? [.all] : [.horizontal, .bottom])
            // --- ALERTS & SHEETS ---
            .alert("Max 250 following", isPresented: $showLimitAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You cannot follow more than 250 users.")
            }
            .task {
                // Only fetch if we are NOT the current user
                if !isCurrentUser {
                    await loadUserProfile()
                }
            }
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
                if let data = displayImageData, let uiImage = UIImage(data: data) {
                    
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
                                    if isCurrentUser { isImageMenuOpen = true}
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
                        if isCurrentUser { isImageMenuOpen = true}
                    }
                    
                } else {
                    // Fallback if image data is somehow missing
                    Text("No image to preview")
                        .onAppear {
                            isPreviewOpen = false // Close the preview if no image exists
                        }
                }
            }
            //.border(.red, width: 2)
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isNavigated {
                    // The Back Button (Leading)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.blue.opacity(0.8))
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        Text(username)
                            .font(.system(size: 18, weight: .bold))
                    }
                        
                    if !isCurrentUser {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink(destination: ChatsView()) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255))
                                    .font(.title2)
                                    .scaleEffect(0.8)
                                    .frame(maxWidth: 50, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func loadUserProfile() async {
        isLoading = true
        do {
            // Fetch the profile struct (DB + Firestore)
            let profile = try await fetchProfile(targetUsername: username, currentUsername: viewModel.currentUser?.username)
            
            await MainActor.run {
                self.fetchedUser = profile
            }
            
            // Fetch the Image if URL exists
            if let urlString = profile.profileUrl, let url = URL(string: urlString) {
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    self.fetchedProfileImageData = data
                }
            }
        } catch {
            print("❌ Failed to load user profile: \(error)")
        }
        await MainActor.run { isLoading = false }
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
    
    func handleFollowToggle() {
            guard let myUsername = viewModel.currentUser?.username,
                  let targetUser = fetchedUser else { return }
            
            let isCurrentlyFollowing = targetUser.isFollowing
            let myCurrentCount = viewModel.currentUser?.followings ?? 0
            
            // 1. LIMIT CHECK
            // Only check if we are attempting to Follow (currently NOT following)
            if !isCurrentlyFollowing {
                if myCurrentCount >= 250 {
                    print("🚫 Max 250 following limit reached")
                    showLimitAlert = true
                    return
                }
            }
            
            // 2. OPTIMISTIC UPDATE (Update UI immediately)
            // Flip the boolean
            fetchedUser?.isFollowing.toggle()
            
            // Update the counts visually
            if isCurrentlyFollowing {
                // We are unfollowing: Decrease
                fetchedUser?.followers -= 1
                viewModel.currentUser?.followings = (viewModel.currentUser?.followings ?? 0) - 1
            } else {
                // We are following: Increase
                fetchedUser?.followers += 1
                viewModel.currentUser?.followings = (viewModel.currentUser?.followings ?? 0) + 1
            }
            
            // 3. SERVICE CALL
            Task {
                do {
                    try await followService.followUser(
                        userToFollow: targetUser.username,
                        userFollowing: myUsername,
                        isFollowing: isCurrentlyFollowing // Pass the OLD state
                    )
                    print("✅ Successfully \(isCurrentlyFollowing ? "unfollowed" : "followed") \(targetUser.username)")
                    
                    // Optional: Force a background refresh to ensure consistency
                    // await loadUserProfile()
                    
                } catch {
                    print("❌ Follow action failed: \(error)")
                    
                    // 4. REVERT UI ON FAILURE
                    await MainActor.run {
                        fetchedUser?.isFollowing = isCurrentlyFollowing // Reset to old state
                        
                        // Revert counts
                        if isCurrentlyFollowing {
                            fetchedUser?.followers += 1
                            viewModel.currentUser?.followings = (viewModel.currentUser?.followings ?? 0) + 1
                        } else {
                            fetchedUser?.followers -= 1
                            viewModel.currentUser?.followings = (viewModel.currentUser?.followings ?? 0) - 1
                        }
                    }
                }
            }
        }
   
}


#Preview {
    ProfileBasicView(username: "delete", isNavigated: false)
        .environmentObject(AuthViewModel())
}

struct RemoveIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color(red: 2 / 255, green: 132 / 255, blue: 199 / 255), lineWidth: 2)
                .frame(width: 20, height: 20)

            Rectangle()
                .fill(Color(red: 192/255, green: 192/255, blue: 192/255))
                .frame(width: 10, height: 2)
                .cornerRadius(5)
        }
    }
}

struct AddIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color(red: 2 / 255, green: 132 / 255, blue: 199 / 255), lineWidth: 2)
                .frame(width: 20, height: 20)

            Rectangle()
                .fill(Color(red: 192/255, green: 192/255, blue: 192/255))
                .frame(width: 10, height: 2)
                .cornerRadius(5)

            Rectangle()
                .fill(Color(red: 192/255, green: 192/255, blue: 192/255))
                .frame(width: 2, height: 10)
                .cornerRadius(5)
        }
    }
}

struct FollowActionRow: View {
    let isFollowing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Spacer()   // ⬅️ pushes content to the right
                Text(isFollowing ? "Unfollow" : "Follow")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                if isFollowing {
                    RemoveIcon()
                } else {
                    AddIcon()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}




struct Follow {
    private let fdb = Firestore.firestore()
    private let rdb = Database.database().reference()
    
    // Equivalent to your NextJS `followUser`
    func followUser(userToFollow: String, userFollowing: String, isFollowing: Bool) async throws {
        if !isFollowing {
            // MARK: - Follow Logic
            
            // 1. Update Realtime DB Counters (Atomic Increment)
            let updates: [AnyHashable: Any] = [
                "user/\(userToFollow)/followers": ServerValue.increment(-1),
                "user/\(userFollowing)/following": ServerValue.increment(-1)
            ]
            try await rdb.updateChildValues(updates)
            
            // 2. Set New Follower (Firestore Subcollection)
            let followerData: [String: Any] = [
                "username": userFollowing,
                "followedAt": FieldValue.serverTimestamp()
            ]
            try await fdb.collection("user").document(userToFollow).collection("followers").document(userFollowing).setData(followerData)
            
            // 3. Set New Following (Firestore Subcollection)
            let followingData: [String: Any] = [
                "username": userToFollow,
                "followedAt": FieldValue.serverTimestamp()
            ]
            try await fdb.collection("user").document(userFollowing).collection("following").document(userToFollow).setData(followingData)
            
            // 4. Update Following Array (Firestore Array Union)
            try await fdb.collection("user").document(userFollowing).updateData([
                "following": FieldValue.arrayUnion([userToFollow])
            ])
            
        } else {
            // MARK: - Unfollow Logic
            
            // 1. Update Realtime DB Counters
            let updates: [AnyHashable: Any] = [
                "user/\(userToFollow)/followers": ServerValue.increment(1),
                "user/\(userFollowing)/following": ServerValue.increment(1)
            ]
            try await rdb.updateChildValues(updates)
            
            // 2. Delete Documents
            try await fdb.collection("user").document(userToFollow).collection("followers").document(userFollowing).delete()
            try await fdb.collection("user").document(userFollowing).collection("following").document(userToFollow).delete()
            
            // 3. Remove from Following Array
            try await fdb.collection("user").document(userFollowing).updateData([
                "following": FieldValue.arrayRemove([userToFollow])
            ])

        }
    }
    
}


