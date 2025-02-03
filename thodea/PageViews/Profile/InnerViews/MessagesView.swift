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

    
    var body: some View {
        VStack(spacing: 16) {
            UserChatView().environmentObject(chatHelper)
        }
        //.border(.green, width: 2)
        //.edgesIgnoringSafeArea(.bottom)
        .padding(0)
        .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 17/255, green: 24/255, blue: 39/255)).foregroundColor(.white.opacity(0.9))
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
                Text("Messages")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}


struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}
