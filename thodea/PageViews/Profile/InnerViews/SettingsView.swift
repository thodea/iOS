//
//  SettingsView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/26/24.
//

//
//  SearchView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/22/24.
//

import SwiftUI
import WebKit

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var userCount: Int = 0 // Track selected tab

    
    var body: some View {
            VStack(spacing: 16) {
                // Search TextField
                HStack(){
                    BioButton()
                }.frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Button(action: {
                        // Add your "LOG OUT" button action here
                        print("LOG OUT tapped")
                    }) {
                        Text("LOG OUT")
                            .padding(4).padding(.horizontal, 4)
                            .background(Color(red: 147 / 255, green: 197 / 255, blue: 253 / 255)) // Background color
                            .foregroundColor(.black.opacity(0.9)) // Text color
                            .cornerRadius(2) // Rounded corners
                            .fontWeight(.bold)
                            .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)// Bold text
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                HStack {
                    Button(action: {
                        // Add your "DELETE" button action here
                        print("DELETE tapped")
                    }) {
                        Text("DELETE")
                            .padding(4).padding(.horizontal, 4) // Add padding for button-like appearance
                            .background(Color(red: 252 / 255, green: 165 / 255, blue: 165 / 255)) // Background color
                            .foregroundColor(.black) // Text color
                            .cornerRadius(2) // Rounded corners
                            .fontWeight(.bold) // Bold text
                            .shadow(color: Color.black.opacity(1), radius: 4, x: 0, y: 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
        
                HStack(){
                    Text("users: \(userCount)")
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8).font(.system(size: 19)).foregroundColor(.white.opacity(0.6))
                
                Spacer()

                // Terms of Service and Privacy Policy Links
                HStack(spacing: 8) {
                    NavigationLink(destination: WebView(url: URL(string: "https://thodea.com/policy/terms")!)) {
                                           Text("Terms")
                                               .foregroundColor(.blue)
                                       }

                   NavigationLink(destination: WebView(url: URL(string: "https://thodea.com/policy/privacy")!)) {
                       Text("Privacy")
                           .foregroundColor(.blue)
                   }

                }
                .font(.system(size: 20))
                .frame(maxWidth: .infinity, alignment: .center)
                //.border(.green, width: 2)
                
            }
            .padding()
            .frame(maxWidth: .infinity).background(Color(red: 17/255, green: 24/255, blue: 39/255)).foregroundColor(.white.opacity(0.9))
            .foregroundColor(.white.opacity(0.9))
            .navigationBarBackButtonHidden(true) // Hides the default back button
                .navigationBarItems(leading: Button(action: {
                    self.presentationMode.wrappedValue.dismiss() // Custom back button action
                }) {
                    Image(systemName: "chevron.left") // Custom back button icon
                        .foregroundColor(.blue.opacity(0.8)) // Color of the icon
                })
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
           


    }
}


struct BioButton: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("Add bio")
                .font(.title3)
                .fixedSize()
                .fontWeight(.bold)
                //.border(.red, width: 2)
            
            //rgb(147 197 253
            Circle()
                .fill(Color(red: 147/255, green: 197/255, blue: 253/255)) // Set the color of the circle to blue
                .frame(width: 10, height: 10, alignment: .leading)
                .padding(.horizontal, 8)
                //.border(.green, width: 2)// Set a fixed size for the circle
        }
        //.border(.green, width: 2) // Border for visualization
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
