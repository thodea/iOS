//
//  Interfaces.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/7/25.
//

import Foundation
import AVKit
import SwiftUI

struct Thought: Identifiable {
    let id = UUID() // Optional unique identifier for SwiftUI's List or ForEach
    var createdAt: Date?
    var createdBy: String
    var message: String
    var postId: Int
    var loved: Bool
    var loveCount: Int
    var lovedAt: Date?
    var commentCount: Int
    var seenCount: Int
    var clickCount: Int?
    var mentions: [String]
    var imageURL: String?
    var assetUrl: String
    var assetType: String
    var posterUrl: String
    var newAssetUrl: String
    var newPosterUrl: String
    var urlDescription: String
    var urlTitle: String
    var firstUrl: String?
    var profileDeleted: Bool?
}

struct User {
    var username: String
    var followers: Int?
    var followings: Int?
    var thoughts: Int?
    var chatRequest: Bool?
    var newChat: Bool?
    var bio: String?
    var registeredAt: Date
    var darkMode: Bool
    var following: [String]?
    var profileUrl: String?
    var profileMiniUrl: String?
    var deleted: Bool?
    
    init(
        username: String,
        registeredAt: Date,
        darkMode: Bool,
        followers: Int,
        followings: Int,
        thoughts: Int,
        profileMiniUrl: String?,
        profileUrl: String?,
        bio: String?
    ) {
        self.username = username
        self.registeredAt = registeredAt
        self.darkMode = darkMode
        self.followers = followers
        self.followings = followings   // FIX: map “following” → “followings”
        self.thoughts = thoughts
        self.profileMiniUrl = profileMiniUrl
        self.profileUrl = profileUrl
        self.bio = bio

        // Default optional values
        self.following = nil
        self.chatRequest = false
        self.newChat = false
        self.following = nil
        self.profileUrl = nil
        self.profileMiniUrl = nil
        self.deleted = false
    }
    
    // 1️⃣ Full initializer (for your ChatHelper mock data)
        init(
            username: String,
            followers: Int,
            followings: Int,
            thoughts: Int,
            chatRequest: Bool,
            newChat: Bool,
            bio: String?,
            registeredAt: Date,
            darkMode: Bool,
            following: [String]?,
            profileUrl: String?,
            profileMiniUrl: String?,
            deleted: Bool
        ) {
            self.username = username
            self.followers = followers
            self.followings = followings
            self.thoughts = thoughts
            self.chatRequest = chatRequest
            self.newChat = newChat
            self.bio = bio
            self.registeredAt = registeredAt
            self.darkMode = darkMode
            self.following = following
            self.profileUrl = profileUrl
            self.profileMiniUrl = profileMiniUrl
            self.deleted = deleted
        }
        
}

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let user: User
    let createdAt: Date
}

let mockThought = Thought(
    createdAt: Date(timeIntervalSince1970: 1734296943), // Converted from "December 14, 2024 at 11:49:03 AM UTC-5"
    createdBy: "nik",
    message: "It doesn’t help thodea.com that a billionaire google.com buys a social network. Now billionaires are managing all social networks, each one their own. Regular population will find it hard to relate themselves with the owners of social network, even Facebook is more of Ivy League story than a normal human can imagine how to pass through admissions. Do people use social networks to connect with their friends or it’s just another news channel for a few to be heard? It’s hard to imagine that a regular person is thinking same thing as these billionaires who have enormous power over population.",
    postId: -6,
    loved: true,
    loveCount: 1,
    lovedAt: nil, // No lovedAt provided
    commentCount: 0,
    seenCount: 3,
    clickCount: 0,
    mentions: [], // Empty array
    imageURL: "https://storage.googleapis.com/thodea_assets/user/nik/asset_1732579544022.webp",
    assetUrl: "https://storage.googleapis.com/thodea_assets/thoughts/-6/asset.jpg",
    assetType: "image/webp",
    posterUrl: "", // No posterUrl provided
    newAssetUrl: "https://storage.googleapis.com/thodea_assets/thoughts/-6/asset.webp",
    newPosterUrl: "", // No newPosterUrl provided
    urlDescription: "", // No urlDescription provided
    urlTitle: "", // No urlTitle provided
    firstUrl: nil, // Null maps to nil in Swift
    profileDeleted: nil // No profileDeleted info provided
)

