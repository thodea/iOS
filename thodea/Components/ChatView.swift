//
//  ThoughtView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/7/25.
//

import SwiftUI
import SafariServices

struct ChatView: View {
    let chat: Thought
    @State private var isHeartTapped = false
    @State private var heartScale: CGFloat = 1.0
    @State private var heartColor: Color = Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255)
    @State private var showSafariView = false
    @State private var urlToOpen: URL?
    
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
         if let createdAt = chat.createdAt {
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
    
    var body: some View {
        //Color.green.edgesIgnoringSafeArea(.all)
        VStack(alignment: .leading, spacing: 8) {
            HStack(){
                if let imageURL = mockThought.imageURL {
                    ImageView(imageURL: imageURL, size: 35).padding(.trailing, 4);
                    /*AsyncImage(url: URL(string: imageURL), transaction: Transaction(animation: .easeInOut)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 20, height: 20)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            case .failure:
                                Image(systemName: "photo")
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }*/
                }
                Text("\(chat.createdBy)")
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

                    if chat.createdAt != nil {
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

            Text(highlightText(chat.message))
                .font(.system(size: 20))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .lineLimit(1) // Limit to 2 lines
                .truncationMode(.tail)
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
                .padding(.bottom, 4)
                       
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
