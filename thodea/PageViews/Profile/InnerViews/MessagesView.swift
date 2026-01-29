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
        //.border(.red, width: 2)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 17/255, green: 24/255, blue: 39/255), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            // The Back Button (Leading)
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue.opacity(0.8))
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Your action here
                }) {
                    Image(systemName: "ellipsis") // Or "ellipsis.circle"
                        .rotationEffect(.degrees(90)) // Makes it vertical to match your SVG
                        .font(.title2)
                        .padding(.trailing, -8) // This "cheats" the system padding
                        .foregroundColor(Color(uiColor: .systemGray)) // Matches fill-gray-400
                }
            }
        }
    }
}


struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { // <--- Wrap it here
            MessagesView()
        }
    }
}
