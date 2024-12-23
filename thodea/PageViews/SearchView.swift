//
//  SearchView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/22/24.
//

import SwiftUI

struct SearchView: View {
    @State private var searchValue: String = ""
    @State private var selectedItem: String? = "Thoughts"
    @State private var selectedTime: String? = "Today"
    
    var body: some View {
        VStack(spacing: 16) {
            // Search TextField
            ZStack(alignment: .leading) {
                if searchValue.isEmpty {
                    Text("Search")
                        .foregroundColor(Color.gray)
                        .font(.system(size: 26))
                }
                
                HStack {
                    TextField("", text: $searchValue)
                        .font(.system(size: 26))
                        .foregroundColor(Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255))
                        .frame(maxWidth: .infinity, maxHeight: 36)
                        .submitLabel(.search)
                    
                    if !searchValue.isEmpty {
                        Button(action: {
                            searchValue = ""
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(Color.gray.opacity(0.7))
                                .font(.system(size: 16, weight: .bold))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.bottom, 3)
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color(red: 30 / 255, green: 58 / 255, blue: 138 / 255))
                        .frame(height: 3)
                }
            )
            
            
            // "Thoughts" and "Users" Buttons
            HStack(spacing: 16) {
                Button("Thoughts") {
                    selectedItem = "Thoughts"
                }
                .padding(2)
                .padding(.horizontal, 8)
                // rgb(7 89 133
                .background(selectedItem == "Thoughts" ? Color(red: 7 / 255, green: 89 / 255, blue: 133 / 255) : Color.clear)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)
                
                Button("Users") {
                    selectedItem = "Users"
                }
                .padding(2)
                .padding(.horizontal, 8)
                .background(selectedItem == "Users" ? Color(red: 7 / 255, green: 89 / 255, blue: 133 / 255) : Color.clear)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.system(size: 22))
            
            // Conditional Time Buttons for "Thoughts" selection
            if selectedItem == "Thoughts" {
                HStack(spacing: 16) {
                    Button("Today") {
                        selectedTime = "Today"
                    }
                    .padding(2)
                    .padding(.horizontal, 8)
                    .background(selectedTime == "Today" ? Color(red: 7 / 255, green: 89 / 255, blue: 133 / 255) : Color.clear)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)
                    
                    Button("Week") {
                        selectedTime = "Week"
                    }
                    .padding(2)
                    .padding(.horizontal, 8)
                    .background(selectedTime == "Week" ? Color(red: 7 / 255, green: 89 / 255, blue: 133 / 255) : Color.clear)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)
                    
                    Button("All") {
                        selectedTime = "All"
                    }
                    .padding(2)
                    .padding(.horizontal, 8)
                    .background(selectedTime == "All" ? Color(red: 7 / 255, green: 89 / 255, blue: 133 / 255) : Color.clear)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)
                    
                    Button("Recent") {
                        selectedTime = "Recent"
                    }
                    .padding(2)
                    .padding(.horizontal, 8)
                    .background(selectedTime == "Recent" ? Color(red: 7 / 255, green: 89 / 255, blue: 133 / 255) : Color.clear)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 22))
            }
            
            
            Spacer()
        }
        .padding()
        
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}

