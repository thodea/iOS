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
    
    @Published var storage: [String: CachedFollowData] = [:]
    
    func get(username: String, type: String) -> CachedFollowData? {
        return storage["\(username)_\(type)"]
    }
    
    func save(username: String, type: String, users: [ProfileUserInfo], lastDoc: DocumentSnapshot?) {
        storage["\(username)_\(type)"] = CachedFollowData(users: users, lastDocument: lastDoc)
    }
    
    func updateFollowerCount(targetUsername: String, delta: Int) {
        // Iterate over all cached lists to find this user and update them everywhere
        for (key, data) in storage {
            if let index = data.users.firstIndex(where: { $0.username == targetUsername }) {
                var updatedUsers = data.users
                var user = updatedUsers[index]
                user.followers = (user.followers ?? 0) + delta
                updatedUsers[index] = user
                
                // Save back to storage
                storage[key] = CachedFollowData(users: updatedUsers, lastDocument: data.lastDocument)
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
