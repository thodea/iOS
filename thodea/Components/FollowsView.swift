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
    @Published var isLoadingInitial: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var hasMore: Bool = true // Assume true initially
    @Published var didLoadOnce = false

    private var lastDocument: DocumentSnapshot? = nil
    private let service = FollowService()
    private let cache = FollowCache.shared
    private let pageSize = 4 // As requested
    private let maxHardLimit = 50 // 🎯 The Hard Limit
    
    func loadInitial(username: String, listType: String) async {
        // 🔒 Prevent reloading if we already have data
        guard !didLoadOnce else { return }
        didLoadOnce = true

        isLoadingInitial = true
        
        // 1. Reset pagination state on refresh/initial load
        self.users = []
        self.lastDocument = nil
        self.hasMore = true
        
        // 2. Check Cache
        // 1. Check Cache first
        if let cachedData = cache.get(username: username, type: listType) {
            self.users = Array(cachedData.users.prefix(maxHardLimit))
            self.lastDocument = cachedData.lastDocument
            // If we have fewer than pageSize, we know there's no more to load
            self.hasMore = self.users.count < maxHardLimit && (cachedData.users.count >= pageSize)
            
            isLoadingInitial = false
            return // Exit early because we have everything we need
        }

        do {
            let (fetchedUsers, lastDoc) = try await service.getFollow(
                user: username,
                type: listType,
                maxLim: pageSize,
                snap: nil
            )
            
            self.users = fetchedUsers
            self.lastDocument = lastDoc
            self.cache.save(username: username, type: listType, users: fetchedUsers, lastDoc: lastDoc)

            if self.users.count >= maxHardLimit || fetchedUsers.count < pageSize {
                self.hasMore = false
            } else {
                self.hasMore = fetchedUsers.count == pageSize
            }
        } catch {
            print("❌ Initial load error:", error)
        }
        
        isLoadingInitial = false
    }
    
    func loadMore(username: String, listType: String) async {
        guard !isLoadingMore, hasMore, !isLoadingInitial, users.count < maxHardLimit else {
            self.hasMore = false
            return
        }
        isLoadingMore = true
        print("⚡️ Triggering Load More...")

        do {
            // Calculate how many more we are allowed to fetch to not exceed 8
            let remainingSpace = maxHardLimit - users.count
            let limitToFetch = min(pageSize, remainingSpace)

            let (newUsers, lastDoc) = try await service.getFollow(
                user: username,
                type: listType,
                maxLim: limitToFetch,
                snap: self.lastDocument
            )
            
            if !newUsers.isEmpty {
                // 1. Append new users to the existing local list
                self.users.append(contentsOf: newUsers)
                self.lastDocument = lastDoc
                
                // 2. 🔥 CACHE THE ENTIRE UPDATED LIST
                // We save the full 'self.users' array so the cache stays in sync
                // with the UI state.
                self.cache.save(username: username,
                               type: listType,
                               users: self.users,
                               lastDoc: lastDoc)
            }
            

            if self.users.count >= maxHardLimit || newUsers.count < limitToFetch {
                self.hasMore = false
            }
            
        } catch {
            print("❌ Load more error:", error)
        }
        
        isLoadingMore = false
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
                            
                            if vm.isLoadingInitial && vm.users.isEmpty {
                                ProgressView()
                                    .tint(.blue)
                                    .scaleEffect(1.2)
                                    .frame(maxWidth: .infinity)
                            }
                            //[PROD] ForEach(vm.users) { userInfo in mockUsers
                            // 🔹 THE LOOP
                            ForEach(Array(vm.users.enumerated()), id: \.element.id) { index, userInfo in
                                let isDeleted = userInfo.deleted ?? false
                                
                                Button(action: {
                                    if !isDeleted {
                                        print("Navigate to \(userInfo.username)")
                                    }
                                }) {
                                    UserRowView(userInfo: userInfo, dateDisabled: dateDisabled)
                                }
                                .padding(.horizontal)
                                .buttonStyle(PlainButtonStyle())
                                .disabled(isDeleted)
                                .opacity(isDeleted ? 0.6 : 1.0)
                                // 👇 MAGIC HAPPENS HERE
                                .onAppear {
                                    // Trigger load when the user sees the 3rd to last item
                                    // This creates a "smooth" infinite scroll effect
                                    if index == vm.users.count - 1 && vm.hasMore {
                                        Task {
                                            await vm.loadMore(username: username, listType: listType)
                                        }
                                    }
                                }
                            }
                            
                            if vm.isLoadingMore {
                                ProgressView()
                                    .tint(.blue)
                                    .scaleEffect(1.2)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    
                    // 2. The "Load More" Footer & Threshold Trigger
                    /*if vm.hasMore {
                        GeometryReader { geo -> Color in
                            let bottomPos = geo.frame(in: .global).maxY
                            let minY = geo.frame(in: .global).minY
                            let height = UIScreen.main.bounds.height
                            let threshold = height + 300 // The 300px threshold
                            let diff = bottomPos - height
                            // TRACING
                            // If the footer position (minY) is less than ScreenHeight + 300,
                            // it means the footer is within 300px of entering the screen (or is already on screen).
                            
                            DispatchQueue.main.async {
                                if diff < 600 {
                                    // Trace
                                    print("📉 Scroll Trace: Footer Y (\(Int(diff))) < Threshold (\(Int(600))) -> LOADING")
                                    
                                    Task {
                                        await vm.loadMore(username: username, listType: listType)
                                    }
                                }
                            }
                            return Color.clear
                        }
                        .frame(height: 50) // Give the reader some height
                    }*/
                    
                }
                .padding(.bottom, 32)

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // <--- Add maxHeight here
            .ignoresSafeArea()
            //Spacer() // Pushes the whole block to the top of the view

        }
        .onAppear {
            Task {
                await vm.loadInitial(username: username, listType: listType)
            }
        }
        //.padding(.horizontal)
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


// Extracted Row View to keep main body clean
struct UserRowView: View {
    let userInfo: ProfileUserInfo
    let dateDisabled: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // 1. Profile Image
                Group {
                    if let urlString = userInfo.imageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            VStack(spacing: 4) {
                                Capsule().fill(Color.gray.opacity(0.5)).frame(width: 8, height: 8)
                                Capsule().fill(Color.gray.opacity(0.5)).frame(width: 12, height: 8)
                            }
                        }
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.trailing, 8)
                
                // 2. Info
                HStack(alignment: .center, spacing: 6) {
                    Text(userInfo.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255))
                    Text("|").font(.system(size: 16)).opacity(0.45)
                    Text(formatNumber(userInfo.thoughts ?? 0)) // Simplified format for brevity
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255))
                }
                
                Spacer()
                
                // 3. Stats
                HStack(spacing: 4) {
                    Text(formatNumber(userInfo.followers ?? 0))
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255))
                    Image(systemName: "person.2.fill")
                        .resizable().aspectRatio(contentMode: .fit).frame(width: 20, height: 20)
                        .foregroundColor(Color.blue.opacity(0.8))
                }
            }
            .frame(minHeight: 50)
            .padding(.horizontal, 8)
            .padding(.top, 3)
            
            if !dateDisabled, let date = userInfo.followedAt {
                HStack {
                    Spacer()
                    DateWithFormattedTimeView(date: date) // Simplified date
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 2)
            }
        }
        
        .background(Color(red: 17/255, green: 24/255, blue: 39/255))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.1), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
        //.padding(.bottom, 200)
    }
}
