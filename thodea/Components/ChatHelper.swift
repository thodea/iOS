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
             User(username: "Alice", image: UIImage(), isCurrentUser: false),
             User(username: "Bob", image: UIImage(), isCurrentUser: true)
         ]

         realTimeMessages = (1...15).map { i in
             Message(
                 content: "Mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock message mock e\(i)",
                 user: mockUsers[i % 2],
                 createdAt: Date(timeIntervalSince1970: 1734296943 + Double(i * 60)) // Each message 1 minute apart
             )
         }
     }

    
    func sendMessage(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let currentUser = User(username: "Me", image: UIImage(), isCurrentUser: true)
        let newMessage = Message(content: content, user: currentUser, createdAt: Date())
        
        realTimeMessages.append(newMessage)
    }
}
