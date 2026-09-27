//
//  ThoughtView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/7/25.
//

import SwiftUI
import SafariServices
import FirebaseDatabase

struct ThoughtView: View {
    
    private static let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    
    let thought: Thought
    @State private var isHeartTapped = false
    @State private var heartScale: CGFloat = 1.0
    @State private var heartColor: Color = Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255)
    @State private var showSafariView = false
    @State private var urlToOpen: URL?
    @State private var localClickCount: Int


    init(thought: Thought) {
        self.thought = thought
        _isHeartTapped = State(initialValue: thought.loved)
        _localClickCount = State(initialValue: thought.clickCount ?? 0) // <-- ADD THIS
    }
    
    func findURLs(in text: String) -> [String] {
       let matches = Self.linkDetector?.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text)) ?? []
       
       return matches.compactMap { match in
           return (text as NSString).substring(with: match.range)
       }
    }
    
    // Function to highlight URLs in text
    func highlightText(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        let urls = findURLs(in: text)
        print(urls)
        for url in urls {
            if let range = attributedString.range(of: url) {
                attributedString[range].foregroundColor = .blue
                //attributedString[range].underlineStyle = .single
                // Make the URL tappable using `.link`
                if let url = URL(string: url) {
                    attributedString[range].link = url
                    //attributedString[range].link = url
                }
                print( attributedString[range])
                //print(attributedString[range])
            }
        }
        print(attributedString)
        return attributedString
    }
    
    var timeAgo: String {
         if let createdAt = thought.createdAt {
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
        //let _ = print("DEBUG message:", thought.message)

        //Color.green.edgesIgnoringSafeArea(.all)
        VStack(alignment: .leading, spacing: 8) {
            HStack(){
                if let imageURL = thought.imageURL {
                    ImageView(imageURL: imageURL, size: 24);
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
                Text(thought.profileDeleted == true ? "Deleted User" : thought.createdBy)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, -2)
                    /*.environment(\.openURL, OpenURLAction { url in
                            // Handle the URL opening here
                            return .handled
                        })*/
                     // Add inset padding
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 6)
            //.border(.red, width: 2)

            Text(highlightText(thought.message))
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .lineLimit(5) // Limit to 2 lines
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.openURL, OpenURLAction { url in
                    // Custom action before opening URL
                    //print("Navigating to \(url)")
                    //print(url)
                    handleLinkClick() // <-- ADD THIS
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
                //.border(.red, width: 2)
                       
                /*.fullScreenCover(isPresented: $showSafariView) {
                    if urlToOpen != nil {
                        WebView(url: urlToOpen!).edgesIgnoringSafeArea(.all)
                    }
                }*/
            
            if thought.firstUrl != nil, (!thought.urlTitle.isEmpty || !thought.urlDescription.isEmpty) {
                HStack(alignment: .top, spacing: 4) {
                    Rectangle()
                        .fill(Color(red: 30/255, green: 58/255, blue: 138/255))
                        .frame(width: 2)

                    VStack(alignment: .leading, spacing: 1) {
                        if !thought.urlTitle.isEmpty {
                            Text(thought.urlTitle)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        if !thought.urlDescription.isEmpty {
                            Text(thought.urlDescription)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.top, 2)
                .contentShape(Rectangle())
                .onTapGesture {
                    if let urlString = thought.firstUrl, let url = URL(string: urlString) {
                        handleLinkClick()
                        self.urlToOpen = url
                        self.showSafariView = true
                    }
                }
                //.border(.green, width: 2)
            }
            
            HStack(spacing: 0){
                HStack(spacing: 0) {
                    Image(systemName: isHeartTapped ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isHeartTapped ? .red : Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255)) // Set color based on tapped state
                        .scaleEffect(heartScale) // Apply scaling effect
                        .onTapGesture {
                            if (!isHeartTapped) {
                                // 1. Make it slightly larger so the fast pop is visible
                                heartScale = 1.15
                                
                                // 2. Drop the delay to 0.05 (just enough to register the frame)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    
                                    // 3. Use a fast, bouncy spring instead of easeInOut
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                                        heartScale = 1.0
                                    }
                                }
                            }
                            isHeartTapped.toggle()
                        }
                    Text(formatNumber(thought.loveCount))
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                        .padding(.leading, 4)
                }
                HStack(spacing: 0) {
                    Image(systemName: "text.bubble.rtl")
                         // You can set the color to red to represent a like
                        .font(.system(size: 20))
                    Text("\(formatNumber(thought.commentCount))")
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                        .padding(.leading, 4)
                }.padding(.leading, 12)
                
            }
            .foregroundColor(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 4)

            HStack(spacing: 0){
                
                HStack(spacing: 0) {
                    Text("\(formatNumber(thought.seenCount))")
                        .font(.system(size: 14))
                    
                    Image(systemName: "eye") // Use "eye.fill" for a filled eye icon
                            .foregroundColor(.gray)
                            .opacity(0.75)
                            .font(.system(size: 13)) // Adjust the size as
                            .padding(.leading, 4)
                }
                
                if thought.firstUrl != nil {
                    HStack(spacing: 0) {
                        //Text("\(formatNumber(thought.clickCount ?? 0))")
                        Text("\(formatNumber(localClickCount))")
                            .font(.system(size: 14))
                        
                        Image(systemName: "link") // Apple's native chain link icon
                            .foregroundColor(.gray)
                            .opacity(0.75)
                            .font(.system(size: 11, weight: .semibold)) 
                            .padding(.leading, 4)
                    }
                    .padding(.leading, 12) // Gives it nice breathing room from the eye icon
                }
            
                Spacer()

                if thought.createdAt != nil {
                    Text("\(timeAgo)")
                        .italic()
                }
            }
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
           
        }
        .onChange(of: urlToOpen) { _, newURL in
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
        .padding(.horizontal, 0)
        .padding(.vertical, 6) // Outer padding for the entire VStack
    }
    
    private func handleLinkClick() {
        // 1. Optimistic UI update (Instant feedback)
        localClickCount += 1
        
        // 2. Database Update (Background fire-and-forget)
        // NOTE: Replace `thought.postId` with whatever your ID property is named.
        let ref = Database.database().reference().child("thoughts/\(thought.postId)/clicked")
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            let currentCount = currentData.value as? Int ?? 0
            currentData.value = currentCount + 1
            return TransactionResult.success(withValue: currentData)
        }) { error, _, _ in
            if let error = error {
                print("Failed to update click count: \(error.localizedDescription)")
            }
        }
    }
    
}
