//
//  DataCache.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/19/25.
//

import SwiftUI // or import Combine
import FirebaseFirestore

@MainActor
class FollowCache: ObservableObject {
    static let shared = FollowCache()
    
    // Create a small container for our cached data
    struct CachedFollowData {
        let users: [ProfileUserInfo]
        let lastDocument: DocumentSnapshot?
    }
    
    private init() {
        NotificationCenter.default.addObserver(
            forName: .userFollowInfoUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let targetUsername = userInfo["username"] as? String,
                  let change = userInfo["change"] as? Int else { return }
            
            // 👇 Extract currentUsername
            let currentUsername = userInfo["currentUsername"] as? String ?? ""
            
            Task { @MainActor in
                // 👇 Pass the full dictionary to access image/follower data
                self?.updateFollowerCount(targetUsername: targetUsername, currentUsername: currentUsername, delta: change, userInfoDict: userInfo)
            }
        }
    }
    
    @Published var storage: [String: CachedFollowData] = [:]
    
    func get(username: String, type: String) -> CachedFollowData? {
        return storage["\(username)_\(type)"]
    }
    
    func save(username: String, type: String, users: [ProfileUserInfo], lastDoc: DocumentSnapshot?) {
        storage["\(username)_\(type)"] = CachedFollowData(users: users, lastDocument: lastDoc)
    }
    
    func updateFollowerCount(targetUsername: String, currentUsername: String, delta: Int, userInfoDict: [AnyHashable: Any]) {
        
        // 1. Update the number integer globally (existing logic)
        for (key, data) in storage {
            var updatedUsers = data.users
            if let index = updatedUsers.firstIndex(where: { $0.username == targetUsername }) {
                var user = updatedUsers[index]
                user.followers = max(0, (user.followers ?? 0) + delta)
                updatedUsers[index] = user
                storage[key] = CachedFollowData(users: updatedUsers, lastDocument: data.lastDocument)
            }
        }
        
        // 2. Process Cached Array Removals/Additions
        let followingKey = "\(currentUsername)_following"
        let followersKey = "\(targetUsername)_followers"
        
        if delta == -1 {
            // Unfollow -> Remove Target from Current User's 'Following'
            if let data = storage[followingKey] {
                var newUsers = data.users
                newUsers.removeAll { $0.username == targetUsername }
                storage[followingKey] = CachedFollowData(users: newUsers, lastDocument: data.lastDocument)
            }
            // Unfollow -> Remove Current User from Target's 'Followers'
            if let data = storage[followersKey] {
                var newUsers = data.users
                newUsers.removeAll { $0.username == currentUsername }
                storage[followersKey] = CachedFollowData(users: newUsers, lastDocument: data.lastDocument)
            }
        } else if delta == 1 {
            // Follow -> Insert Target to Current User's 'Following'
            if let data = storage[followingKey] {
                if !data.users.contains(where: { $0.username == targetUsername }) {
                    let newUser = ProfileUserInfo(username: targetUsername, imageURL: userInfoDict["targetImage"] as? String, followers: userInfoDict["targetFollowers"] as? Int, thoughts: 0, followedAt: Date())
                    var newUsers = data.users
                    newUsers.insert(newUser, at: 0)
                    storage[followingKey] = CachedFollowData(users: newUsers, lastDocument: data.lastDocument)
                }
            }
            // Follow -> Insert Current User to Target's 'Followers'
            if let data = storage[followersKey] {
                if !data.users.contains(where: { $0.username == currentUsername }) {
                    let newUser = ProfileUserInfo(username: currentUsername, imageURL: userInfoDict["currentImage"] as? String, followers: userInfoDict["currentFollowers"] as? Int, thoughts: 0, followedAt: Date())
                    var newUsers = data.users
                    newUsers.insert(newUser, at: 0)
                    storage[followersKey] = CachedFollowData(users: newUsers, lastDocument: data.lastDocument)
                }
            }
        }
    }
}

@MainActor
class ProfileCache: ObservableObject {
    static let shared = ProfileCache()
    
    // This struct holds both the data and the potentially downloaded image
    struct CachedProfileData {
        var info: ProfileInfo
        var imageData: Data?
        var miniImageData: Data?
    }
    
    // Key = Username
    @Published var storage: [String: CachedProfileData] = [:]
    
    func get(username: String) -> CachedProfileData? {
        return storage[username]
    }
    
    func save(username: String, info: ProfileInfo, imageData: Data?, miniImageData: Data?) {
        storage[username] = CachedProfileData(info: info, imageData: imageData, miniImageData: miniImageData)
    }
    
    // Update follower count in cache without re-fetching
    func updateFollowerCount(username: String, delta: Int) {
        guard var data = storage[username] else { return }
        
        var updatedInfo = data.info
        let currentFollowers = updatedInfo.followers
        updatedInfo.followers = max(0, currentFollowers + delta)
        
        // If we are following them now (delta +1), set isFollowing to true, etc.
        if delta > 0 { updatedInfo.isFollowing = true }
        if delta < 0 { updatedInfo.isFollowing = false }
        
        data.info = updatedInfo
        storage[username] = data
    }
}


@MainActor
class ThoughtsCache: ObservableObject {
    static let shared = ThoughtsCache()
    
    struct CachedThoughtsData {
        let thoughts: [Thought]
        let lastDocument: DocumentSnapshot?
        let hasMore: Bool
    }
    
    // Keyed by the profile's username
    @Published private var storage: [String: CachedThoughtsData] = [:]
    
    func get(username: String) -> CachedThoughtsData? {
        return storage[username]
    }
    
    func save(username: String, thoughts: [Thought], lastDoc: DocumentSnapshot?, hasMore: Bool) {
        storage[username] = CachedThoughtsData(thoughts: thoughts, lastDocument: lastDoc, hasMore: hasMore)
    }
}
