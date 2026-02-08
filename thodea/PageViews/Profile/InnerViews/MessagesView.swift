//
//  ChatsView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/27/24.
//


import SwiftUI

struct MessagesView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var chatHelper = ChatHelper()
    @State private var showDeleteOptions = false
    @State private var showDeleteConfirmation = false
    
    let username: String
    let miniImageData: Data?
    
    var body: some View {
        VStack(spacing: 16) {
            UserChatView().environmentObject(chatHelper)
        }
        //.border(.green, width: 2)
        //.edgesIgnoringSafeArea(.bottom)
        .padding(0)
        .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 17/255, green: 24/255, blue: 39/255)).foregroundColor(.white.opacity(0.9))
        //.border(.red, width: 2)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 17/255, green: 24/255, blue: 39/255), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .preferredColorScheme(.dark)
        .toolbar {
            // Wrap both the back button and the user info in one HStack
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 8) { // Added spacing here for layout
                    // 1. The Back Button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue.opacity(0.8))
                    }
                    
                    // 2. Profile Image & Info Grouped
                    NavigationLink(destination: ProfileUserView(username: username)) {
                        HStack(spacing: 8) {
                            Group {
                                
                                if let data = miniImageData, let uiImage = UIImage(data: data) {
                                    // Show the selected photo
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill() // Ensures photo fills the square
                                        .frame(width: 34, height: 34)
                                        .clipShape(RoundedRectangle(cornerRadius: 8)) // Clips the overflowing image
                                } else {
                                    // STATE C: No URL exists at all -> Show Default Person Icon
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .padding(8)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            Text(username)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255))
                        }
                    }.buttonStyle(PlainButtonStyle())
                }
            }
            
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // Initial "Delete" option (corresponds to setDeleteConvo(true))
                    NavigationLink(destination: ChatsView()) {                        Label("Chats", systemImage: "envelope")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Chat", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.title2)
                        .padding(.trailing, -13)
                        .contentShape(Rectangle())
                        .padding(.leading, 10)
                        .padding(.vertical, 6)
                        .foregroundColor(Color(uiColor: .systemGray))
                }

                // The "Are you sure?" confirmation dialog (corresponds to deleteConvoConfirm)
                .confirmationDialog("Delete chat?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    Button("Yes", role: .destructive) {
                        // handleSpeakDelete(convoData?.id)
                        print("Deleting...")
                    }
                    Button("No", role: .cancel) {
                        showDeleteConfirmation = false
                    }
                }
            }
        }
    }
}


struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = ProfileUserInfo(
            username: "nikolay_p",
            imageURL: "https://picsum.photos/200", // A valid random image for testing
            deleted: false,
            followers: 128,
            thoughts: 42,
            followedAt: Date()
        )
        
        NavigationStack {
            MessagesView(username: mockUser.username, miniImageData: nil)
                .environmentObject(mockAuthViewModel)
        }
        .preferredColorScheme(.dark)
    }
    
    // Move the logic here
    static var mockAuthViewModel: AuthViewModel {
        let viewModel = AuthViewModel()
        viewModel.currentUser = User(
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
        return viewModel
    }
    
    /*static var previews: some View {
        let mockUser = ProfileUserInfo(
            username: "nikolay_p",
            imageURL: "https://picsum.photos/200", // A valid random image for testing
            deleted: false,
            followers: 128,
            thoughts: 42,
            followedAt: Date()
        )
        
        
        // 2. Pass the mock user into the view
        NavigationStack {
            MessagesView(username: mockUser.username, miniImageData: nil)
                .environmentObject(AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }*/
}
