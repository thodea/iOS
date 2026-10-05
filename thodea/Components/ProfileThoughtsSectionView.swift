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
        LazyVStack(spacing: 5) {
            // 1. Render Thoughts
            ForEach(Array(viewModel.thoughts.enumerated()), id: \.element.id) { index, thought in
                ThoughtView(thought: thought)
                    .onAppear {
                        // 👈 2. Set threshold to trigger 3 items before the bottom
                        let prefetchThreshold = max(0, viewModel.thoughts.count - 3)
                        
                        // 👈 3. If we cross the threshold and have more to load, trigger the fetch!
                        if index >= prefetchThreshold && viewModel.hasMore {
                            Task {
                                await viewModel.fetchThoughts(for: profileUsername, currentUserName: currentLoggedUser)
                            }
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
