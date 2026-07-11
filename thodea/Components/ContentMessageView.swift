//
//  ContentMessageView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/25/25.
//


import SwiftUI
import AVKit // <--- ADD THIS
import Kingfisher
import Combine


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
    @Binding var isLiked: Bool
    var onDelete: () -> Void // Add this callback
    
    // --- NEW: Optional Media Properties ---
    var attachedImage: String? = nil
    var attachedVideoURL: URL? = nil
    var posterLink: URL? = nil
    // --------------------------------------

    @State private var isPreviewOpen: Bool = false // State for the preview
    
    
    //@State private var isLiked: Bool = false
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

    private func linkifiedText(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        
        // Use NSDataDetector (Apple's native URL detector)
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        
        detector?.enumerateMatches(in: text, options: [], range: nsRange) { match, _, _ in
            guard let match = match,
                  let _ = Range(match.range, in: text),
                  let url = match.url else { return }
            
            if let attributedRange = Range(match.range, in: attributed) {
                attributed[attributedRange].link = url
                attributed[attributedRange].foregroundColor = .blue
                attributed[attributedRange].underlineStyle = .single
            }
        }
        
        return attributed
    }


    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading) {
            HStack(alignment: .center) { // Align items to bottom so hearts stay near text
                
                // --- CURRENT USER HEART (Left Side) ---
                if isCurrentUser {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .opacity(0) // Hidden placeholder for alignment if needed, or keeping your existing logic
                }
                
                // --- MESSAGE CONTENT STACK (Media + Text) ---
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                    
                    // 1. VIDEO ATTACHM ENT
                    // 1. ADD THE FIELD INSIDE OPTIONAL MEDIA PROPERTIES SECTION (near top):
                    //let posterUrl: String? = nil

                    // 2. UPDATE THE VIDEO ATTACHMENT CALL INSIDE THE BODY STACK:
                    if let videoURL = attachedVideoURL {
                        MessageVideoView(url: videoURL, posterUrl: posterLink) // <-- Pass it here
                            .padding(.bottom, 2)
                    }
                    
                    // 2. IMAGE ATTACHMENT
                    else if let urlStr = attachedImage, let url = URL(string: urlStr) {
                        KFImage(url)
                            .placeholder {
                                ShimmerView()
                                    .frame(minWidth: 125, minHeight: 125)
                                    .frame(maxHeight: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 125, minHeight: 125)
                            .frame(maxHeight: 300)
                            .clipped() // Keeps it visually contained
                            .cornerRadius(10)
                            // 👇 THE FIX: Define the hit-test shape to match the frame
                            .contentShape(RoundedRectangle(cornerRadius: 10))
                            .onTapGesture {
                                isPreviewOpen = true
                            }
                            .padding(.bottom, 2)
                    }
                    
                    // 3. TEXT BUBBLE
                    if !contentMessage.isEmpty {
                        Text(linkifiedText(contentMessage))
                            .padding(12)
                            .font(.system(size: 18))
                            .foregroundColor(Color.white)
                            .background(isCurrentUser ? Color(red: 23/255, green: 37/255, blue: 84/255) : Color(red: 30/255, green: 41/255, blue: 59/255))
                            .cornerRadius(10)
                            .textSelection(.enabled)
                    }
                }
                
                // --- OTHER USER HEART (Right Side - Interactable) ---
                if !isCurrentUser {
                    Button(action: {
                        isLiked.toggle()
                    }) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(isLiked ? .red : Color(red: 156/255, green: 163/255, blue: 175/255))
                            .scaleEffect(heartScale)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onChange(of: isLiked) { oldValue, newValue in
                        if newValue { // Only animate when switching from unliked to liked
                            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                                heartScale = 1.2
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                    heartScale = 1.0
                                }
                            }
                        }
                    }
                }
            }
            .padding(isCurrentUser ? .leading : .trailing, 30)

            // --- TIMESTAMP & MENU ROW ---
            HStack(spacing: 0) {
                if let createdAt = createdAt {
                    TimelineView(.periodic(from: Date(), by: 1)) { context in
                        Text(timeAgo(from: createdAt, now: context.date))
                            .font(.system(size: 16))
                            .foregroundColor(.gray.opacity(0.93))
                            .italic()//.border(.red, width: 2)
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
                            .padding(.leading, 6)
                            .padding(.trailing, 2)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                            //.border(.green, width: 2)
                    }//.border(.red, width: 2)
                }
            }//.border(.red, width: 2)
        }
        .preferredColorScheme(.dark)
        .environment(\.openURL, OpenURLAction { url in
            UIApplication.shared.open(url)
            return .handled
        })
        //.border(.yellow, width: 2)
        .fullScreenCover(isPresented: $isPreviewOpen) {
            if let urlStr = attachedImage, let url = URL(string: urlStr) {
                ZStack {
                    Color.black.opacity(0.95)
                        .ignoresSafeArea()
                    
                    KFImage(url)
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

struct MessageVideoView: View {
    let url: URL
    let posterUrl: URL?
    
    @State private var player = AVPlayer()
    @State private var isPlaying = false
    @State private var isAssetPrimed = false
    @State private var showBufferingSpinner = false
    
    // --- NEW: Processing States ---
    enum MediaStatus {
        case ready
        case processing
    }
    @State private var mediaStatus: MediaStatus = .ready
    @State private var playerStatusCancellable: AnyCancellable?
    // ------------------------------

    var body: some View {
        ZStack {
            if isPlaying {
                // --- STATE 1: ACTIVE VIDEO CONTAINER LAYER ---
                PlayerViewController(player: player)
                    .frame(width: 300, height: 350)
                    .cornerRadius(10)
                    .transition(.opacity)
                
                // Overlay clean loading indicator if CDN network experiences buffer hiccups
                if showBufferingSpinner {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            } else {
                // --- STATE 2: PRISTINE CACHED IDLE POSTER LAYER ---
                ZStack {
                    if let posterUrl = posterUrl {
                        KFImage(posterUrl)
                            .requestModifier(AnyModifier { request in
                                var securedRequest = request
                                securedRequest.setValue("https://www.thodea.com", forHTTPHeaderField: "Referer")
                                securedRequest.setValue("MobileAppClient/1.0", forHTTPHeaderField: "User-Agent")
                                return securedRequest
                            })
                            .retry(maxCount: 20, interval: .seconds(3))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 350)
                            .clipped()
                            .contentShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                Color.clear
                                    .background(.ultraThinMaterial)
                                    .opacity(0.2)
                            )
                            .overlay(mediaStatus == .processing ? Color(red: 23/255, green: 37/255, blue: 84/255).opacity(0.2) : Color.black.opacity(0.15))
                            .background(mediaStatus == .processing ? Color(red: 23/255, green: 37/255, blue: 84/255).opacity(0.2) : Color(red: 23/255, green: 23/255, blue: 23/255))
                            .cornerRadius(10)
                            //.id(mediaStatus)
                    } else {
                        Color(mediaStatus == .processing ? Color(red: 23/255, green: 37/255, blue: 84/255).opacity(0.2) : Color(red: 23/255, green: 23/255, blue: 23/255))
                            .frame(width: 300, height: 350)
                            .cornerRadius(10)
                    }
                    
                    // --- NEW: UI Switch based on Processing State ---
                    if mediaStatus == .processing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("Processing Media")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(red: 38/255, green: 38/255, blue: 38/255)) // <-- Solid Dark Gray Badge Background
                        .cornerRadius(12)
                    } else {
                        // Centered Floating Play Action Button Trigger
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                            .onTapGesture { play() }
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            primeVideoAsset()
        }
        .onDisappear {
            pause()
            playerStatusCancellable?.cancel() // Cleanup observer
        }
    }
    
    private func primeVideoAsset() {
        guard !isAssetPrimed else { return }
        
        let headers: [String: String] = [
            "Referer": "https://www.thodea.com",
            "User-Agent": "MobileAppClient/1.0"
        ]
        let assetOptions = ["AVURLAssetHTTPHeaderFieldsKey": headers]
        let asset = AVURLAsset(url: url, options: assetOptions)
        let playerItem = AVPlayerItem(asset: asset)
        
        // 1. Observe Player Item Status to catch CDN 404s (Processing state)
        playerStatusCancellable = playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { status in
                if status == .failed {
                    // Video likely isn't ready on Bunny CDN yet
                    self.mediaStatus = .processing
                    self.isAssetPrimed = false // Allow re-priming once ready
                    self.pollForReadiness()
                }
            }
        
        player.replaceCurrentItem(with: playerItem)
        isAssetPrimed = true
        
        // Listen to native pipeline buffer underflow state modifications
        NotificationCenter.default.addObserver(forName: .AVPlayerItemPlaybackStalled, object: playerItem, queue: .main) { _ in
            showBufferingSpinner = true
        }
    }
    
    // --- NEW: Polling Logic ---
    private func pollForReadiness() {
        // Create an HTTP HEAD request (retrieves ONLY headers, no heavy video data downloaded)
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.setValue("https://www.thodea.com", forHTTPHeaderField: "Referer")
        request.setValue("MobileAppClient/1.0", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.scheduleNextPoll()
                    return
                }
                
                // If CDN returns 200 OK or 206 Partial Content, the transcode is done
                if (200...299).contains(httpResponse.statusCode) {
                    self.mediaStatus = .ready
                    self.primeVideoAsset() // Retry loading into AVPlayer
                } else {
                    // Still processing (likely 403 or 404), check again in 5 seconds
                    self.scheduleNextPoll()
                }
            }
        }.resume()
    }
    
    private func scheduleNextPoll() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.pollForReadiness()
        }
    }
    // ----------------------------
    
    private func play() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isPlaying = true
        }
        player.play()
    }
    
    private func pause() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isPlaying = false
        }
        player.pause()
    }
}

// MARK: - Update Preview to Test
/*struct ContentMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 17/255, green: 24/255, blue: 39/255).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 1. Text Only
                ContentMessageView(
                    contentMessage: "Text only message test.com s",
                    isCurrentUser: true,
                    createdAt: Date(),
                    isLiked: .constant(false),
                    onDelete: {}
                )
                
                // 2. Text + Image (Other User)
                ContentMessageView(
                    contentMessage: "Look at this photo!",
                    isCurrentUser: false,
                    createdAt: Date(),
                    isLiked: .constant(false),
                    onDelete: {},
                    attachedImage: UIImage(systemName: "photo.fill")?.withTintColor(.purple, renderingMode: .alwaysOriginal)
                )
            }
            .padding()
        }
    }
}*/

/*
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
*/
