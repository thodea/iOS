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
    
    func sendMessage(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let currentUser = User(username: "Me", image: UIImage(), isCurrentUser: true)
        let newMessage = Message(content: content, user: currentUser)
        
        realTimeMessages.append(newMessage)
    }
}
