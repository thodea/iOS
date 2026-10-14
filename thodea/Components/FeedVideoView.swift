import SwiftUI
import AVFoundation
import Combine
import Kingfisher

final class FeedVideoModel: ObservableObject {
    @Published private(set) var player: AVPlayer?
    @Published private(set) var aspect: CGFloat = 1.0
    @Published private(set) var hasStartedPlaying = false
    @Published private(set) var isBuffering = false
    @Published private(set) var isProcessing = false
    @Published private(set) var userPaused = false
    
    private let url: URL
    private static let headers = ["Referer": "https://www.thodea.com", "User-Agent": "MobileAppClient/1.0"]
    private var asset: AVURLAsset?
    private var bag = Set<AnyCancellable>()
    private var pollTask: Task<Void, Never>?
    private var wantsPlay = false
    private var muted = true

    init(url: URL) { self.url = url }

    private func makeAsset() -> AVURLAsset {
        AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": Self.headers])
    }

    /// Cheap: reads only the video size so the cell has the right height before it plays.
    func prepare() {
        guard asset == nil else { return }
        let a = makeAsset()
        asset = a
        Task { @MainActor [weak self] in
            do {
                guard let track = try await a.loadTracks(withMediaType: .video).first else { return }
                let (size, tf) = try await track.load(.naturalSize, .preferredTransform)
                let s = size.applying(tf)
                guard s.width != 0, s.height != 0 else { return }
                self?.aspect = min(max(abs(s.width / s.height), 0.8), 16.0 / 9.0)  // clamp 4:5 … 16:9
            } catch {
                self?.enterProcessing()
            }
        }
    }

    func setPlaying(_ play: Bool) { wantsPlay = play; applyPlayback() }

    func togglePause() { userPaused.toggle(); applyPlayback() }
    func resumeAfterFullScreen() { userPaused = false; applyPlayback() }
    
    private func applyPlayback() {
        guard wantsPlay, !userPaused else { player?.pause(); return }
        if player == nil { buildPlayer() }
        player?.play()
    }

    func setMuted(_ m: Bool) { muted = m; player?.isMuted = m }

    func teardown() {
        pollTask?.cancel(); bag.removeAll()
        player?.pause(); player = nil; asset = nil
        isProcessing = false; hasStartedPlaying = false; isBuffering = false
        userPaused = false
    }

    private func buildPlayer() {
        guard !isProcessing else { return }
        let item = AVPlayerItem(asset: asset ?? makeAsset())
        let p = AVPlayer(playerItem: item)
        p.isMuted = muted
        p.actionAtItemEnd = .none
        player = p

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)   // loop
            .sink { [weak self, weak p] _ in
                p?.seek(to: .zero)
                if self?.wantsPlay == true && self?.userPaused == false { p?.play() }
            }.store(in: &bag)

        item.publisher(for: \.status).receive(on: DispatchQueue.main)
            .sink { [weak self] in if $0 == .failed { self?.enterProcessing() } }
            .store(in: &bag)

        p.publisher(for: \.timeControlStatus).receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                self.isBuffering = status == .waitingToPlayAtSpecifiedRate
                if status == .playing { self.hasStartedPlaying = true }   // hides the poster
            }.store(in: &bag)
    }

    private func enterProcessing() {
        guard !isProcessing else { return }
        isProcessing = true
        player?.pause(); player = nil; bag.removeAll()
        hasStartedPlaying = false; isBuffering = false
        pollTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard let self, !Task.isCancelled else { return }
                var req = URLRequest(url: self.url)
                req.httpMethod = "HEAD"
                Self.headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
                if let (_, resp) = try? await URLSession.shared.data(for: req),
                   let code = (resp as? HTTPURLResponse)?.statusCode, (200...299).contains(code) {
                    self.isProcessing = false
                    self.asset = nil
                    self.prepare()
                    if self.wantsPlay { self.setPlaying(true) }
                    return
                }
            }
        }
    }
}


final class PlayerLayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

struct PlayerLayerRepresentable: UIViewRepresentable {
    let player: AVPlayer?
    var gravity: AVLayerVideoGravity = .resizeAspectFill

