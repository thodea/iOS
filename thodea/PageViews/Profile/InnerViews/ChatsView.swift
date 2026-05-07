//
//  ChatsView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/27/24.
//


import SwiftUI
import FirebaseFirestore

struct ChatsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var chatsViewModel = ChatsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel // Add this
    
    var username: String {
        authViewModel.currentUser?.username ?? ""
    }
    
    // This initializer handles both Production and Preview
    init(previewVM: ChatsViewModel? = nil) {
        _chatsViewModel = StateObject(wrappedValue: previewVM ?? ChatsViewModel())
    }
    
    var body: some View {
            /*VStack(spacing: 16) {
                // Search TextField
                /*HStack(){
                    Text("chats")
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8).font(.system(size: 19)).foregroundColor(.white.opacity(0.6))*/
                                        
               
                
               /* NavigationLink(destination: MessagesView(username: mockUser.username, miniImageData: nil)) {
                                ChatView(chat: mockThought)
                            }
                
                ChatView(chat: mockThought)*/

                Spacer()

            }*/
            ScrollView {
                VStack(spacing: 16) {
                    // 2. Iterate over the fetched chats
                    ForEach(chatsViewModel.chats) { chat in
                        let otherUser = chat.otherUser(currentUsername: username)
                        
                        NavigationLink(destination: MessagesView( username: otherUser, miniImageData: nil, chat: chat)) {
                            ChatView(chat: chat)
                        }
                    }
                    
                    // 3. Optional: Pagination Loader
                    if chatsViewModel.isLoading {
                        ContinuousProgressView()
                    } else if chatsViewModel.canLoadMore {
                        Color.clear
                            .onAppear {
                                chatsViewModel.fetchChats(username: username, isFirstLoad: false)
                            }
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity).background(Color(red: 17/255, green: 24/255, blue: 39/255)).foregroundColor(.white.opacity(0.9))
            .foregroundColor(.white.opacity(0.9))
            .navigationBarBackButtonHidden(true) // Hides the default back button
                .navigationBarItems(leading: Button(action: {
                    self.presentationMode.wrappedValue.dismiss() // Custom back button action
                }) {
                    Image(systemName: "chevron.left") // Custom back button icon
                        .foregroundColor(.blue.opacity(0.8)) // Color of the icon
                })
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if chatsViewModel.chats.isEmpty {
                    chatsViewModel.fetchChats(username: authViewModel.currentUser?.username ?? "")
                }
            }
            .toolbar{
                ToolbarItem(placement: .principal) {
                    Text("Chats")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.9))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ChatRequestsView()) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 29/255, green: 78/255, blue: 216/255))
                            .padding(2)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 29/255, green: 78/255, blue: 216/255), lineWidth: 2)
                            )
                    }
                }
            }
           


    }
}


struct ChatsView_Previews: PreviewProvider {
    static var previews: some View {
        // 1. Setup Mock Auth
        let mockAuth = AuthViewModel()
        mockAuth.currentUser = .mock
        let currentUserId = mockAuth.currentUser?.username ?? "test"

        // 2. Create 3 Mock Chats
        let mockChats = [
            Chat(
                id: "mock_1",
                chatUsers: [currentUserId, "john_doe"],
                startedAt: Date(),
                acceptedBy: [currentUserId, "john_doe"],
                allAccepted: true,
                lastMessage: "Hey! Did you see the new update? This is so long that I need to inform you",
                lastMessagedAt: Date(),
                lastMessagedBy: "john_doe",
                newMessageFrom: currentUserId,
                startedBy: "john_doe"
            ),
            Chat(
                id: "mock_2",
                chatUsers: [currentUserId, "design_team"],
                startedAt: Date().addingTimeInterval(-3600), // 1 hour ago
                acceptedBy: [currentUserId, "design_team"],
                allAccepted: true,
                lastMessage: "",
                lastMessagedAt: Date().addingTimeInterval(-3600),
                lastMessagedBy: "test",
                newMessageFrom: "",
                startedBy: "design_team"
            ),
            Chat(
                id: "mock_3",
                chatUsers: [currentUserId, "app_bot"],
                startedAt: Date().addingTimeInterval(-86400), // 1 day ago
                acceptedBy: [currentUserId, "app_bot"],
                allAccepted: true,
                lastMessage: nil,
                lastMessagedAt: Date().addingTimeInterval(-86400),
                lastMessagedBy: "app_bot",
                newMessageFrom: "",
                startedBy: "app_bot",
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/d/d3/Halleyparknovember_b_%28cropped%29.jpg"
            )
        ]

        // 3. Inject mocks into the View
        // Note: You need to update ChatsView to accept the VM as a parameter
        // OR manually set it if you prefer keeping @StateObject
        return ChatsView(previewVM: ChatsViewModel(initialChats: mockChats))
            .environmentObject(mockAuth)
    }
}

