//
//  FeedView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/22/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct FeedView: View {

    /*init() {

     }*/
    //private let chatService = ChatService()
    
    var body: some View {
        ScrollView { // Wrap the content in a ScrollView
            
            VStack(spacing: 0) {
                
                VStack {
                    Text("")
                }.frame(maxHeight:1)
                //.task { await chatService.createThreeSampleConversations(currentUserId: "test")}
                VStack {
                    Text("follow to customize feed")
                        .font(.headline) // Adjust font size and weight
                        .padding(.leading, 8)
                        .padding(.trailing, 8)
                        .padding(.bottom, 2)
                        .padding(.top, 2)
                        .foregroundColor(Color.white.opacity(0.8))
                        .background(Color(red: 55 / 255, green: 65 / 255, blue: 81 / 255)) // Add a background color
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)
                }.padding(.bottom, 6)
                
                ThoughtView(thought: mockThought)
                //ThoughtView(thought: mockThought)
                
                
                //Text(\(username))
                
                monthlyLovedLabel().padding(.bottom, 6).padding(.top, 6)
                mostFollowedLabel().padding(.bottom, 6).padding(.top, 6)
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Ensure the ScrollView covers the full scree
        //.border(Color.red, width: 2) // To see the frame edges clearly
    }
    
    /*func getName(completion: @escaping (_ username: String?) -> Void) {
        let docRef = Firestore.firestore().collection("user").document("him")

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // Access the document data as a dictionary
                if let data = document.data(), let username = data["username"] as? String {
                    print("Username: \(username)")
                    completion(username) // Pass the username to the completion handler
                } else {
                    print("Username not found in document")
                    completion(nil)
                }
            } else {
                print("Document does not exist or an error occurred: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }*/
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}


struct monthlyLovedLabel: View {
    var body: some View {
        Text("monthly loved")
            .font(.headline) // Adjust font size and weight
            .padding(4)
            .foregroundColor(.clear) // Text becomes transparent to show gradient
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
, Color(red: 192 / 255, green: 132 / 255, blue: 252 / 255)
, Color(red: 59 / 255, green: 130 / 255, blue: 246 / 255)
]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask(Text("monthly loved")) // Apply gradient as a mask to text
            )
            .cornerRadius(8) // Rounded corners
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.5), Color.purple.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.black, radius: 4, x: 0, y: 2) // Shadow effect
    }
}


struct mostFollowedLabel: View {
    var body: some View {
        Text("most followed")
            .font(.headline) // Adjust font size and weight
            .padding(4) // Equivalent to `pl-2 pr-2`
            .foregroundColor(.clear) // Make the text transparent to show gradient
            .background(
                //rgb(59 130 246
                //rgb(96 165 250
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 59 / 255, green: 130 / 255, blue: 246 / 255)
, Color(red: 96 / 255, green: 165 / 255, blue: 250 / 255)
, Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask(Text("most followed")) // Apply gradient as a mask to the text
            )
            .cornerRadius(8) // Rounded corners
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.black, radius: 4, x: 0, y: 2) // Shadow effect
    }
}



// TESTING
/*
class ChatService {
    private let db = Firestore.firestore()

    func createThreeSampleConversations(currentUserId: String) async {
        let batch = db.batch()
        let collectionRef = db.collection("conversation")
        
        // Define your 3 different scenarios/users
        let targets = ["test_user_1", "test_user_2", "test_user_3"]
        
        for target in targets {
            let newChat = Chat(
                chatUsers: [currentUserId, target],
                startedAt: Date(),
                acceptedBy: [currentUserId, target],
                allAccepted: true,
                lastMessage: "Initial message for \(target)",
                lastMessagedAt: Date(),
                lastMessagedBy: currentUserId,
                newMessageFrom: currentUserId,
                startedBy: target
            )
            
            // 1. Create a reference with an auto-generated ID
            let newDocRef = collectionRef.document()
            
            do {
                // 2. Encode the chat object and add to batch
                try batch.setData(from: newChat, forDocument: newDocRef)
            } catch {
                print("Encoding error: \(error)")
                return
            }
        }
        
        // 3. Commit all 3 writes at once
        do {
            try await batch.commit()
            print("Successfully created 3 conversations in one batch.")
        } catch {
            print("Batch commit failed: \(error.localizedDescription)")
        }
    }
}*/
