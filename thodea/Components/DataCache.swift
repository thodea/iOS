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
