//
//  ProfileThoughtsSectionView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 9/12/26.
//


import SwiftUI

struct ProfileThoughtsSectionView: View {
    //@StateObject private var viewModel = ProfileThoughtsViewModel()
    @ObservedObject var viewModel: ProfileThoughtsViewModel

    // Pass these in from your parent ProfileBasicView
    let profileUsername: String 
    let currentLoggedUser: String
    
    var body: some View {
        VStack(spacing: 5) {
            // 1. Render Thoughts
            ForEach(viewModel.thoughts) { thought in
                ThoughtView(thought: thought)
                    .onAppear {
                        // Optional: Trigger pagination if they scroll to the last item
                        if thought.id == viewModel.thoughts.last?.id {
                            Task { await viewModel.fetchThoughts(for: profileUsername, currentUserName: currentLoggedUser) }
                        }
                    }
            }
            
            // 2. Exact requested Spinner logic
            if viewModel.isLoading {
                VStack {
                    ContinuousProgressView()
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            // Initial fetch
            if viewModel.thoughts.isEmpty {
                Task {
                    await viewModel.fetchThoughts(for: profileUsername, currentUserName: currentLoggedUser)
                }
            }
        }
        //.border(.red, width: 2)
    }
}
