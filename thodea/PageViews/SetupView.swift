//
//  SetupView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 3/1/25.
//


import SwiftUI
import WebKit

struct SetupView: View {
    @State private var username: String = ""
    @State private var usernameCopy: String = ""
    @State private var emailSent: Bool = false
    @State private var showSafariView = false
    @State private var selectedURL: URL?
    @State private var isError: Bool = false
    @State private var errorMessage: String = ""
    @EnvironmentObject var authViewModel: AuthViewModel // Add this
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Color(red: 17/255, green: 24/255, blue: 39/255)
        .ignoresSafeArea()
        .overlay {
            VStack(spacing: 12) {
                HStack() {
                    Text("Set username").font(.system(size: 26)).foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Button(action: {
                        // LOG OUT action
                        authViewModel.signOut()
                        presentationMode.wrappedValue.dismiss()
                        print("LOG OUT tapped")
                    }) {
                        Image(systemName: "arrow.left.to.line.square")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .foregroundColor(Color(red: 37/255, green: 99/255, blue: 235/255))
                    }
                }.padding(.horizontal)
                VStack() {
                    TextField(
                        "",
                        text: $username,
                        prompt: Text(isError ? errorMessage : "username")
                            .foregroundColor(isError ? Color(red: 255/255, green: 131/255, blue: 131/255) : .gray)
                            .font(.title2)
                    )
                    .onChange(of: username) { newValue in
                        DispatchQueue.main.async {
                            let regex = "^[a-z0-9_]*$" // Only allows lowercase letters, numbers, and underscores
                            let filteredValue = newValue.lowercased().prefix(14) // Convert to lowercase & limit length
                            let finalValue = String(filteredValue).filter { String($0).range(of: regex, options: .regularExpression) != nil }

                            if username != finalValue {
                                username = finalValue
                            }
                        }
                    }
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal)
                    .overlay(
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color(red: 30 / 255, green: 58 / 255, blue: 138 / 255))
                                .frame(height: 3)
                        }
                        .padding(.horizontal)
                    )



                    
                    Text("a-z, 0-9, _ only 14 char max")
                        .font(.system(size: 14))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 12)
                                    //.border(.red, width: 2)
                                    .padding(.horizontal)
                }
                
                if username != "" {
                    Button(action: {
                        //userLogIn()
                    }) {
                        Text("Next")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(Color(red: 30/255, green: 58/255, blue: 138/255))
                            .foregroundColor(.white)
                            .cornerRadius(5)
                            .padding(.horizontal)
                    }.padding(.bottom, 18)
                }

                Spacer()
            }
            //.border(.red, width: 2)
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .frame(maxWidth: .infinity, alignment: .top)
            .foregroundColor(.white)
        }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
    }
}
