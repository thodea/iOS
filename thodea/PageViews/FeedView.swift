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
    @StateObject private var vm = FeedViewModel()

    /*init() {

     }*/
    //private let chatService = ChatService()
    //private let testService = TestService()
    
    var body: some View {
        
        ScrollView { // Wrap the content in a ScrollView
            
            VStack(spacing: 0) {
                
                VStack {
                    Text("")
                }.frame(maxHeight:1)
                //.task { await testService.deleteSampleFollowingData()}
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
                
                // 🔹 MOST FOLLOWED SECTION
                if !vm.mostFollowedUsers.isEmpty {
                    mostFollowedLabel().padding(.bottom, 6).padding(.top, 6)
                    LazyVStack(spacing: 8) {
                        ForEach(vm.mostFollowedUsers, id: \.username) { userInfo in
                            let isDeleted = userInfo.deleted ?? false
                            
                            NavigationLink(destination: ProfileUserView(username: userInfo.username)) {
                                UserRowView(userInfo: userInfo, dateDisabled: true)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isDeleted)
                            .opacity(isDeleted ? 0.6 : 1.0)
                            .padding(.bottom, 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .padding(.bottom, 24)
                }

            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await vm.fetchMostFollowedUsers()
        }
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

class ChatService {
    private let db = Firestore.firestore()

    func createThreeSampleConversations(currentUserId: String) async {
        let batch = db.batch()
        let collectionRef = db.collection("conversation")
        
        // Define your 3 different scenarios/users
        let targets = ["test"]
        
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
}



/*class ChatService {
    private let db = Firestore.firestore()
    
    /// Creates 150 sample conversations (test_user_4 to test_user_153) for pagination testing
    func create150SampleConversations(currentUserId: String) async {
        let collectionRef = db.collection("conversation")
        var batch = db.batch()
        var operationCount = 0
        
        for i in 4...153 {
            let target = "test_user_\(i)"
            // Stagger timestamps incrementally so they sort cleanly in descending order
            let timeOffset = Double(i * 60) // 1 minute apart per conversation
            let messageDate = Date().addingTimeInterval(-timeOffset)
            
            let newChat = Chat(
                chatUsers: [currentUserId, target],
                startedAt: messageDate,
                acceptedBy: [currentUserId, target],
                allAccepted: true,
                lastMessage: "Pagination test message #\(i)",
                lastMessagedAt: messageDate,
                lastMessagedBy: currentUserId,
                newMessageFrom: currentUserId,
                startedBy: target
            )
            
            let newDocRef = collectionRef.document()
            do {
                try batch.setData(from: newChat, forDocument: newDocRef)
                operationCount += 1
                
                // Firestore safety check: commit batches if nearing the 500 limit
                if operationCount >= 450 {
                    try await batch.commit()
                    batch = db.batch()
                    operationCount = 0
                }
            } catch {
                print("Encoding error for target \(target): \(error)")
            }
        }
        
        if operationCount > 0 {
            do {
                try await batch.commit()
                print("Successfully created 150 test conversations.")
            } catch {
                print("Batch commit failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Removes all test conversations except test_user_1, test_user_2, and test_user_3
    func removeTestConversations(currentUserId: String) async {
        let collectionRef = db.collection("conversation")
        let protectedTargets: Set<String> = ["test_user_1", "test_user_2", "test_user_3", "nik"]
        
        do {
            let snapshot = try await collectionRef
                .whereField("acceptedBy", arrayContains: currentUserId)
                .getDocuments()
            
            var batch = db.batch()
            var deleteCount = 0
            
            for document in snapshot.documents {
                do {
                    let chat = try document.data(as: Chat.self)
                    let otherUser = chat.otherUser(currentUsername: currentUserId)
                    
                    // Exclude protected users from deletion
                    if !protectedTargets.contains(otherUser) {
                        batch.deleteDocument(document.reference)
                        deleteCount += 1
                        
                        // Respect Firestore's 500-operation batch limit
                        if deleteCount >= 450 {
                            try await batch.commit()
                            batch = db.batch()
                            deleteCount = 0
                        }
                    }
                } catch {
                    print("Error decoding document \(document.documentID): \(error)")
                }
            }
            
            if deleteCount > 0 {
                try await batch.commit()
                print("Successfully cleaned up test conversations (kept test_user_1, 2, and 3).")
            } else {
                print("No generated test conversations found to delete.")
            }
        } catch {
            print("Failed to fetch or delete conversations: \(error.localizedDescription)")
        }
    }
}
*/
class TestService {
    
    func seedSampleFollowingData() async {
        let db = Firestore.firestore()
        let batch = db.batch()
        let followingRef = db.collection("user").document("test").collection("following")
        
        // Base date: February 23, 2026 at 9:40:34 PM UTC-5
        var dateComponents = DateComponents()
        dateComponents.year = 2026
        dateComponents.month = 2
        dateComponents.day = 23
        dateComponents.hour = 21
        dateComponents.minute = 40
        dateComponents.second = 34
        dateComponents.timeZone = TimeZone(secondsFromGMT: -5 * 3600)
        
        let baseDate = Calendar.current.date(from: dateComponents) ?? Date()
        
        for i in 1...100 {
            let docID = "\(i)"
            let docRef = followingRef.document(docID)
            
            // Offset each follow date by a few minutes to create realistic pagination ordering
            let itemDate = baseDate.addingTimeInterval(TimeInterval(-i * 60))
            
            let data: [String: Any] = [
                "username": docID,
                "followedAt": Timestamp(date: itemDate)
            ]
            
            batch.setData(data, forDocument: docRef)
        }
        
        do {
            try await batch.commit()
            print("✅ Successfully seeded 100 sample following documents!")
        } catch {
            print("❌ Error seeding Firestore documents: \(error.localizedDescription)")
        }
    }
    
    
    func deleteSampleFollowingData(range: ClosedRange<Int> = 1...100) async {
        let db = Firestore.firestore()
        let batch = db.batch()
        let followingRef = db.collection("user").document("test").collection("following")
        
        for i in range {
            let docRef = followingRef.document("\(i)")
            batch.deleteDocument(docRef)
        }

        do {
            try await batch.commit()
            print("✅ Successfully deleted test documents \(range.lowerBound) through \(range.upperBound)!")
        } catch {
            print("❌ Error deleting Firestore documents: \(error.localizedDescription)")
        }
    }
}
