//
//  Interfaces.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/7/25.
//

import Foundation
import AVKit

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
    var image: UIImage
    var isCurrentUser: Bool = false
}

struct Message {
    var id = UUID() // This will generate a unique identifier for each message
    var content: String
    var user: User
}


let mockThought = Thought(
    createdAt: Date(timeIntervalSince1970: 1734296943), // Converted from "December 14, 2024 at 11:49:03 AM UTC-5"
    createdBy: "tatyanapev",
    message: "It doesn’t help thodea.com that a billionaire google.com buys a social network. Now billionaires are managing all social networks, each one their own. Regular population will find it hard to relate themselves with the owners of social network, even Facebook is more of Ivy League story than a normal human can imagine how to pass through admissions. Do people use social networks to connect with their friends or it’s just another news channel for a few to be heard? It’s hard to imagine that a regular person is thinking same thing as these billionaires who have enormous power over population.",
    postId: -6,
    loved: true,
    loveCount: 1,
    lovedAt: nil, // No lovedAt provided
    commentCount: 0,
    seenCount: 3,
    clickCount: 0,
    mentions: [], // Empty array
    imageURL: "https://storage.googleapis.com/thodea_assets/user/tatyanapev/asset_1732782978345_min.webp",
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
