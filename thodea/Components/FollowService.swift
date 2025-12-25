//
//  FollowService.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/7/25.
//

import Foundation
import FirebaseFirestore
import FirebaseDatabase
import FirebaseStorage

final class FollowService {

    private let fdb = Firestore.firestore()
    private let rdb = Database.database().reference()
    private let storage = Storage.storage()

    /// Swift equivalent of the Next.js getFollow() function
    func getFollow(user: String,
                   type: String,
                   maxLim: Int,
                   snap: DocumentSnapshot? = nil) async throws -> ([ProfileUserInfo], DocumentSnapshot?) {
        
        // 1. Base query
        var query: Query = fdb
            .collection("user")
            .document(user)
            .collection(type)
            .order(by: "followedAt", descending: true)
            .limit(to: maxLim)

        // 2. If snap exists → startAfter
        if let doc = snap {
            query = query.start(afterDocument: doc)
        }

        // 3. Execute Firestore query
        let snapshot = try await query.getDocuments()
        
        // If empty, return empty early
        if snapshot.documents.isEmpty {
            return ([], nil)
        }

        var arr = try snapshot.documents.compactMap { doc -> ProfileUserInfo? in
            return try doc.data(as: ProfileUserInfo.self)
        }

        // 4. Hydrate with user profile info + realtime DB values
        for i in 0..<arr.count {
            let username = arr[i].username

            // --- Firestore user doc ---
            let userDoc = try await fdb.collection("user").document(username).getDocument()
            if let miniURL = userDoc.data()?["profileMiniUrl"] as? String {
                arr[i].imageURL = miniURL
            }
            arr[i].deleted = userDoc.data()?["deleted"] as? Bool

            // --- Realtime DB followers ---
            let followersRef = rdb.child("user/\(username)/followers")
            let followersSnap = try await followersRef.getData()
            if let val = followersSnap.value as? Int {
                arr[i].followers = val * -1
            }

            // --- Realtime DB thoughts ---
            let thoughtsRef = rdb.child("user/\(username)/thoughts")
            let thoughtsSnap = try await thoughtsRef.getData()
            arr[i].thoughts = thoughtsSnap.value as? Int ?? 0
        }

        return (arr, snapshot.documents.last)
    }
}
