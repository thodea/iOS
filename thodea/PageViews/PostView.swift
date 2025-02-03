//
//  PostView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/22/24.
//

import SwiftUI
import Combine
import AVKit

struct PostView: View {
    @Binding var selectedNavItem: String
    @State private var message: String = ""
    @State private var postIsUploading: Bool = false
    @State private var canPost: Bool = false
    @State private var image: UIImage? = nil
    @State private var videoURL: URL? = nil
    @State private var videoThumb: UIImage? = nil
    @State private var dropDownUsers: [User] = [] // Replace `User` with your model
    @State private var selectedOption: Int? = nil
    @State private var isLengthExceeded: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            // Uploading overlay
            
            VStack() {
                Button(action: {
                    selectedNavItem = "feed"
                }) {
                    BarIcon()
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .trailing) // Align to the trailing edge
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 30)
            //.border(Color.green, width: 2)
                
            
            MultilineTextField("Thought", text: $message)
            

            VStack {
                HStack {
                    AssetSVGView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    //Text("img").font(.title3).frame(maxWidth: .infinity, alignment: .leading)
                        
                    if message.count >= 750 {
                        Text("750 char limit")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(Color(red: 239 / 255, green: 68 / 255, blue: 68 / 255))
                    }
                    
                    if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        
                        ResetText()
                            .onTapGesture {
                                message = "" // Remove the message when tapped
                            }
                    } else {
                        Text("").frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 25, alignment: .trailing)
                .padding(.top, 2)
                .padding(.bottom, 2)
                //.border(Color.green, width: 2)
            }
            .padding(.top, 5)
            .frame(maxWidth: .infinity, maxHeight: 30)
        
            //SuperTextField(placeholder: Text("Thought"), text: $message, isLengthExceeded: $isLengthExceeded)
            //.border(Color.gray, width: 1) // Optional border for visibility
            
            if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack {
                    Button(action: handlePost) {
                        Text("POST")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 5)
                            .padding(.bottom, 5)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)
                    }
                }.padding(.top, 10)
            }
            
            if postIsUploading {
                ZStack {
                    VStack {
                        Text("Posting")
                            .font(.headline)
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        ProgressView()
                            .scaleEffect(1.5)
                    }
                }
            }
                
            
            // Preview Section
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if let videoURL = videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(maxHeight: 400)
                    .cornerRadius(8)
            }

            // Post Button
          
        }
        .padding()
    }

    func handlePost() {
        // Post logic here
    }
}


struct PostView_Previews: PreviewProvider {
    @State static var previewNavItem = "feed" // Add a State variable for the preview
    static var previews: some View {
        PostView(selectedNavItem: $previewNavItem)
    }
}


struct BarIcon: View {
    var body: some View {
        HStack(spacing: 3) {
            // First Bar
            RoundedRectangle(cornerRadius: 5)
                .frame(width: 5, height: 20) // Adjust dimensions for a 0.67 width scaled
                .foregroundColor(Color.gray.opacity(0.8))

            // Middle Bar
            RoundedRectangle(cornerRadius: 5)
                .frame(width: 5, height: 25)
                .foregroundColor(Color.gray.opacity(0.8))

            // Third Bar
            RoundedRectangle(cornerRadius: 5)
                .frame(width: 5, height: 20)
                .foregroundColor(Color.gray.opacity(0.8))
        }
        .frame(width: 20, height: 20, alignment: .center)
        .contentShape(Rectangle())
        .background(.clear)
    }
}


struct ResetText: View {
    var body: some View {
        HStack {
            Text("reset")
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .trailing) // Align to the trailing edge
            
            Circle()
                .fill(Color.blue) // Set the color of the circle to blue
                .frame(width: 13, height: 13) // Set the size of the circle
        }
    }
}


struct AssetSVGView: View {
    var body: some View {
        ZStack {
            // First path
            Path { path in
                path.move(to: CGPoint(x: 7, y: 7))
                path.addArc(center: CGPoint(x: 7, y: 7), radius: 3, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
            }
            .fill(Color(red: 59/255, green: 130/255, blue: 246/255))
            
            
            Path { path in
                path.move(to: CGPoint(x: 7, y: 7))
                path.addArc(center: CGPoint(x: 7, y: 7), radius: 1, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
            }
            .fill(Color(red: 17/255, green: 24/255, blue: 39/255))
            
                        
            // Second path
            Path { path in
                path.move(to: CGPoint(x: 3, y: 3))
                path.addRoundedRect(in: CGRect(x: 0, y: 0, width: 24, height: 24), cornerSize: CGSize(width: 0, height: 0))
                path.addRect(CGRect(x: 3, y: 3, width: 18, height: 18))
            }
            .fill(Color.clear) // fill-blue-400 equivalent
     
            RoundedRectangle(cornerRadius: 2)
               .frame(width: 28, height: 18) // Adjust the height to show only half
               .rotationEffect(.degrees(45)) // Rotate the rectangle
               .offset(x: 10, y: 14) // Position it at the bottom
               .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
            
            //3rd element
            RoundedRectangle(cornerRadius: 2)
                .frame(width: 25, height: 15.5) // Adjust the height to show only half
               .rotationEffect(.degrees(45)) // Rotate the rectangle
               .offset(x: 10, y: 15) // Position it at the bottom
               .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
        }
        .border(Color(red: 59/255, green: 130/255, blue: 246/255), width: 2.5)
        .frame(width: 27, height: 20)
        .cornerRadius(2)
        //.clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