struct GlobalOverlayView: View {
    @Binding var isUploading: Bool
    @Binding var isDeleting: Bool
    
    var body: some View {
        if isUploading {
            ZStack {
                // Background dimmer - covers the whole screen including safe areas
                Color(red: 17/255, green: 24/255, blue: 39/255)
                    .ignoresSafeArea()
                    .opacity(0.8)

                // Alert box content
                HStack(spacing: 12) { // 👈 Changed from VStack to HStack for one row
                    ProgressView()
                        .progressViewStyle(.circular)
                        // Use a light color for visibility against the dark background
                        .tint(.white)

                    Text(isDeleting ? "Deleting" : "Uploading")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .cornerRadius(14)
                .shadow(radius: 12)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.15), value: isUploading)
        }
    }
}


struct ProfileUserInfo: Identifiable, Codable {
    var id: String { username } // Swift needs an ID for Lists
    let username: String
    var imageURL: String?
    var deleted: Bool?
    var followers: Int?
    var thoughts: Int?
    var followedAt: Date?
}



// MARK: - DateWithFormattedTimeView
struct DateWithFormattedTimeView: View {
    
    // 1. Input: The initial date. This could be a Swift Date or a Unix timestamp (Double).
    // Assuming the input is a Date object, which is cleaner in Swift.
    // If your backend gives you an object with a 'seconds' property (like Firebase Timestamps),
    // you'll need a small wrapper struct or to convert it to a Date beforehand.
    // For this example, we'll assume it's a standard Swift Date object.
    let date: Date
    
    // 2. State: The displayed time string, updated by the timer.
    @State private var elapsedTimeString: String = ""
    
    // 3. Timer: Used to trigger the update function every second.
    // We use a custom timer publisher.
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Initializer to set the initial state when the view is created
    init(date: Date) {
        self.date = date
        // Initialize the state variable immediately upon creation
        _elapsedTimeString = State(initialValue: formatElapsedTime(since: date))
    }
    
    var body: some View {
        Text(elapsedTimeString)
            // Apply styling similar to the original component's className
            .font(.caption) // Smaller font
            .italic()       // Italic text
            .frame(alignment: .trailing) // Adjust alignment if needed
        
        // 4. Timer Handling:
        // When the timer fires, the .onReceive block executes updateTime().
        // This is equivalent to the setInterval logic in React's useEffect.
            .onReceive(timer) { _ in
                updateTime()
            }
            // Use .onAppear to ensure the initial value is calculated correctly,
            // though we already did this in the init. It's good practice.
            .onAppear {
                updateTime()
            }
    }
    
    // MARK: - Helper Functions
    
    /// Updates the `elapsedTimeString` state property with the new formatted time.
    private func updateTime() {
        self.elapsedTimeString = formatElapsedTime(since: self.date)
    }
    
    /// Converts the elapsed time into a human-readable "time ago" string.
    /// - Parameter date: The original date/time of the comment.
    /// - Returns: A string like "5 minutes ago".
    private func formatElapsedTime(since date: Date) -> String {
        // TimeInterval is a Double representing the time in seconds between two Dates.
        let timeInterval = Date().timeIntervalSince(date)
        let seconds = Int(timeInterval)
        
        // The original logic handles cases by checking from largest to smallest unit.
        
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        
        if days > 0 {
            return days == 1 ? "\(days) day ago" : "\(days) days ago"
        } else if hours > 0 {
            return hours == 1 ? "\(hours) hour ago" : "\(hours) hours ago"
        } else if minutes > 0 {
            return minutes == 1 ? "\(minutes) minute ago" : "\(minutes) minutes ago"
        } else {
            return seconds == 1 ? "\(seconds) second ago" : "\(seconds) seconds ago"
        }
    }
}
