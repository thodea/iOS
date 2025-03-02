//
//  FullScreenModalView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/22/25.
//


import SwiftUI
import SafariServices

struct FullScreenModalView: View {
    @Environment(\.dismiss) var dismiss
    let url: URL
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            WebView(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                   .edgesIgnoringSafeArea(.bottom) // Make the web view full-screen
                   .background(.white)
                   .onAppear {
                       DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                           self.isLoading = false
                       }
                   }
               
               // Dismiss button overlay
               VStack {
                   Spacer()
                   Button(action: {
                       dismiss()
                   }) {
                       Text("Go Back")
                           .padding()
                           .background(Color.black.opacity(0.7))
                           .foregroundColor(.white)
                           .cornerRadius(8)
                           .padding(.bottom, 30)
                   }
               }
        }
        /*.onAppear {
            // Print the URL when the view appears
            print("URL: \(url)")
        }*/
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
        .edgesIgnoringSafeArea(.bottom)
    }
}
