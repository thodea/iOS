//
//  DataCache.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/19/25.
//

import SwiftUI // or import Combine

@MainActor
class FollowCache: ObservableObject {
    static let shared = FollowCache() // Singleton for easy access
    
    // Key format: "username_followers" or "username_following"
    @Published var storage: [String: [ProfileUserInfo]] = [:]
    
    func get(username: String, type: String) -> [ProfileUserInfo]? {
        return storage["\(username)_\(type)"]
    }
    
    func save(username: String, type: String, users: [ProfileUserInfo]) {
        storage["\(username)_\(type)"] = users
    }
}
