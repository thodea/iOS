//
//  FeedViewModel.swift
//  thodea
//
//  Created by Nikolay Pevnev on 8/22/26.
//


import Foundation
import SwiftUI
import FirebaseDatabase
import FirebaseFirestore

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var mostFollowedUsers: [ProfileUserInfo] = []
    @Published var isLoadingProfiles: Bool = false
    
    func fetchMostFollowedUsers() async {
        guard mostFollowedUsers.isEmpty else { return }
        isLoadingProfiles = true
        defer { isLoadingProfiles = false }
        
        let rtdbRef = Database.database().reference()
            .child("user")
            .queryOrdered(byChild: "followers")
            .queryLimited(toFirst: 10)
        
        do {
            let snapshot = try await rtdbRef.getData()
            guard let children = snapshot.children.allObjects as? [DataSnapshot] else { return }
            
            let firestore = Firestore.firestore()
            
            // Concurrently fetch Firestore profile details (Promise.all equivalent)
            let fetchedProfiles = await withTaskGroup(of: ProfileUserInfo?.self) { group in
                for child in children {
                    let username = child.key
                    guard let dict = child.value as? [String: Any] else { continue }
                    
                    group.addTask {
                        let docRef = firestore.collection("user").document(username)
                        let docSnap = try? await docRef.getDocument()
                        let firestoreData = docSnap?.data()
                        
                        let rawFollowers = dict["followers"] as? Int ?? 0
                        let thoughts = dict["thoughts"] as? Int ?? 0
                        let imageURL = firestoreData?["profileMiniUrl"] as? String
                        let isDeleted = firestoreData?["deleted"] as? Bool ?? false
                        
                        return ProfileUserInfo(
                            username: username,
                            imageURL: imageURL,
                            deleted: isDeleted,
                            followers: rawFollowers * -1, // Invert stored negative value
                            thoughts: thoughts,
                            followedAt: nil
                        )
                    }
                }
                
                var results: [ProfileUserInfo] = []
                for await profile in group {
                    if let profile = profile {
                        results.append(profile)
                    }
                }
                return results
            }
            
            // Sort descending by follower count
            self.mostFollowedUsers = fetchedProfiles.sorted { lhs, rhs in
                let lhsFollowers = lhs.followers ?? 0
                let rhsFollowers = rhs.followers ?? 0
                
                if lhsFollowers != rhsFollowers {
                    return lhsFollowers > rhsFollowers
                }
                
                return lhs.username.localizedStandardCompare(rhs.username) == .orderedAscending
            }
        } catch {
            print("Error fetching most followed users: \(error.localizedDescription)")
        }
    }
}
