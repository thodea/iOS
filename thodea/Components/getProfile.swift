//
//  getProfile.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/4/26.
//
import FirebaseDatabase
import FirebaseFirestore

// Add this function inside your View or a separate Service file
func fetchProfile(targetUsername: String, currentUsername: String?) async throws -> ProfileInfo {
    // 1. Setup References (Assuming you have Firebase configured)
    let db = Database.database().reference()
    let fdb = Firestore.firestore()
    
    // 2. Fetch Basic Info from Realtime DB (db/user/username)
    let userRef = db.child("user").child(targetUsername)
    let userSnap = try await userRef.getData()
    
    // Map snapshot to basic info (Modify keys to match your actual DB structure)
    // Note: In Next.js you did (await get(userRef)).val()
    guard let value = userSnap.value as? [String: Any] else { throw URLError(.badServerResponse) }
    
    // Handle the negative followers/following logic you showed in Next.js
    var followersCount = (value["followers"] as? Int ?? 0)
    var followingCount = (value["following"] as? Int ?? 0)
    
    // Next.js logic: profile.followers = profile.followers * -1;
    // Assuming your DB stores them as negative for sorting:
    if followersCount < 0 { followersCount = followersCount * -1 }
    if followingCount < 0 { followingCount = followingCount * -1 }
    
    // 3. Fetch Bio/URLs from Firestore (user/username)
    let docUsrDisplayRef = fdb.collection("user").document(targetUsername)
    let docUsrDisplaySnap = try await docUsrDisplayRef.getDocument()
    let data = docUsrDisplaySnap.data()
    
    // 4. Check "Following" Status
    var isFollowing = false
    if let currentUsername = currentUsername {
        // doc(fdb, `user/${userSignOn}/following/${user}`)
        let followingRef = fdb.collection("user").document(currentUsername).collection("following").document(targetUsername)
        let followingSnap = try await followingRef.getDocument()
        isFollowing = followingSnap.exists
    }
    
    return ProfileInfo(
        username: targetUsername,
        bio: data?["bio"] as? String,
        profileUrl: data?["profileUrl"] as? String,
        profileMiniUrl: data?["profileMiniUrl"] as? String,
        followers: followersCount,
        following: followingCount,
        thoughts: value["thoughts"] as? Int ?? 0,
        isFollowing: isFollowing
    )
}
