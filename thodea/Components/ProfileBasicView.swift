//
//  ProfileBasicView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/28/25.
//

import SwiftUI
import PhotosUI
import Firebase // Ensure you have Firebase imports for the fetch logic
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import OSLog

struct ProfileBasicView: View {
    let username: String
    let isNavigated: Bool
    @State private var userName: String = "John Doe" // Sample username
    @State private var userImage: String = "profile_picture"
    @State private var selectedTab: String = "thoughts"
    @State private var bioInfo: Bool = true
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var webViewData: WebViewData?
    @State private var isImageMenuOpen = false
    //@State private var isUploading = false
    // 2. ADD STATE VARIABLES FOR PHOTO SELECTION
    @State private var showPhotosPicker = false
    @State private var selectedPickerItem: PhotosPickerItem? = nil
    @State private var profileImageData: Data? = nil
    @State private var isPreviewOpen = false
    //let uploadService = UploadService(signedPostEndpoint: URL(string: "https://www.thodea.com/api/uploadURL")!)
    
    @EnvironmentObject var bunnyService: BunnyUploadService // <--- Use the shared instance
    
    @State private var isLoading: Bool = true
    // 1. Check if we are looking at our own profile
    var isCurrentUser: Bool {
        return viewModel.currentUser?.username == username
    }
    @State private var fetchedUser: ProfileInfo?
    @State private var fetchedProfileImageData: Data?
    @State private var fetchedProfileMiniImageData: Data?

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
    
    var displayFollowers: Int? {
        if isCurrentUser {
            return viewModel.currentUser?.followers
        }
        // If fetchedUser is nil, this returns nil (the "loading" state)
        return fetchedUser?.followers
    }

    var displayFollowing: Int? {
        if isCurrentUser {
            return viewModel.currentUser?.followings
        }
        return fetchedUser?.following
    }
    
    var displayThoughts: Int {
        isCurrentUser ? (viewModel.currentUser?.thoughts ?? 0) : (fetchedUser?.thoughts ?? 0)
    }
    
    var displayImageData: Data? {
        isCurrentUser ? viewModel.profileImageData : fetchedProfileImageData
    }
    
    var miniImageData: Data? {
        isCurrentUser ? viewModel.profileMiniImageData : fetchedProfileMiniImageData
    }
    
    // Helper within the View or as a private func
    private func followerText(for count: Int?) -> String {
        guard let count = count else { return "" } // Show nothing while loading
        let formatted = formatNumber(abs(count))
        let label = abs(count) == 1 ? "follower" : "followers"
        return "\(formatted) \(label)"
    }

