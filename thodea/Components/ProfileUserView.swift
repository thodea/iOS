//
//  ProfileUserView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/29/25.
//

import SwiftUI
import PhotosUI


struct ProfileUserView: View {
    let username: String
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var authViewModel: AuthViewModel // Add this

    var body: some View {
        
        ZStack(alignment: .top) {
            Color(red: 17/255, green: 24/255, blue: 39/255)
            .ignoresSafeArea()
            ProfileBasicView(username: username)
        }
    }
}


#Preview {
    ProfileUserView(username: "delete")
        .environmentObject(AuthViewModel())
}
