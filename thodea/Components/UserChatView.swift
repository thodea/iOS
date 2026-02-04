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
            messageScrollView

            messageInputBar
                .frame(minHeight: 50)
                .padding(.horizontal, 16)
        }
        .background(Color(red: 17/255, green: 24/255, blue: 39/255))
        .padding(0)
    }

    private var messageScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    messageList
                }
                .onChange(of: chatHelper.realTimeMessages.count) { _ in
                    scrollToBottom(proxy, animate: true)
                }
            }
            .onAppear {
                scrollToBottom(proxy, animate: false)
            }
        }
    }

    private var messageList: some View {
        ForEach(chatHelper.realTimeMessages, id: \.id) { msg in
            ContentMessageView(contentMessage: msg.content, isCurrentUser: true, createdAt: msg.createdAt)
                .frame(maxWidth: .infinity, alignment: true ? .trailing : .leading)
                .padding(.horizontal)
        }
    }

    private var messageInputBar: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Button(action: {
                print("Image button clicked")
            }) {
                Image(systemName: "photo.artframe")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .padding(3)
                    .foregroundColor(.blue) // Replicates fill-blue-400
            }
            .padding(.trailing, 4)
            .buttonStyle(.plain)
            
            TextField("Message", text: $typingMessage, prompt: Text("Message").foregroundColor(.white.opacity(0.7)))
                .textFieldStyle(DefaultTextFieldStyle())
                .frame(minHeight: 40)
                .lineLimit(6)
                .foregroundColor(.white)
                .font(.system(size: 22))
                .padding(.leading, 4)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(Color(red: 30/255, green: 58/255, blue: 138/255)),
                    alignment: .bottom
                )

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.gray)
                    .padding(10)
                    .background(Color.clear)
                    .clipShape(Circle())
            }
            .frame(height: 40)
            .disabled(typingMessage.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animate: Bool = true) {
        if let lastMessage = chatHelper.realTimeMessages.last {
            if animate {
                withAnimation {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
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