    private func followingText(for count: Int?) -> String {
        guard let count = count else { return "" }
        return "\(formatNumber(count)) following"
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
                                    .compositingGroup()
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
                            
                        if let urlStr = isCurrentUser ? viewModel.currentUser?.profileUrl : fetchedUser?.profileUrl,
                               let url = URL(string: urlStr) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color.clear
                                }
                                .frame(width: 100, height: 100)
                            }
                        
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
                            if !isNavigated {
                                if viewModel.profileImageData == nil {
                                    showPhotosPicker = true
                                } else {
                                    isImageMenuOpen = true
                                }
                            } else {
                                if viewModel.profileImageData != nil {
                                    isPreviewOpen = true
                                }
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
                        let followersCount = abs(displayFollowers ?? 0)
                        let hasFollowers = followersCount > 0
                    
                        NavigationLink(destination: FollowsView(
                            username: username,
                            listType: "followers",
                            dateDisabled: false
                        )) {
                            HStack {
                                Text(followerText(for: displayFollowers))
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
                        .allowsHitTesting(hasFollowers)
                        
                        // 2. Following Link
                        let followingCount = abs(displayFollowing ?? 0)
                        let hasFollowing = followingCount > 0
                
                        NavigationLink(destination: FollowsView(
                            username: username,
                            listType: "following",
                            dateDisabled: false
                        )) {
                            HStack {
                                Text(followingText(for: displayFollowing))
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
                        .allowsHitTesting(hasFollowing)
                        
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
                    await loadInitial()
                    //await loadUserProfile()
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
                    guard let item = newItem else {
                        Logger.media.warning("Picker dismissed without selection.")
                        return
                    }
                    
                    Logger.media.info("🏁 Starting image replacement process...")
                    
                    await MainActor.run {
                        viewModel.isUploading = true
                    }
                    
                    do {
                        // 1. Cleanup old image
                        if viewModel.profileImageData != nil {
                            Logger.media.debug("Existing profile data found. Initiating removal.")
                            try await viewModel.removeProfileImage(skipLocalCleanup: true)
                            Logger.media.info("Successfully removed old profile image from storage.")
                        }
                        
                        // 2. Load and validate data
                        Logger.media.debug("Loading transferable data from picker...")
                        // Pro Tip: Avoid 'try?' so we can catch the specific loading error
                        let data = try await item.loadTransferable(type: Data.self)
                        
                        guard let data = data else {
                            Logger.media.error("Failed to extract Data from PhotosPickerItem.")
                            await MainActor.run { viewModel.isUploading = false }
                            return
                        }
                        
                        let ext = await item.fileExtension() ?? "jpg"
                        
                        await MainActor.run {
                            viewModel.profileImageData = data
                            viewModel.profileImageExtension = ext
                            Logger.media.info("Local state updated: Data loaded (\(data.count) bytes), extension: \(ext)")
                        }
                        
                        // 3. Hand off to upload
                        Logger.media.info("🚀 Passing control to performImageUploadAndFinish()")
                        performImageUploadAndFinish()
                        
                    } catch {
                        // Logs the full error details to the system console
                        Logger.media.fault("❌ Image Replacement Failed: \(error.localizedDescription, privacy: .public)")
                        
                        await MainActor.run {
                            viewModel.isUploading = false
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
                            if !viewModel.isUploading {
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
                                    await MainActor.run {viewModel.isDeleting = true }
                                    selectedPickerItem = nil
                                    try await viewModel.removeProfileImage()
                                    
                                    await MainActor.run {
                                        viewModel.isDeleting = false
                                        viewModel.isUploading = false
                                        isImageMenuOpen = false
                                    }
                                } catch {
                                    await MainActor.run {
                                        viewModel.isDeleting = false
                                        viewModel.isUploading = false
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
                            NavigationLink(destination: MessagesView(username: username, miniImageData: miniImageData)) {
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
    
    /// Checks cache first; if missing, fetches from network.
    func loadInitial() async {
        // 1. Check if data exists in Cache
        if let cachedData = ProfileCache.shared.get(username: username) {
            //print("🟢 [ProfileBasicView] Cache HIT for \(username)")
            
            // Immediately populate UI with cached data
            self.fetchedUser = cachedData.info
            self.fetchedProfileImageData = cachedData.imageData
            self.fetchedProfileMiniImageData = cachedData.miniImageData
            self.isLoading = false
            return
        }
        
        // 2. If no cache, fetch from network
        //print("🟡 [ProfileBasicView] Cache MISS for \(username). Fetching...")
        await loadUserProfile()
    }
    
    func loadUserProfile() async {
        isLoading = true
        do {
            // Fetch the profile struct (DB + Firestore)
            let profile = try await fetchProfile(targetUsername: username, currentUsername: viewModel.currentUser?.username)
            
            var profileImage: Data? = nil
            var profileMiniImage: Data? = nil

            // Fetch the Image if URL exists
            if let urlString = profile.profileUrl, let url = URL(string: urlString) {
                let (data, _) = try await URLSession.shared.data(from: url)
                profileImage = data
            }
            
            // Fetch the Image if URL exists
            if let miniUrlString = profile.profileMiniUrl, let miniUrl = URL(string: miniUrlString) {
                let (data, _) = try await URLSession.shared.data(from: miniUrl)
                profileMiniImage = data
            }
            
            // 3. Update State on Main Thread
            await MainActor.run {
                self.fetchedUser = profile
                self.fetchedProfileImageData = profileImage
                self.fetchedProfileMiniImageData = profileMiniImage
                self.isLoading = false
                
                // 4. Save to Cache immediately after fetching
                ProfileCache.shared.save(username: username, info: profile, imageData: profileImage, miniImageData: profileMiniImage)
                //print("💾 [ProfileBasicView] Saved \(username) to Cache")
            }
        } catch {
            print("❌ Failed to load user profile: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    func performImageUploadAndFinish() {
        // 1. Ensure we have the raw data and user context
        guard let rawData = viewModel.profileImageData,
              let username = viewModel.currentUser?.username else {
            return
        }

        Task {
            do {
                // 2. Start UI Loading State
                await MainActor.run { viewModel.isUploading = true }

                // 3. JPEG COMPRESSION STEP
                // Convert Data -> UIImage -> Compressed JPEG Data
                guard let uiImage = UIImage(data: rawData),
                      let compressedData = uiImage.jpegData(compressionQuality: 0.80) else {
                    throw UploadError.compressionFailed
                }

                // 4. Define metadata
                let ext = "jpg" // Since we forced JPEG compression, extension is now jpg
                
                // 5. Upload to Bunny
                // The service now handles the signing and the PUT request
                let finalCdnUrl = try await bunnyService.uploadImage(
                    data: compressedData,
                    username: username,
                    fileExtension: ext
                )

                // Check if we got a URL back (since the function returns String?)
                guard let urlToSave = finalCdnUrl else {
                    throw UploadError.uploadFailed
                }
                
                viewModel.primeCache(with: compressedData, for: urlToSave)

                try await updateProfileUrlInFirestore(username: username, url: urlToSave)
                                    
                // 7. Success Cleanup
                await MainActor.run {
                    // Keep the compressed data in memory for the local UI to save RAM
                    viewModel.profileImageData = compressedData
                    viewModel.isUploading = false
                    isImageMenuOpen = false
                    bunnyService.progress = 0.0
                    bunnyService.isUploading = false
                }
                
            } catch {
                await MainActor.run {
                    viewModel.isUploading = false
                    bunnyService.progress = 0.0
                    bunnyService.isUploading = false}
                    print("Upload failed: \(error.localizedDescription)")
                    // Trigger your error alert here
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
            if abs(myCurrentCount) >= 250 {
                print("🚫 Max 250 following limit reached")
                showLimitAlert = true
                return
            }
        }
        
        // 2. OPTIMISTIC UPDATE (Update UI immediately)
        let delta = isCurrentlyFollowing ? -1 : 1
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
        
        ProfileCache.shared.updateFollowerCount(username: targetUser.username, delta: delta)
        
        NotificationCenter.default.post(
            name: .userFollowInfoUpdated,
            object: nil,
            userInfo: [
                "username": targetUser.username,
                "change": delta
            ]
        )
    
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
                    
                    // 🔥 REVERT THE BROADCAST
                    ProfileCache.shared.updateFollowerCount(username: targetUser.username, delta: -delta)
                    // We send the OPPOSITE change (-delta) to undo the list update
                    NotificationCenter.default.post(
                        name: .userFollowInfoUpdated,
                        object: nil,
                        userInfo: [
                            "username": targetUser.username,
                            "change": -delta
                        ]
                    )
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


