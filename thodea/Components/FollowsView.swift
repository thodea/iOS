//
//  FollowsView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/6/25.
//




import SwiftUI
import FirebaseFirestore

@MainActor
class FollowListViewModel: ObservableObject {
    @Published var users: [ProfileUserInfo] = []
    @Published var isLoading: Bool = false // 1. Added loading state
    
    private let service = FollowService()
    private let cache = FollowCache.shared

    func loadInitial(username: String, listType: String) async {
        
        if let cachedUsers = cache.get(username: username, type: listType) {
            self.users = cachedUsers
            // Optional: return early if you don't want to refresh,
            // or continue to fetch "fresh" data in the background.
            return
        }

        isLoading = true // 2. Start loading
        do {
            let result = try await service.getFollow(
                user: username,
                type: listType,
                maxLim: 4,
                snap: nil
            )
            self.users = result
            cache.save(username: username, type: listType, users: result)
        } catch {
            print("❌ Follow load error:", error)
        }
        isLoading = false // 3. Stop loading
    }
}

struct FollowsView: View {
    let username: String
    let listType: String // "followers" or "following"
    let dateDisabled: Bool
    var mockUsers: [ProfileUserInfo] = [
            ProfileUserInfo(
                username: "MockUser_1",
                imageURL: nil,
                followers: 150,
                thoughts: 12,
                followedAt: Date() // 1 day ago
            ),
            ProfileUserInfo(
                username: "Design_Guru",
                imageURL: nil,
                followers: 2300,
                thoughts: 89,
                followedAt: Date().addingTimeInterval(-60 * 3) // 7 days ago
            ),
            ProfileUserInfo(
                username: "SwiftUI_Fan",
                imageURL: nil,
                followers: 45,
                thoughts: 2,
                followedAt: Date().addingTimeInterval(-60 * 60 * 24 * 30) // 30 days ago
            )
        ]
    
    var users: [ProfileUserInfo] = []
    private let service = FollowService()
    @StateObject private var vm = FollowListViewModel()


    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel // Add this
    

