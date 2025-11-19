//
//  BioView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 11/16/25.
//


import SwiftUI
import FirebaseFirestore

struct BioView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel // Add this

    // State variables to hold the input value and handle the logic
    @State private var bioValue: String = ""
    @State private var bioUpdated: Bool = false // Tracks if the bio has been updated/changed
    @State private var bioUpdating: Bool = false // Tracks if the bio has been updated/changed
    @State private var updateTask: Task<Void, Never>? = nil
    
    
    // Constants for the character limit
    private let characterLimit: Int = 75
    
    // Computed property to check if the length is exceeded
    private var isLengthExceeded: Bool {
        bioValue.count >= characterLimit
    }
    
    // Computed property for the border color based on length and update status
    private var borderColor: Color {
           // return Color(red: 0/255, green: 130/255, blue: 0/255) // Custom dark green for updated/saved (approximation)
        if authViewModel.currentUser?.bio != nil {
             // Custom dark blue (approximation for default)
            if self.bioUpdating {
                return Color(red: 30/255, green: 58/255, blue: 138/255) // Custom dark blue (approximation for default)
            } else {
                return Color(red: 0/255, green: 130/255, blue: 0/255) //
            }
        } else {
            return Color(red: 30/255, green: 58/255, blue: 138/255) // Custom dark blue (approximation for default)
        }
    }
    
    var body: some View {
        // Equivalent to the main outer div: w-full max-w-[700px] mx-auto
        VStack(spacing: 16) {
            
            // Equivalent to flex flex-col w-full...
            VStack(alignment: .leading, spacing: 0) {
                
                // Text input field
                // Equivalent to the input tag with onChange/value and styling
                HStack {
                    TextField("Bio", text: $bioValue)
                        .foregroundColor(Color(red: 229/255, green: 231/255, blue: 235/255))
                        .font(.system(size: 26))
                        .lineLimit(1)
                        .padding(.vertical, 4)
                        .onChange(of: bioValue) { newValue in
                            // Protect initial load
                            let originalBio = authViewModel.currentUser?.bio ?? ""
                            guard newValue != originalBio else { return }
                            
                            // newValue is the new value of bioValue
                            self.bioUpdating = true
                            bioUpdated = false
                            updateTask?.cancel()

                            if newValue.count > characterLimit {
                                // Enforce limit directly on the binding value
                                bioValue = String(newValue.prefix(characterLimit))
                            }
                            
                            updateTask = Task {
                                do {
                                    
                                    try await Task.sleep(nanoseconds: 700_000_000) // 0.35 sec
                                    
                                    // 🛑 CHANGE IS HERE: Add 'try' before 'await' for the throwing async function
                                    try await updateBio(username: authViewModel.currentUser?.username ?? "", bio: bioValue)
                                    
                                } catch is CancellationError {
                                    // This is the common case: the previous task was cancelled before sleep finished.
                                    // Do nothing, as a new task has started.
                                } catch {
                                    // Handle the error thrown by updateBio or any other error.
                                    print("Error updating bio: \(error.localizedDescription)")
                                }
                            }
                        }
                    // Clear button (only shows when text is not empty)
                    if !bioValue.isEmpty {
                            Button(action: { bioValue = "" }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.gray.opacity(0.6))   // gray “X”
                                    .font(.system(size: 16, weight: .bold))
                                    .padding(8)                            // optional tap target
                            }
                            .background(Color.clear)                       // fully transparent
                            .contentShape(Circle())                        // keeps good tap area
                        }
                }
                .background(
                    VStack {
                        Spacer()
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(borderColor)
                    }
                )
                
                
                // Character limit warning (isLengthExceeded && <div>)
               // if isLengthExceeded {
                HStack {
                    // Equivalent to flex flex-col items-center justify-center mt-0.5
                    Text("\(characterLimit) char limit")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(isLengthExceeded ? .red : .gray)
                        .padding(.bottom, 12)
                        //.border(.red, width: 2)
                        .padding(.top, 8)
                    Spacer() // Pushes the text to the left/start
                }
                //}
                
                Spacer() // Pushes content to the top
            }
            .frame(maxWidth: 700) // max-w-[700px]
            
            Spacer() // Pushes the whole block to the top of the view
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
        .onAppear {
            bioValue = authViewModel.currentUser?.bio ?? ""
        }
        .toolbar{
            ToolbarItem(placement: .principal) {
                Text("Bio")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
        
    @MainActor
    func updateBio(username: String, bio: String?) async throws {
        let ref = Firestore.firestore().collection("user").document(username)
        
        // Explicitly define the dictionary type to be [String: Any]
        // The Swift compiler can often determine that [String: Any] is
        // safe when the values (String and FieldValue) are Sendable.
        var data: [String: Any]

        if let bio = bio, !bio.isEmpty {
            data = ["bio": bio] // bio (String) is Sendable
            authViewModel.currentUser?.bio = bio
        } else {
            data = ["bio": FieldValue.delete()] // FieldValue is Sendable
            authViewModel.currentUser?.bio = nil
        }
        
        // Passing the constrained 'data' dictionary often resolves the warning
        try await ref.updateData(data)
        self.bioUpdating = false
    }
    
}

// Preview structure for development environment
#Preview {
    // 1. Instantiate the view without arguments (as defined by struct BioView: View)
    BioView()
        // 2. Attach an instance of the EnvironmentObject to the view hierarchy
        .environmentObject(AuthViewModel())
}
