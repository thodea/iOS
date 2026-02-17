//
//  ContentMessageView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/25/25.
//


import SwiftUI
import AVKit // <--- ADD THIS


struct PlayerViewController: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.entersFullScreenWhenPlaybackBegins = false
        controller.exitsFullScreenWhenPlaybackEnds = true
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

struct ContentMessageView: View {
    var contentMessage: String
    var isCurrentUser: Bool
    var createdAt: Date?
    var onDelete: () -> Void // Add this callback
    
    // --- NEW: Optional Media Properties ---
    var attachedImage: UIImage? = nil
    var attachedVideoURL: URL? = nil
    // --------------------------------------

    @State private var isPreviewOpen: Bool = false // State for the preview
    
    @State private var isLiked: Bool = false
    @State private var heartScale: CGFloat = 1.0
    @State private var player: AVPlayer? = nil

    // Computed property to format the date
    func timeAgo(from createdAt: Date, now: Date) -> String {
        let timeElapsed = Int(now.timeIntervalSince(createdAt))

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



    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading) {
            HStack(alignment: .bottom) { // Align items to bottom so hearts stay near text
                
                // --- CURRENT USER HEART (Left Side) ---
                if isCurrentUser {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .opacity(0) // Hidden placeholder for alignment if needed, or keeping your existing logic
                }
                
                // --- MESSAGE CONTENT STACK (Media + Text) ---
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                    
                    // 1. VIDEO ATTACHMENT
                    if let videoURL = attachedVideoURL {
                        MessageVideoView(url: videoURL)
                            .padding(.bottom, 2)
                    }
                    // 2. IMAGE ATTACHMENT
                    else if let image = attachedImage {
                        Image(uiImage: image)
                            .resizable()
                            // CSS: object-cover
                            .aspectRatio(contentMode: .fill)
                            // CSS: min-w-[125px] min-h-[125px] max-h-[300px]
                            .frame(minWidth: 125, minHeight: 125)
                            .frame(maxHeight: 300)
                            // CSS: rounded-md
                            .cornerRadius(10)
                            .clipped() // Essential for object-cover behavior
                            .padding(.bottom, 2)
                            .onTapGesture {
                                isPreviewOpen = true
                            }
                    }
                    
                    // 3. TEXT BUBBLE
                    if !contentMessage.isEmpty {
                        Text(contentMessage)
                            .padding(12)
                            .font(.system(size: 18))
                            .foregroundColor(Color.white)
                            .background(isCurrentUser ? Color(red: 23/255, green: 37/255, blue: 84/255) : Color(red: 30/255, green: 41/255, blue: 59/255))
                            .cornerRadius(10)
                    }
                }
                
                // --- OTHER USER HEART (Right Side - Interactable) ---
                if !isCurrentUser {
                    Button(action: {
                        isLiked.toggle()
                        if isLiked {
                            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                                heartScale = 1.2
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    heartScale = 1.0
                                }
                            }
                        }
                    }) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(isLiked ? .red : Color(red: 156/255, green: 163/255, blue: 175/255))
                            .scaleEffect(heartScale)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(isCurrentUser ? .leading : .trailing, 30)

            // --- TIMESTAMP & MENU ROW ---
            HStack {
                if let createdAt = createdAt {
                    TimelineView(.periodic(from: Date(), by: 1)) { context in
                        Text(timeAgo(from: createdAt, now: context.date))
                            .font(.system(size: 16))
                            .foregroundColor(.gray.opacity(0.93))
                            .italic()
                    }
                }
                
                if isCurrentUser {
                    Menu {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.gray.opacity(0.93))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 10)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $isPreviewOpen) {
            if let image = attachedImage {
                ZStack {
                    Color.black.opacity(0.95)
                        .ignoresSafeArea()
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                isPreviewOpen = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.largeTitle)
                                    .foregroundColor(.white) // Changed to white for better contrast on black
                                    .padding()
                            }
                        }
                        Spacer()
                    }
                }
                .onTapGesture {
                    isPreviewOpen = false
                }
            }
        }
    }
    // --- THE FULL SCREEN COVER ---
}

// MARK: - Update Preview to Test
struct ContentMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 17/255, green: 24/255, blue: 39/255).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 1. Text Only
                ContentMessageView(
                    contentMessage: "Text only message",
                    isCurrentUser: true,
                    createdAt: Date(),
                    onDelete: {}
                )
                
                // 2. Text + Image (Other User)
                ContentMessageView(
                    contentMessage: "Look at this photo!",
                    isCurrentUser: false,
                    createdAt: Date(),
                    onDelete: {},
                    attachedImage: UIImage(systemName: "photo.fill")?.withTintColor(.purple, renderingMode: .alwaysOriginal)
                )
            }
            .padding()
        }
    }
}

struct MessageVideoView: View {
    let url: URL
    
    @State private var player: AVPlayer
    @State private var isPlaying = false
    
    init(url: URL) {
        self.url = url
        _player = State(initialValue: AVPlayer(url: url))
    }
    
    var body: some View {
        ZStack {
            
            PlayerViewController(player: player)
                .frame(height: 400)
                .frame(maxWidth: 300)
                .cornerRadius(10)
                .onTapGesture {
                    // Pause only if currently playing
                    if isPlaying {
                        pause()
                    }
                }
            
            // Overlay controls when paused
            if !isPlaying {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.white.opacity(0.7))
                    .onTapGesture {
                        play()
                    }
            }

        }
        .onAppear {
            player.pause()
            isPlaying = false
        }
    }
    
    private func play() {
        player.play()
        isPlaying = true
    }
    
    private func pause() {
        player.pause()
        isPlaying = false
    }
    
    private func skip(seconds: Double) {
        guard let currentItem = player.currentItem else { return }
        
        let currentTime = player.currentTime()
        let newTime = CMTimeGetSeconds(currentTime) + seconds
        let duration = CMTimeGetSeconds(currentItem.duration)
        
        let clampedTime = max(0, min(newTime, duration))
        let time = CMTime(seconds: clampedTime, preferredTimescale: 600)
        
        player.seek(to: time)
    }
}
