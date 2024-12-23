//
//  FeedView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/22/24.
//

import SwiftUI


struct FeedView: View {
    var body: some View {
        ScrollView { // Wrap the content in a ScrollView
            
            VStack {
                Text("")
            }.frame(maxHeight:1)
            
            VStack {
                Text("follow to customize feed")
                    .font(.headline) // Adjust font size and weight
                    .padding(.leading, 8)
                    .padding(.trailing, 8)
                    .padding(.bottom, 2)
                    .padding(.top, 2)
                    .foregroundColor(Color.white.opacity(0.8))
                    .background(Color(red: 55 / 255, green: 65 / 255, blue: 81 / 255)) // Add a background color
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)
            }
            
            monthlyLovedLabel()
            
            mostFollowedLabel()
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure the ScrollView covers the full scree
        //.border(Color.red, width: 2) // To see the frame edges clearly
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}


struct monthlyLovedLabel: View {
    var body: some View {
        Text("monthly loved")
            .font(.headline) // Adjust font size and weight
            .padding(4)
            .foregroundColor(.clear) // Text becomes transparent to show gradient
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
, Color(red: 192 / 255, green: 132 / 255, blue: 252 / 255)
, Color(red: 59 / 255, green: 130 / 255, blue: 246 / 255)
]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask(Text("monthly loved")) // Apply gradient as a mask to text
            )
            .cornerRadius(8) // Rounded corners
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.5), Color.purple.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.black, radius: 4, x: 0, y: 2) // Shadow effect
    }
}


struct mostFollowedLabel: View {
    var body: some View {
        Text("most followed")
            .font(.headline) // Adjust font size and weight
            .padding(4) // Equivalent to `pl-2 pr-2`
            .foregroundColor(.clear) // Make the text transparent to show gradient
            .background(
                //rgb(59 130 246
                //rgb(96 165 250
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 59 / 255, green: 130 / 255, blue: 246 / 255)
, Color(red: 96 / 255, green: 165 / 255, blue: 250 / 255)
, Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask(Text("most followed")) // Apply gradient as a mask to the text
            )
            .cornerRadius(8) // Rounded corners
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.black, radius: 4, x: 0, y: 2) // Shadow effect
    }
}
