//
//  ThoughtActionService.swift
//  thodea
//
//  Created by Nikolay Pevnev on 10/4/26.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase

class ThoughtActionService {
    static let shared = ThoughtActionService()
    
    private let rtdb = Database.database().reference()
    private let fdb = Firestore.firestore()
    private let type = "post"
    // Replace with your actual base URL
    private let apiBase = "https://www.thodea.com" 
    
    /// Translates the Next.js `love(...)` API to Swift
    func toggleLove(
        postId: Int,
        createdBy: String,
        postedAt: Date?,
        isCurrentlyLoved: Bool,
        currentUsername: String,
        currentUserEmail: String
    ) async {
        let change = isCurrentlyLoved ? -1 : 1
        let pIdStr = String(postId)
        
        do {
            // 1. Update RTDB (Atomic Increment)
            let rtdbPath = "thoughts/\(pIdStr)/loves"
            try await rtdb.child(rtdbPath).setValue(ServerValue.increment(NSNumber(value: change)))
            
            // 2. Update MongoDB via API (if post is not older than 30 days)
            if let date = postedAt, !isOlderThan30Days(date) {
                // Get fresh Firebase token
                if let token = try await Auth.auth().currentUser?.getIDToken() {
                    await updateMongoDBLove(postId: postId, increment: change, email: currentUserEmail, token: token)
                }
            }
            
            // 3. Update Firestore
            let firestorePath = fdb.collection("user").document(createdBy)
                .collection("thoughts").document(pIdStr)
                .collection("loves").document(currentUsername)
            
            if !isCurrentlyLoved { // We are Liking it
                let data: [String: Any] = [
                    "postId": postId,
                    "lovedBy": currentUsername,
                    "lovedAt": FieldValue.serverTimestamp(),
                    "type": type
                ]
                try await firestorePath.setData(data)
            } else { // We are Unliking it
                try await firestorePath.delete()
            }
            
        } catch {
            print("❌ Error updating love state: \(error.localizedDescription)")
        }
    }
    
    // Helper to match NextJS 30-day logic
    private func isOlderThan30Days(_ date: Date) -> Bool {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return date < thirtyDaysAgo
    }
    
    // Helper for MongoDB patch request
    private func updateMongoDBLove(postId: Int, increment: Int, email: String, token: String) async {
        guard let url = URL(string: "\(apiBase)/api/mdb/love") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "postId": postId,
            "increment": increment,
            "email": email
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, !((200...299).contains(httpResponse.statusCode)) {
                print("❌ Failed to update MongoDB love. Status: \(httpResponse.statusCode)")
            }
        } catch {
            print("❌ MongoDB Request Error: \(error)")
        }
    }
}
