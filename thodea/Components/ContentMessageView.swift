//
//  ContentMessageView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/25/25.
//


import SwiftUI

struct ContentMessageView: View {
    var contentMessage: String
    var isCurrentUser: Bool
    var createdAt: Date?
    
    @State private var currentTime = Date()

    // Computed property to format the date
    var timeAgo: String {
        guard let createdAt = createdAt else { return "Unknown time" }

        let timeElapsed = Int(currentTime.timeIntervalSince(createdAt))

        if timeElapsed < 60 {
            return "\(timeElapsed) second\(timeElapsed == 1 ? "" : "s") ago"
        } else if timeElapsed < 3600 {
            let minutes = timeElapsed / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if timeElapsed < 86400 {
            let hours = timeElapsed / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = timeElapsed / 86400
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
    // Function to start a timer that updates every second
    func startTimer() {
        // Invalidate any previous timers and start a new one
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.currentTime = Date() // Update the current time every second
        }
    }

    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading) {
            HStack {
               Text(contentMessage)
                   .padding(12)
                   .font(.system(size: 18))
                   .foregroundColor(Color.white)
                   .background(isCurrentUser ? Color(red: 23/255, green: 37/255, blue: 84/255) : Color(red: 30/255, green: 41/255, blue: 59/255))
                   .cornerRadius(10)
                   .padding(.vertical, 4)

               // Add heart at the end for the other user
               if !isCurrentUser {
                   Image(systemName: "heart")
                       .font(.system(size: 20))
                       .foregroundColor(Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255)) // Set color based on tapped state
                       //.scaleEffect(heartScale) // Apply scaling effect
               }
            }
            .padding(isCurrentUser ? .leading : .trailing, 30)

           
            // Display the formatted time
           Text(timeAgo)
                .font(.system(size: 16))
                .foregroundColor(.gray.opacity(0.93))
                .italic()
        }
        .onAppear {
            // Start the timer when the view appears
            startTimer()
        }
    }
}
