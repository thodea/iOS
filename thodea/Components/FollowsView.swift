//
//  FollowsView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/6/25.
//




import SwiftUI
import FirebaseFirestore

@MainActor
class FollowListViewModel: ObservableObject {
    @Published var users: [ProfileUserInfo] = []

    private let service = FollowService()

    func loadInitial(username: String, listType: String) async {
        do {
            let result = try await service.getFollow(
                user: username,
                type: listType,
                maxLim: 4,
                snap: nil
            )
            self.users = result
        } catch {
            print("❌ Follow load error:", error)
        }
    }
}

struct FollowsView: View {
    let username: String
    let listType: String // "followers" or "following"
    var users: [ProfileUserInfo] = []
    private let service = FollowService()
    @StateObject private var vm = FollowListViewModel()


    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel // Add this
    

    var body: some View {

        // Equivalent to the main outer div: w-full max-w-[700px] mx-auto

        VStack(spacing: 16) {


            // Equivalent to flex flex-col w-full...

            VStack(alignment: .leading, spacing: 0) {

                // 🔹 LIST OF FOLLOWERS/FOLLOWING
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {

                        ForEach(vm.users) { userInfo in
                            HStack(spacing: 12) {

                                // Profile image
                                if let url = userInfo.imageURL, let imageURL = URL(string: url) {
                                    AsyncImage(url: imageURL) { img in
                                        img.resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(userInfo.username)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)

                                    Text("\(userInfo.followers ?? 0) followers • \(userInfo.thoughts ?? 0) thoughts")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.6))
                                }

                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }

                Spacer() // Pushes content to the top
            }

            .frame(maxWidth: 700) // max-w-[700px]

            Spacer() // Pushes the whole block to the top of the view

        }
        .onAppear {
            Task {
                await vm.loadInitial(username: username, listType: listType)
            }
        }
        .padding()
        .frame(maxWidth: .infinity).background(Color(red: 17/255, green: 24/255, blue: 39/255)).foregroundColor(.white.opacity(0.9))
        .foregroundColor(.white.opacity(0.9))
        .navigationBarBackButtonHidden(true) // Hides the default back button
        .navigationBarItems(leading:

            HStack(spacing: 8) {
                // Custom Back Button
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue.opacity(0.8))
                }

                // Dynamic Title Left-Aligned next to Caret

                HStack {
                    Text(username)
                        .font(.system(size: 18, weight: .semibold)) // Bold username
                        .foregroundColor(.white.opacity(0.9))

                    Text("/ \(listType)")
                        .font(.system(size: 18, weight: .regular)) // Regular listType
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}



// Preview structure for development environment

#Preview {
    FollowsView(username: "JohnDoe", listType: "followers")
        .environmentObject(AuthViewModel())
}
