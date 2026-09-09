//
//  ChatsView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/27/24.
//


import SwiftUI

struct ChatRequestsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // 1. Initialize ViewModel in Requests mode (Zero logic duplication!)
    @StateObject private var requestsViewModel = ChatsViewModel(mode: .requests)
    
    var username: String {
        authViewModel.currentUser?.username ?? ""
    }
    
    var body: some View {
        ZStack {
            // Main App Background
            Color(red: 17/255, green: 24/255, blue: 39/255)
                .ignoresSafeArea()
            
            if requestsViewModel.chats.isEmpty {
                if requestsViewModel.isLoading {
                    // Loader State
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            .opacity(0.2)
                            .scaleEffect(1.5)
                            .padding(.top, 24)
                        Spacer()
                    }
                } else {
                    // Empty State
                    VStack {
                        HStack(spacing: 6) {
                            Text("No chat requests")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 24)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        Spacer()
                    }
                }
            } else {
                // Chats Request List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(requestsViewModel.chats.enumerated()), id: \.element.id) { index, chat in
                            let otherUser = chat.otherUser(currentUsername: username)
                            
                            NavigationLink(
                                destination: MessagesView(
                                    username: otherUser,
                                    miniImageData: nil,
                                    chat: chat,
                                    // 2. This closure ensures that the request UI updates upon popping back
                                    onMessageUpdated: { text, date, sender in
                                        requestsViewModel.updateChatState(chatId: chat.id ?? "", text: text, date: date, sender: sender, currentUsername: username)
                                    },
                                    onDelete: {
                                        if let chatId = chat.id {
                                            requestsViewModel.deleteChat(chatId: chatId)
                                        }
                                    }
                                )
                                .onAppear {
                                    requestsViewModel.markAsReadIfNeeded(chat: chat, currentUsername: username)
                                }
                            ) {
                                ChatView(chat: chat)
                            }
                            .onAppear {
                                // 3. Pagination logic matching ChatsView perfectly
                                if index >= requestsViewModel.chats.count - 2,
                                   requestsViewModel.canLoadMore,
                                   !requestsViewModel.isLoading {
                                    requestsViewModel.fetchChats(username: username, isFirstLoad: false)
                                }
                            }
                        }
                        
                        if requestsViewModel.isLoading && !requestsViewModel.chats.isEmpty {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                .padding(.vertical, 8)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.blue.opacity(0.8))
        })
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Initial Data Fetch
            if requestsViewModel.chats.isEmpty {
                requestsViewModel.fetchChats(username: username)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Chat requests")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}

struct ChatRequestsView_Previews: PreviewProvider {
    static var previews: some View {
        ChatRequestsView()
            .environmentObject(AuthViewModel())
    }
}
