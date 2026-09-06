//
//  ChatsView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/27/24.
//


import SwiftUI
import FirebaseFirestore
import Kingfisher

struct ChatsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var chatsViewModel = ChatsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel // Add this
        
    var onNavigateToSearch: (() -> Void)? = nil
    
    var username: String {
        authViewModel.currentUser?.username ?? ""
    }
    
    // Initializer supports both Production, Preview, and optional action callback
    init(previewVM: ChatsViewModel? = nil, onNavigateToSearch: (() -> Void)? = nil) {
        _chatsViewModel = StateObject(wrappedValue: previewVM ?? ChatsViewModel())
        self.onNavigateToSearch = onNavigateToSearch
    }
    
    var body: some View {
        ZStack {
                // Main App Background
                Color(red: 17/255, green: 24/255, blue: 39/255)
                    .ignoresSafeArea()
                
                // Conditional State Handling
                if chatsViewModel.chats.isEmpty {
                    if chatsViewModel.isLoading {
                        // 1. SHOW INITIAL LOADER
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                .opacity(0.2)
                                .scaleEffect(1.5)
                                .padding(.top, 24)
                            
                            Spacer()
                        }
                    } else {
                        // 2. FALLBACK DISPLAY (0 Chats & Not Loading)
                        VStack {
                            HStack(spacing: 6) {
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                    NotificationCenter.default.post(name: Notification.Name("SwitchToSearchTab"), object: nil)
                                    onNavigateToSearch?()
                                }) {
                                    Text("Search users")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(red: 29/255, green: 78/255, blue: 216/255))
                                        .underline()
                                }
                                
                                Text("to start new chat")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                            
                            Spacer()
                        }
                    }
                } else {
                    // 3. SHOW CHATS LIST
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(chatsViewModel.chats.enumerated()), id: \.element.id) { index, chat in
                                let otherUser = chat.otherUser(currentUsername: username)
                                
                                NavigationLink(
                                    destination: MessagesView(
                                        username: otherUser,
                                        miniImageData: nil,
                                        chat: chat,
                                        onMessageUpdated: { text, date, sender in
                                            chatsViewModel.updateChatState(chatId: chat.id ?? "", text: text, date: date, sender: sender)
                                        },
                                        onDelete: {
                                            if let chatId = chat.id {
                                                chatsViewModel.deleteChat(chatId: chatId)
                                            }
                                        }
                                    )
                                    .onAppear {
                                        chatsViewModel.markAsReadIfNeeded(chat: chat, currentUsername: username)
                                    }
                                ) {
                                    ChatView(chat: chat)
                                }
                                .onAppear {
                                    if index >= chatsViewModel.chats.count - 2,
                                       chatsViewModel.canLoadMore,
                                       !chatsViewModel.isLoading {
                                        chatsViewModel.fetchChats(username: username, isFirstLoad: false)
                                    }
                                }
                            }
                            
                            if chatsViewModel.isLoading && !chatsViewModel.chats.isEmpty {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding()
                    }
                }
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
                            .overlay(alignment: .topTrailing) {
                                if authViewModel.currentUser?.chatRequest == true { // 👈 Pointer 1: Update this condition
                                    Circle()
                                        .fill(Color(red: 161 / 255, green: 98 / 255, blue: 7 / 255))
                                        .frame(width: 10, height: 10)
                                        .shadow(color: .black.opacity(0.4), radius: 1.5, x: 0, y: 1) 
                                        .offset(x: 4, y: -5) // 👈 Pointer 2: Tweak for corner radius
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                       if authViewModel.currentUser?.chatRequest == true {
                           authViewModel.clearChatRequestNotification()
                       }
                   })
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
    private let initialPageSize = 15
    private let pageSize = 5
    private let maxChatsLimit = 100 // Hard cap requirement
    
    init(initialChats: [Chat] = []) {
        self.chats = initialChats
        if !initialChats.isEmpty {
            self.canLoadMore = false
        }
    }

    func markAsReadIfNeeded(chat: Chat, currentUsername: String) {
        guard let newMessageFrom = chat.newMessageFrom,
              !newMessageFrom.isEmpty,
              newMessageFrom != currentUsername,
              let chatId = chat.id,
              !chatId.isEmpty else { return }

        // 1. Optimistic Local Update
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].newMessageFrom = nil
        }

        // 2. Firestore Remote Update
        let convoRef = Firestore.firestore().collection("conversation").document(chatId)
        convoRef.updateData([
            "newMessageFrom": FieldValue.delete()
        ]) { error in
            if let error = error {
                print("Error clearing newMessageFrom: \(error.localizedDescription)")
            }
        }
    }

    func fetchChats(username: String, isFirstLoad: Bool = true) {
        guard !username.isEmpty, !isLoading && (isFirstLoad || canLoadMore) else { return }
        guard chats.count < maxChatsLimit else {
            DispatchQueue.main.async { self.canLoadMore = false }
            return
        }
         
        isLoading = true
         
        // Dynamically choose limit based on whether it's the initial load or a scroll pagination
        let fetchLimit = isFirstLoad ? initialPageSize : pageSize
        
        var query = db.collection("conversation")
            .whereField("acceptedBy", arrayContains: username)
            .order(by: "lastMessagedAt", descending: true)
            .order(by: "startedBy")
            .limit(to: fetchLimit)
         
        if let lastCursor = lastDocument, !isFirstLoad {
            query = query.start(afterDocument: lastCursor)
        }

        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
             
            if let error = error {
                print("Firestore Error: \(error.localizedDescription)")
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            guard let documents = snapshot?.documents, !documents.isEmpty else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.canLoadMore = false
                }
                return
            }

            // Check against the specific limit used for this request type
            self.canLoadMore = documents.count == fetchLimit
            self.lastDocument = documents.last
             
            let group = DispatchGroup()
            var temporaryChats: [Chat] = []
             
            for doc in documents {
                do {
                    var chat = try doc.data(as: Chat.self)
                    let otherUser = chat.otherUser(currentUsername: username)
                     
                    group.enter()
                    self.db.collection("user").document(otherUser).getDocument { userDoc, _ in
                        chat.imageURL = userDoc?.data()?["profileMiniUrl"] as? String
                        temporaryChats.append(chat)
                        group.leave()
                    }
                } catch {
                    print("Mapping error for doc \(doc.documentID): \(error)")
                }
            }
             
            group.notify(queue: .main) {
                let sorted = temporaryChats.sorted {
                    ($0.lastMessagedAt ?? Date.distantPast) > ($1.lastMessagedAt ?? Date.distantPast)
                }
                 
                if isFirstLoad {
                    self.chats = sorted
                } else {
                    let remainingCapacity = self.maxChatsLimit - self.chats.count
                    let chatsToAdd = sorted.prefix(remainingCapacity)
                    self.chats.append(contentsOf: chatsToAdd)
                     
                    if self.chats.count >= self.maxChatsLimit {
                        self.canLoadMore = false
                    }
                }
                 
                self.preloadChatImages(for: sorted)
                self.isLoading = false
            }
        }
    }

    private func preloadChatImages(for chats: [Chat]) {
        let urls = chats.compactMap { chat -> URL? in
            guard let urlString = chat.imageURL else { return nil }
            return URL(string: urlString)
        }
        
        let prefetcher = ImagePrefetcher(urls: urls)
        prefetcher.start()
    }
    
    func deleteChat(chatId: String) {
        // 1. Local Optimistic Cleanup (instant UI removal)
        chats.removeAll { $0.id == chatId }

        // 2. Remote Firestore Deletion
        db.collection("conversation").document(chatId).delete { error in
            if let error = error {
                print("Error deleting chat document: \(error.localizedDescription)")
            }
        }
    }
    
    func updateChatState(chatId: String, text: String, date: Date, sender: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        
        chats[index].lastMessage = text
        chats[index].lastMessagedAt = date
        chats[index].lastMessagedBy = sender
        chats[index].newMessageFrom = nil
        
        chats.sort { ($0.lastMessagedAt ?? .distantPast) > ($1.lastMessagedAt ?? .distantPast) }
    }
}