    var body: some View {

        // Equivalent to the main outer div: w-full max-w-[700px] mx-auto

        VStack(spacing: 16) {


            // Equivalent to flex flex-col w-full...

            VStack(alignment: .leading, spacing: 0) {

                // 🔹 LIST OF FOLLOWERS/FOLLOWING
                ZStack(alignment: .top) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            
                            //[PROD] ForEach(vm.users) { userInfo in
                            ForEach(vm.users) { userInfo in
                                let isDeleted = userInfo.deleted ?? false
                                
                                // Card Container
                                // Equivalent to: div onClick... className="... shadow-md border rounded-lg ..."
                                Button(action: {
                                    if !isDeleted {
                                        // navProfile(profile.username)
                                        print("Navigate to \(userInfo.username)")
                                    }
                                }) {
                                    VStack(spacing: 0) {
                                        
                                        // --- Top Section (Image | Info | Stats) ---
                                        HStack(spacing: 0) {
                                            
                                            // 1. Profile Image Section
                                            // Equivalent to: w-[40px] h-[40px] rounded-md
                                            Group {
                                                if let urlString = userInfo.imageURL, let url = URL(string: urlString) {
                                                    AsyncImage(url: url) { image in
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: 40, height: 40)
                                                            .clipShape(RoundedRectangle(cornerRadius: 6)) // rounded-md
                                                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                                    } placeholder: {
                                                        Color.gray.opacity(0.2)
                                                            .frame(width: 40, height: 40)
                                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                                    }
                                                } else {
                                                    // Fallback "Skeleton" Style
                                                    // Matches the div with gray-400 dots inside
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                                            .background(Color.clear)
                                                        
                                                        VStack(spacing: 4) {
                                                            Capsule().fill(Color.gray.opacity(0.5)).frame(width: 8, height: 8)
                                                            Capsule().fill(Color.gray.opacity(0.5)).frame(width: 12, height: 8)
                                                        }
                                                    }
                                                    .frame(width: 40, height: 40)
                                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                                }
                                            }
                                            .padding(.trailing, 8) // pl-2 pr-2 logic
                                            
                                            // 2. Center Info: Username | Thoughts
                                            HStack(alignment: .center, spacing: 6) {
                                                Text(userInfo.username)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255))
                                                
                                                Text("|")
                                                    .font(.system(size: 16))
                                                    .opacity(0.45)
                                                    .foregroundColor(Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255))
                                                
                                                // Thoughts Count
                                                Text(formatNumber(userInfo.thoughts ?? 0))
                                                    .font(.system(size: 16))
                                                    .foregroundColor(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255))
                                            }
                                            
                                            Spacer()
                                            
                                            // 3. Right Stats: Followers + Blue Icon
                                            HStack(spacing: 4) {
                                                Text(formatNumber(userInfo.followers ?? 0))
                                                    .font(.system(size: 16))
                                                    .foregroundColor(Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255)) // text-gray-500
                                                
                                                // SVG Replacement: Closest SF Symbol to the user group icon
                                                Image(systemName: "person.2.fill")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 20, height: 20)
                                                // dark:text-blue-600 text-blue-400
                                                    .foregroundColor(Color.blue.opacity(0.8))
                                            }
                                        }
                                        .frame(minHeight: 50)
                                        .padding(.horizontal, 8)
                                        .padding(.top, 3)
                                        
                                        // Adjust bottom padding if date is shown or not
                                        
                                        // --- Bottom Section (Date) ---
                                        if !dateDisabled {
                                            HStack(spacing: 0) {
                                                Spacer()
                                                // Equivalent to: <DateWithFormattedTime ... />
                                                if let date = userInfo.followedAt {
                                                    DateWithFormattedTimeView(date: date)
                                                        .font(.caption)
                                                        .foregroundColor(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255))
                                                }
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.bottom, 2)
                                        }
                                    }
                                    .background(Color(red: 17/255, green: 24/255, blue: 39/255))
                                    .cornerRadius(8) // rounded-lg
                                    // Border logic: dark:border-gray-800
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                    )
                                    // Shadow logic: shadow-md
                                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
                                }
                                .buttonStyle(PlainButtonStyle()) // Removes default tap gray-out
                                .disabled(isDeleted)
                                .opacity(isDeleted ? 0.6 : 1.0) // Visual cue for deleted
                            }
                        }
                    }
                    
                    // 2. The Loader layer (on top)
                    if vm.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)
                            .padding(.top, 10) // Adjust this to position it exactly where you want
                    }
                    
                }
            }

            .frame(maxWidth: 700) // max-w-[700px]

            Spacer() // Pushes the whole block to the top of the view

        }
        .onAppear {
            Task {
                await vm.loadInitial(username: username, listType: listType)
            }
        }
        .padding(.horizontal)
        .padding(.top, 2)
        .frame(maxWidth: .infinity).background(Color(red: 17/255, green: 24/255, blue: 39/255)).foregroundColor(.white.opacity(0.9))
        .foregroundColor(.white.opacity(0.9))
        .navigationBarBackButtonHidden(true) // Hides the default back button
        .navigationBarItems(leading:

            HStack(spacing: 8) {
                // Custom Back Button
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue.opacity(0.8))
                }

                // Dynamic Title Left-Aligned next to Caret

                HStack {
                    Text(username)
                        .font(.system(size: 18, weight: .semibold)) // Bold username
                        .foregroundColor(.white.opacity(0.9))

                    Text("/ \(listType)")
                        .font(.system(size: 18, weight: .regular)) // Regular listType
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}



// Preview structure for development environment

#Preview {
    
    FollowsView(username: "JohnDoe", listType: "followers",
                dateDisabled: false)
        .environmentObject(AuthViewModel())
}
