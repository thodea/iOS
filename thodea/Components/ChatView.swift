//
//  ThoughtView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/7/25.
//

import SwiftUI
import SafariServices

struct ChatView: View {
    let chat: Chat
    @State private var isHeartTapped = false
    @State private var heartScale: CGFloat = 1.0
    @State private var heartColor: Color = Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255)
    @State private var showSafariView = false
    @State private var urlToOpen: URL?
    @EnvironmentObject var authViewModel: AuthViewModel // Add this
    
    var username: String {
        authViewModel.currentUser?.username ?? ""
    }
    
    // Add this inside ChatView
    private var isIncomingMessage: Bool {
        username != chat.lastMessagedBy
    }

    // Custom Blue Colors
    private let brandBlue = Color(red: 37/255, green: 99/255, blue: 235/255)
    private let shadowBlue = Color(red: 30/255, green: 64/255, blue: 175/255)
    
    
    
    private var placeholderView: some View {
        ZStack {
            // 1. The solid background that "catches" the shadow
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 17/255, green: 24/255, blue: 39/255)) // Or .white
            
            // 2. The border/stroke (Optional, but adds definition)
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
            
            // 3. The Icon
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .padding(8)
                .foregroundColor(.gray)
        }
        .frame(width: 34, height: 34)
        // 4. Modern Shadow Styling
        .shadow(color: isIncomingMessage ? shadowBlue.opacity(0.8) : .black.opacity(0.3),
                    radius: isIncomingMessage ? 4 : 1,
                    x: 1, y: 2)
        //.shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 2)
    }

    
    func findURLs(in text: String) -> [String] {
       let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
       let matches = detector?.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text)) ?? []
       
       return matches.compactMap { match in
           return (text as NSString).substring(with: match.range)
       }
    }
    
    // Function to highlight URLs in text
    func highlightText(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        let urls = findURLs(in: text)

        for url in urls {
            if let range = attributedString.range(of: url) {
                attributedString[range].foregroundColor = .blue
                //attributedString[range].underlineStyle = .single
                // Make the URL tappable using `.link`
                if let url = URL(string: url) {
                    attributedString[range].link = url
                    //attributedString[range].link = url
                }
                //print( attributedString[range])
                //print(attributedString[range])
            }
        }
        
        return attributedString
    }
    
    var timeAgo: String {
         if let createdAt = chat.lastMessagedAt {
             let timeElapsed = Int(Date().timeIntervalSince(createdAt))
             if timeElapsed < 60 {
                 return "\(timeElapsed) seconds ago"
             } else if timeElapsed < 3600 {
                 let minutes = timeElapsed / 60
                 return "\(minutes) minutes ago"
             } else if timeElapsed < 86400 {
                 let hours = timeElapsed / 3600
                 return "\(hours) hours ago"
             } else {
                 let days = timeElapsed / 86400
                 return "\(days) days ago"
             }
         }
         return "Unknown time"
     }
    
    private var messageStyle: (text: String, color: Color, opacity: Double, isItalic: Bool, icon: String?) {
        let softRed = Color(red: 252/255, green: 165/255, blue: 165/255)
        
        guard let msg = chat.lastMessage else {
            return ("deleted message", softRed, 0.25, true, nil) // Added icon name
        }
        
        if msg.isEmpty {
            return ("media", .white, 0.5, false, "photo.artframe") // Added icon name
        }
        
        return (msg, .white, 1.0, false, nil) // No icon for regular text
    }
    
    var body: some View {
        //Color.green.edgesIgnoringSafeArea(.all)
        VStack(alignment: .leading, spacing: 2) {
            HStack(){
                if let urlString = chat.imageURL, let url = URL(string: urlString) {
                    // Scenario 1: URL exists, attempt to load
                    AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 34, height: 34)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isIncomingMessage ? brandBlue : Color.clear, lineWidth: 0.5)
                                )
                                .shadow(color: isIncomingMessage ? shadowBlue.opacity(0.8) : .black.opacity(0.5),
                                        radius: 3, x: 2, y: 1)
                            
                        case .failure(_):
                            // Scenario 2: URL exists but loading failed
                            placeholderView
                            
                        case .empty:
                            // Loading state
                            ProgressView()
                                .frame(width: 34, height: 34)
                            
                        @unknown default:
                            placeholderView
                        }
                    }
                    .padding(.trailing, 4)
                } else {
                    // Scenario 3: imageURL is nil or invalid string
                    placeholderView
                        .padding(.trailing, 4)
                }
                Text("\(chat.otherUser(currentUsername: username))")
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, -2)
                    /*.environment(\.openURL, OpenURLAction { url in
                            // Handle the URL opening here
                            return .handled
                        })*/
                     // Add inset padding
                Spacer()

                HStack(spacing: 0){
                
                    Spacer()

                    if chat.lastMessagedAt != nil {
                        Text("\(timeAgo)")
                            .italic()
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(.top, -2)

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 10)
            //.border(.red, width: 2)
            let style = messageStyle
            
                HStack(spacing: 6) { // This puts them on the same line
                    if let iconName = style.icon {
                        Image(systemName: iconName)
                            .font(.system(size: 16)) // Scales with text
                            .foregroundColor(.blue)
                            .offset(y: 1)
                            .opacity(style.opacity)
                    }
                    
                    Text(highlightText(style.text))
                        .font(.system(size: 20))
                        .italic(style.isItalic)
                        .foregroundColor(style.color) // Apply dynamic color
                        .opacity(style.opacity)
                        .lineLimit(1) // Limit to 2 lines
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .environment(\.openURL, OpenURLAction { url in
                    // Custom action before opening URL
                    //print("Navigating to \(url)")
                    //print(url)
                   self.urlToOpen = url
                   self.showSafariView = true
                    return .handled
                    //return .systemAction // Opens in system browser
                })
                .sheet(isPresented: $showSafariView) {
                    VStack(spacing: 0) {
                        ZStack {
                            if self.urlToOpen != nil {
                                FullScreenModalView(url: urlToOpen!)  // Use safely unwrapped url
                            } /*else {
                                Text("Invalid URL").onAppear(){
                                    print("Invalid URL: \(String(describing: urlToOpen!))")

                                }
                            }*/
                        }
                    }
                    
                }
                .padding(.top, 5)
                .padding(.bottom, 8)
                       
                /*.fullScreenCover(isPresented: $showSafariView) {
                    if urlToOpen != nil {
                        WebView(url: urlToOpen!).edgesIgnoringSafeArea(.all)
                    }
                }*/
           
        }
        .onChange(of: urlToOpen) { newURL in
            if newURL != nil {
                    //print("New URL: \(newURL.absoluteString)")
                } else {
                    //print("URL was reset.")
                }
            }
        .background(Color(red: 17/255, green: 24/255, blue: 39/255))
        .cornerRadius(5)
        .shadow(color: .black, radius: 2, x: 1, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 5) // Apply rounded corners
                .stroke(Color(red: 31/255, green: 41/255, blue: 55/255), lineWidth: 1) // Border with blue color
        )
        .foregroundColor(.white) // Apply white color to all Text views
        .padding(.vertical, 0) // Outer padding for the entire VStack
    }
}
