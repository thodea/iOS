//
//  UserChatView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/25/25.
//

import SwiftUI
import PhotosUI
import AVFoundation
import AVKit // <--- ADD THIS

// 1. Helper Struct to make URL Identifiable for sheets
struct PlayableVideo: Identifiable {
    let id = UUID()
    let url: URL
}

struct UserChatView: View {
    @State private var typingMessage: String = ""
    @EnvironmentObject var chatHelper: ChatHelper
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var previousMessageCount: Int = 0
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var selectedVideoURL: URL? = nil
    @State private var isShowingPicker = false
    
    @State private var playableVideo: PlayableVideo? = nil
    @State private var showVideoLengthAlert = false


    var body: some View {
        VStack(spacing: 0) {
            messageScrollView

            messageInputBar
                .frame(minHeight: 50)
                .padding(.horizontal, 16)
        }
        .background(Color(red: 17/255, green: 24/255, blue: 39/255))
        .alert("Video Too Long", isPresented: $showVideoLengthAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Videos longer than 60 seconds cannot be uploaded.")
        }
        .padding(0)
    }

    private var messageScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    messageList
                }
                .onChange(of: chatHelper.realTimeMessages.count) { newCount in
                    if newCount > previousMessageCount && previousMessageCount != 0 {
                        scrollToBottom(proxy, animate: true)
                    }
                    previousMessageCount = newCount
                }
            }
            .onAppear {
                previousMessageCount = chatHelper.realTimeMessages.count
                scrollToBottom(proxy, animate: false)
            }
        }
    }

    private var messageList: some View {
        ForEach(chatHelper.realTimeMessages, id: \.id) { msg in
            let isCurrentUser = viewModel.currentUser?.username == msg.user.username
            ContentMessageView(contentMessage: msg.content, isCurrentUser: isCurrentUser, createdAt: msg.createdAt,
               onDelete: {
                   chatHelper.deleteMessage(id: msg.id)
               })
                .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
                .padding(.horizontal)
        }
    }

    private var messageInputBar: some View {
        VStack(alignment: .leading, spacing: 0) {
            mediaPreview

            HStack(alignment: .bottom, spacing: 0) {
                // Photo/Video Button
                if selectedImage == nil && selectedVideoURL == nil {
                    PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                        Image(systemName: "photo.artframe")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .padding(3)
                            .foregroundColor(.blue)
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            await handleMediaSelection(newItem)
                        }
                    }
                    .padding(.trailing, 4)
                }

                TextField("Message", text: $typingMessage, prompt: Text("Message").foregroundColor(.gray), axis: .vertical)
                    .lineLimit(1...6)
                    .textFieldStyle(.plain)
                    .frame(minHeight: 40)
                    .foregroundColor(.white)
                    .font(.system(size: 22))
                    .padding(.leading, 4)
                    .overlay(Rectangle().frame(height: 2).foregroundColor(Color(red: 30/255, green: 58/255, blue: 138/255)), alignment: .bottom)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.gray)
                        .padding(10)
                }
                .disabled(typingMessage.isEmpty && selectedImage == nil && selectedVideoURL == nil)
            }
        }
    }

    private var mediaPreview: some View {
        Group {
            if selectedImage != nil || selectedVideoURL != nil {
                HStack {
                    ZStack(alignment: .topTrailing) {
                        
                        // --- Image Case ---
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                                .clipped()
                        }
                        
                        // --- Video Case ---
                        else if let videoURL = selectedVideoURL {
                            VideoPreview(url: videoURL)
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                                .clipped()
                                // 3. Make the thumbnail tappable
                                .onTapGesture {
                                    print("[DEBUG] Opening video player for \(videoURL)")
                                    playableVideo = PlayableVideo(url: videoURL)
                                }
                        }

                        // --- Remove Button (The "X") ---
                        Button(action: {
                            print("[DEBUG] Clearing media selection")
                            selectedImage = nil
                            selectedVideoURL = nil
                            selectedItem = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white, .gray)
                                .background(Circle().fill(Color.black))
                                .font(.system(size: 22))
                        }
                        .offset(x: 8, y: -8)
                    }
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.bottom, 8)
                // 4. Attach the player to the preview context
                .fullScreenCover(item: $playableVideo) { video in
                    MediaPlayerView(url: video.url)
                }
            }
        }
    }
    
    struct MediaPlayerView: View {
        let url: URL
        @Environment(\.dismiss) private var dismiss
        
        @State private var player: AVPlayer
        
        init(url: URL) {
            self.url = url
            _player = State(initialValue: AVPlayer(url: url))
        }
        
        var body: some View {
            ZStack(alignment: .topLeading) {
                Color.black.ignoresSafeArea()
                
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                .padding(.top, 50)
                .padding(.leading, 20)
            }
        }
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy, animate: Bool = true) {
        if let lastMessage = chatHelper.realTimeMessages.last {
            if animate {
                withAnimation {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    private func sendMessage() {
        chatHelper.sendMessage(typingMessage)
        typingMessage = ""
        // Also clear media on send
        selectedImage = nil
        selectedVideoURL = nil
        selectedItem = nil
    }
    
    private func handleMediaSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        print("[DEBUG] Selection started. Supported types: \(item.supportedContentTypes)")
        
        // 1. Check for Video
        if item.supportedContentTypes.contains(.movie) || item.supportedContentTypes.contains(.video) || item.supportedContentTypes.contains(.quickTimeMovie) {
            print("[DEBUG] Item identified as video/movie. Attempting to load Transferable...")
            
            do {
                if let movie = try await item.loadTransferable(type: VideoPickerTransferable.self) {
                    print("[DEBUG] Video loaded successfully at: \(movie.url)")
                    await checkAndTrimVideo(url: movie.url)
                } else {
                    print("[DEBUG] loadTransferable returned nil for video")
                }
            } catch {
                print("[DEBUG] Failed to load video transferable: \(error.localizedDescription)")
            }
            
        // 2. Check for Image
        } else if let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) {
            print("[DEBUG] Item identified as image.")
            await MainActor.run {
                self.selectedImage = uiImage
                self.selectedVideoURL = nil
            }
        } else {
            print("[DEBUG] Could not match content type to Video or Image.")
        }
    }

    private func checkAndTrimVideo(url: URL) async {
        print("[DEBUG] Checking video duration for: \(url.lastPathComponent)")
        let asset = AVAsset(url: url)
        
        do {
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            print("[DEBUG] Video duration: \(seconds) seconds")
            
            if seconds > 60 {
                await MainActor.run {
                    showVideoLengthAlert = true
                    
                    // FULL RESET
                    selectedVideoURL = nil
                    selectedImage = nil
                    selectedItem = nil
                }
                return
            }
            
            await MainActor.run {
                self.selectedVideoURL = url
                self.selectedImage = nil
            }
        } catch {
            print("[DEBUG] Failed to load video duration: \(error)")
        }
    }

    // MARK: - Improved Video Preview
    struct VideoPreview: View {
        let url: URL
        @State private var thumbnail: UIImage? = nil
        
        var body: some View {
            ZStack {
                // Background: Thumbnail or Black Placeholder
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.black
                    ProgressView() // Show loading spinner while generating thumbnail
                }
                
                // Overlay: Play Icon (Standard UI indicator for video)
                Color.black.opacity(0.3) // Slight dimming for contrast
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .task {
                await generateThumbnail()
            }
        }
        
        private func generateThumbnail() async {
            // Re-generate only if URL changes or thumbnail is missing
            print("[DEBUG] Generating thumbnail for \(url)")
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true // Respects portrait/landscape
            
            do {
                // Extract frame at 0 seconds
                let time = CMTime(seconds: 0, preferredTimescale: 60)
                let (cgImage, _) = try await generator.image(at: time)
                await MainActor.run {
                    self.thumbnail = UIImage(cgImage: cgImage)
                }
            } catch {
                print("[DEBUG] Thumbnail generation failed: \(error)")
            }
        }
    }

    // MARK: - Enhanced Video Transferable
    struct VideoPickerTransferable: Transferable {
        let url: URL
        
        static var transferRepresentation: some TransferRepresentation {
            FileRepresentation(contentType: .movie) { movie in
                SentTransferredFile(movie.url)
            } importing: { received in
                // Create a unique filename to prevent overwrites/conflicts in temp
                let originalName = received.file.lastPathComponent
                let uniqueName = "\(UUID().uuidString)_\(originalName)"
                let copy = FileManager.default.temporaryDirectory.appendingPathComponent(uniqueName)
                
                print("[DEBUG] Transferable: Importing file from \(received.file)")
                print("[DEBUG] Transferable: Destination \(copy)")
                
                // Clean up previous file if it exists (unlikely with UUID, but good practice)
                if FileManager.default.fileExists(atPath: copy.path) {
                    try? FileManager.default.removeItem(at: copy)
                }
                
                // Copy the file from the picker's secure location to our app's temp folder
                try FileManager.default.copyItem(at: received.file, to: copy)
                print("[DEBUG] Transferable: Copy success")
                
                return .init(url: copy)
            }
        }
    }
}

struct UserChatView_Previews: PreviewProvider {
    static var previews: some View {
        UserChatView()
            .environmentObject(ChatHelper())
            .environmentObject(mockAuthViewModel)
            .preferredColorScheme(.dark)
    }
    
    // Move the logic here
    static var mockAuthViewModel: AuthViewModel {
        let viewModel = AuthViewModel()
        viewModel.currentUser = User(
            username: "Me",
            followers: 0,
            followings: 0,
            thoughts: 0,
            chatRequest: false,
            newChat: false,
            bio: nil,
            registeredAt: Date(),
            darkMode: true,
            following: [],
            profileUrl: nil,
            profileMiniUrl: nil,
            deleted: false
        )
        return viewModel
    }
}