extension User {
    static var mock: User {
        User(
            username: "test",
            registeredAt: Date(),
            darkMode: true,
            followers: 0,
            followings: 0,
            thoughts: 0,
            profileMiniUrl: "https://example.com/mini.jpg",
            profileUrl: "https://example.com/full.jpg",
            bio: "This is a professional mock bio for testing."
        )
    }
}


class ChatsViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var isLoading = false
    @Published var canLoadMore = true
    
    private var lastDocument: DocumentSnapshot?
    private let db = Firestore.firestore()
    private let pageSize = 5
    
    // ADD THIS INITIALIZER
    init(initialChats: [Chat] = []) {
        self.chats = initialChats
        // If we provide mocks, we usually don't want to show the 'loading' spinner immediately
        if !initialChats.isEmpty {
            self.canLoadMore = false
        }
    }

    func fetchChats(username: String, isFirstLoad: Bool = true) {
        // 1. Guard against empty username or redundant loads
        guard !username.isEmpty, !isLoading && (isFirstLoad || canLoadMore) else { return }
        
        isLoading = true
        
        var query = db.collection("conversation")
            .whereField("acceptedBy", arrayContains: username)
            .order(by: "lastMessagedAt", descending: true)
            .order(by: "startedBy")
            .limit(to: pageSize)
        
        if let lastCursor = lastDocument, !isFirstLoad {
            query = query.start(afterDocument: lastCursor)
        }

        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Firestore Error: \(error.localizedDescription)")
                // Check your console! If you see an index error, click the link provided there.
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            guard let documents = snapshot?.documents, !documents.isEmpty else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.canLoadMore = false // No more data to fetch
                }
                return
            }

            self.canLoadMore = documents.count == self.pageSize
            self.lastDocument = documents.last
            
            let group = DispatchGroup()
            var temporaryChats: [Chat] = []
            
            for doc in documents {
                do {
                    var chat = try doc.data(as: Chat.self)
                    let otherUser = chat.otherUser(currentUsername: username)
                    
                    group.enter() // ENTER
                    self.db.collection("user").document(otherUser).getDocument { userDoc, _ in
                        chat.imageURL = userDoc?.data()?["profileMiniUrl"] as? String
                        temporaryChats.append(chat)
                        group.leave() // LEAVE
                    }
                } catch {
                    print("Mapping error for doc \(doc.documentID): \(error)")
                    // Don't enter the group if decoding fails, or it will hang
                }
            }
            
            group.notify(queue: .main) {
                let sorted = temporaryChats.sorted {
                    ($0.lastMessagedAt ?? Date.distantPast) > ($1.lastMessagedAt ?? Date.distantPast)
                }
                
                if isFirstLoad {
                    self.chats = sorted
                } else {
                    self.chats.append(contentsOf: sorted)
                }
                self.isLoading = false // FINALLY SET TO FALSE
            }
        }
    }
}
