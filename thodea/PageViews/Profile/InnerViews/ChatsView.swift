//
//  ChatsView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/27/24.
//


import SwiftUI

struct ChatsView: View {
    @Environment(\.presentationMode) var presentationMode
    let mockUser = ProfileUserInfo(
        username: "nikolay_p",
        imageURL: "https://picsum.photos/200", // A valid random image for testing
        deleted: false,
        followers: 128,
        thoughts: 42,
        followedAt: Date()
    )
    
    var body: some View {
            VStack(spacing: 16) {
                // Search TextField
                /*HStack(){
                    Text("chats")
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8).font(.system(size: 19)).foregroundColor(.white.opacity(0.6))*/
                                        
               
                
                NavigationLink(destination: MessagesView(username: mockUser.username, miniImageData: nil)) {
                                ChatView(chat: mockThought)
                            }
                
                ChatView(chat: mockThought)

                Spacer()

            }
            .padding()
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
        ChatsView()
    }
}