    func makeUIView(context: Context) -> PlayerLayerView { PlayerLayerView() }
    func updateUIView(_ v: PlayerLayerView, context: Context) {
        v.playerLayer.player = player
        v.playerLayer.videoGravity = gravity
    }
}


struct FeedVideoView: View {
    let url: URL
    let posterUrl: URL?

    @State private var id = UUID().uuidString      // unique per cell, safe if a thought shows in two screens
    @StateObject private var model: FeedVideoModel
    @ObservedObject private var manager = FeedVideoManager.shared
    @State private var showFullScreen = false

    init(url: URL, posterUrl: URL?) {
        self.url = url
        self.posterUrl = posterUrl
        _model = StateObject(wrappedValue: FeedVideoModel(url: url))
    }

    private var shouldPlay: Bool { manager.playingIDs.contains(id) }
    private var hasAudio: Bool { manager.soundEnabled && manager.audioVideoID == id }

    var body: some View {
        Color(red: 23/255, green: 23/255, blue: 23/255)
            .frame(maxWidth: .infinity)
            .aspectRatio(model.aspect, contentMode: .fit)          // sizes the cell; overlays don't affect layout
            .background(GeometryReader { geo in
                Color.clear
                    .onAppear { manager.report(id: id, frame: geo.frame(in: .global)) }
                    .onChange(of: geo.frame(in: .global)) { _, f in manager.report(id: id, frame: f) }
            })
            .overlay { mediaLayers }
            .overlay(alignment: .bottomTrailing) { if model.player != nil { speakerButton } }
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture { openFullScreen() }
            .onAppear {
                model.prepare()
                model.setMuted(!hasAudio)
                if shouldPlay { model.setPlaying(true) }
            }
            .onDisappear {
                guard !showFullScreen else { return }               // presenting the cover can trigger this
                manager.remove(id: id)
                model.teardown()
            }
            .onChange(of: shouldPlay) { _, v in model.setPlaying(v) }
            .onChange(of: hasAudio) { _, v in model.setMuted(!v) }
            .fullScreenCover(isPresented: $showFullScreen, onDismiss: {
                manager.setFullScreen(nil)
                model.resumeAfterFullScreen()      // pause only lives inside full screen
            }) {
                if let p = model.player { FullScreenVideoView(player: p, model: model) }
                else { Color.clear.onAppear { showFullScreen = false } }
            }
    }

    private var mediaLayers: some View {
        ZStack {
            if let posterUrl, !model.hasStartedPlaying {
                KFImage(posterUrl)
                    .requestModifier(AnyModifier { r in
                        var r = r
                        r.setValue("https://www.thodea.com", forHTTPHeaderField: "Referer")
                        r.setValue("MobileAppClient/1.0", forHTTPHeaderField: "User-Agent")
                        return r
                    })
                    .retry(maxCount: 20, interval: .seconds(3))
                    .resizable().scaledToFill()
                    .allowsHitTesting(false)
            }
            if let p = model.player {
                PlayerLayerRepresentable(player: p).allowsHitTesting(false)
            }
            if model.isProcessing {
                VStack(spacing: 10) {
                    ProgressView().tint(.white)
                    Text("Processing Media").font(.caption.weight(.semibold))
                }
                .foregroundColor(.white).padding(16)
                .background(Color(white: 0.15), in: RoundedRectangle(cornerRadius: 12))
            } else if model.isBuffering {
                ProgressView().tint(.white)
            }
            /*if model.userPaused {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 54)).foregroundColor(.white.opacity(0.85))
                    .shadow(radius: 4).allowsHitTesting(false)
            }*/
        }
    }

    private var speakerButton: some View {
        Button { manager.toggleSound(for: id) } label: {
            Image(systemName: manager.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(Color.black.opacity(0.6), in: Circle())
        }
        .buttonStyle(.plain)
        .padding(8)
    }

    private func openFullScreen() {
        guard model.player != nil else { return }
        manager.setFullScreen(id)
        showFullScreen = true
    }
}
