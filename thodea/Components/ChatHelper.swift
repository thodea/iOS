//
//  ChatHelper.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/25/25.
//


import SwiftUI
import Combine

class ChatHelper: ObservableObject {
    @Published var realTimeMessages: [Message] = []
    
    init() {
         let mockUsers = [
            User(
                username: "Me",
                followers: 120,
                followings: 85,
                thoughts: 42,
                chatRequest: false,
                newChat: true,
                bio: "Lover of coffee and code ☕️",
                registeredAt: Date(), // current date
                darkMode: true,
                following: ["bob", "charlie", "diana"],
                profileUrl: "https://example.com/images/alice.jpg",
                profileMiniUrl: "https://example.com/images/alice-mini.jpg",
                deleted: false
            ),
            User(
                username: "delete",
                followers: 200,
                followings: 150,
                thoughts: 30,
                chatRequest: false,
                newChat: true,
                bio: "Just a regular Bob.",
                registeredAt: Date(),
                darkMode: true,
                following: ["Alice", "Charlie"],
                profileUrl: "https://example.com/images/bob.jpg",
                profileMiniUrl: "https://example.com/images/bob-mini.jpg",
                deleted: false
            ),
            User(
                username: "Me",
                followers: 200,
                followings: 150,
                thoughts: 30,
                chatRequest: false,
                newChat: true,
                bio: "Just a regular Bob.",
                registeredAt: Date(),
                darkMode: true,
                following: ["Alice", "Charlie"],
                profileUrl: "https://example.com/images/bob.jpg",
                profileMiniUrl: "https://example.com/images/bob-mini.jpg",
                deleted: false
            )
         ]

         /*realTimeMessages = (1...3).map { i in
             Message(
                 content: "Mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock e\(i)",
                 user: mockUsers[i], //mockUsers[i % 2],
                 createdAt: Date(timeIntervalSince1970: 1734296943 + Double(i * 60)) // Each message 1 minute apart
             )
         }*/
        realTimeMessages = (1...10).map { i in
            Message(
                content: "Mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock e\(i)",
                user: mockUsers[i % mockUsers.count], // Safely wraps around
                createdAt: Date().addingTimeInterval(Double(-600 + (i * 60)))
            )
        }
        
     }

    
    func sendMessage(_ content: String, user: User, image: UIImage? = nil, videoURL: URL? = nil) {
        // Guard: ensure we have at least text OR media
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty || image != nil || videoURL != nil else { return }
        
        /*
         
         let currentUser = User(
             username: "Me",
             followers: 0,
             followings: 0,
             thoughts: 0,
             chatRequest: false,
             newChat: false,
             bio: nil,
             registeredAt: Date(),
             darkMode: true,
             following: [],
             profileUrl: nil,
             profileMiniUrl: nil,
             deleted: false
         )
         */
        
        // Init message with the new optionals
        let newMessage = Message(
            content: content,
            user: user,
            createdAt: Date(),
            attachedImage: image,     // <--- Pass Image
            attachedVideoURL: videoURL // <--- Pass Video
        )
        
        realTimeMessages.append(newMessage)
    }
    
    func deleteMessage(id: UUID) {
        realTimeMessages.removeAll { $0.id == id }
    }
}
