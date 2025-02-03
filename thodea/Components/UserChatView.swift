//
//  UserChatView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/25/25.
//

import SwiftUI

struct UserChatView: View {
    @State private var typingMessage: String = ""
    @EnvironmentObject var chatHelper: ChatHelper

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        ForEach(chatHelper.realTimeMessages, id: \.id) { msg in
                            ContentMessageView(contentMessage: msg.content, isCurrentUser: msg.user.isCurrentUser, createdAt: msg.createdAt)
                                .frame(maxWidth: .infinity, alignment: msg.user.isCurrentUser ? .trailing : .leading)
                                .padding(.horizontal)
                        }
                        .onChange(of: chatHelper.realTimeMessages.count) { _ in
                               withAnimation {
                                   if let lastMessage = chatHelper.realTimeMessages.last {
                                       proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                   }
                               }
                           }
                    }
                }
                .onAppear {
                    // Ensures we scroll to the bottom when the view appears initially
                    if let lastMessage = chatHelper.realTimeMessages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
                .onChange(of: chatHelper.realTimeMessages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(chatHelper.realTimeMessages.last?.id, anchor: .bottom)
                    }
                }
            }//.border(.red, width: 2)

            HStack(alignment: .bottom, spacing: 0) {
                
                    TextField("Message", text: $typingMessage, prompt: Text("Message").foregroundColor(Color.white.opacity(0.7)).font(.system(size: 22)), axis: .vertical)
                        .textFieldStyle(DefaultTextFieldStyle())
                        .frame(minHeight: 40) // Set height for the text field
                        .lineLimit(6)
                        .foregroundColor(.white)
                    //.background(Color.green)
                    //.border(.green, width: 2)
                        .font(.system(size: 22))
                        .padding(.leading, 4)
                        .overlay(
                            Rectangle()
                                .frame(height: 2) // Border thickness
                                .foregroundColor(Color(red: 30/255, green: 58/255, blue: 138/255)), // RGB color
                            alignment: .bottom
                        )


                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28) // Icon size
                        .foregroundColor(.white)
                        .padding(10) // Padding inside button
                        .background(Color.clear)
                        .clipShape(Circle())
                }
                .frame(height: 40) // Match TextField height
                .disabled(typingMessage.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            //.border(.red, width: 1)
            .frame(minHeight: CGFloat(50))
            .padding(.horizontal, 16)
        }
        .background(Color(red: 17/255, green: 24/255, blue: 39/255))
        //.edgesIgnoringSafeArea(.bottom)
        //.frame(maxWidth: .infinity, maxHeight: .infinity)
        //.border(.red, width: 2)
        .padding(0)
        //.background(Color.black.opacity(0.5))
    }

    private func sendMessage() {
        chatHelper.sendMessage(typingMessage)
        typingMessage = ""
    }
}

struct UserChatView_Previews: PreviewProvider {
    static var previews: some View {
        UserChatView()
            .environmentObject(ChatHelper()) // Provide an instance of ChatHelper
    }
}

