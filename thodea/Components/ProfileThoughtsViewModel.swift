//
//  ProfileThoughtsViewModel.swift
//  thodea
//
//  Created by Nikolay Pevnev on 9/12/26.
//


import Foundation
import FirebaseFirestore
import FirebaseDatabase

@MainActor
class ProfileThoughtsViewModel: ObservableObject {
    @Published var thoughts: [Thought] = []
    @Published var isLoading: Bool = false
    
    // Pagination tracking (optional but recommended for feeds)
    private var lastDocument: DocumentSnapshot?
    private let maxLimit: Int = 3
    private let absoluteMaxLimit: Int = 10 // 🟢 ADD THIS
    
    /// Completed Firebase function calling translated from Next.js
    func fetchThoughts(for createdBy: String, currentUserName: String) async {
        guard !isLoading else { return }
        
        // 🟢 ADD THIS: Stop immediately if we've already reached 10 thoughts
        guard thoughts.count < absoluteMaxLimit else { return }
        
        isLoading = true
        
        // 🟢 ADD THIS: Calculate the limit dynamically.
        let fetchLimit = min(maxLimit, absoluteMaxLimit - thoughts.count)
        
        let db = Firestore.firestore()
        let rtdb = Database.database().reference()
        
        do {
            // 1. Initial Firestore Query (Equivalent to collectionGroup("thoughts").where...)
            var query: Query = db.collectionGroup("thoughts")
                .whereField("createdBy", isEqualTo: createdBy)
                .order(by: "createdAt", descending: true)
                .limit(to: fetchLimit) //maxLimit
            
            if let last = lastDocument {
                query = query.start(afterDocument: last)
            }
            
            let querySnapshot = try await query.getDocuments()
            self.lastDocument = querySnapshot.documents.last
            
            // 2. Parallel Fetching using TaskGroup (Equivalent to Promise.all)
            let fetchedThoughts = try await withThrowingTaskGroup(of: Thought?.self) { group in
                for document in querySnapshot.documents {
                    group.addTask {
                        let data = document.data()
                        let postId = data["postId"] as? Int ?? 0
                        
                        // 3. Concurrent sub-fetching (Equivalent to individual async calls in your map)
                        // Using `async let` fires these off at the same time!
                        async let userDoc = db.collection("user").document(createdBy).getDocument()
                        async let lovedDoc = db.document("user/\(createdBy)/thoughts/\(postId)/loves/\(currentUserName)").getDocument()
                        
                        async let lovesSnap = rtdb.child("thoughts/\(postId)/loves").getData()
                        async let commentsSnap = rtdb.child("thoughts/\(postId)/comments").getData()
                        async let clicksSnap = rtdb.child("thoughts/\(postId)/clicked").getData()
                        async let seenSnap = rtdb.child("thoughts/\(postId)/seen").getData()
                        
                        // Await all concurrent tasks
                        let profileSnap = try? await userDoc
                        let lovedSnap = try? await lovedDoc
                        let lovesCount = (try? await lovesSnap)?.value as? Int ?? 0
                        let commentsCount = (try? await commentsSnap)?.value as? Int ?? 0
                        let clicksCount = (try? await clicksSnap)?.value as? Int ?? 0
                        let seenRaw = (try? await seenSnap)?.value as? Int ?? 0
                        
                        // 4. Construct the Thought model
                        return Thought(
                            createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                            createdBy: createdBy,
                            message: data["message"] as? String ?? "",
                            postId: postId,
                            loved: lovedSnap?.exists ?? false,
                            loveCount: lovesCount,
                            lovedAt: (lovedSnap?.data()?["lovedAt"] as? Timestamp)?.dateValue(),
                            commentCount: commentsCount,
                            seenCount: seenRaw == 0 ? 1 : seenRaw,
                            clickCount: clicksCount,
                            mentions: data["mentions"] as? [String] ?? [],
                            imageURL: profileSnap?.data()?["profileMiniUrl"] as? String,
                            assetUrl: data["assetUrl"] as? String ?? "",
                            assetType: data["assetType"] as? String ?? "",
                            posterUrl: data["posterUrl"] as? String ?? "",
                            newAssetUrl: data["newAssetUrl"] as? String ?? "",
                            newPosterUrl: data["newPosterUrl"] as? String ?? "",
                            urlDescription: data["urlDescription"] as? String ?? "",
                            urlTitle: data["urlTitle"] as? String ?? "",
                            firstUrl: data["firstUrl"] as? String,
                            profileDeleted: profileSnap?.data()?["deleted"] as? Bool
                        )
                    }
                }
                
                // Collect results
                var results: [Thought] = []
                for try await thought in group {
                    if let thought = thought { results.append(thought) }
                }
                
                // Swift TaskGroups complete in random order, so we sort them back to chronological
                return results.sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
            }
            
            // Append to our published array to trigger UI update
            self.thoughts.append(contentsOf: fetchedThoughts)
            
        } catch {
            print("Error fetching thoughts: \(error)")
        }
        
        self.isLoading = false
    }
}
