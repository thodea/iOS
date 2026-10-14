import SwiftUI
import AVFoundation
import Combine

final class PlaybackProgress: ObservableObject {
    @Published var current: Double = 0
    @Published var duration: Double = 0
    var isScrubbing = false
    private let player: AVPlayer
    private var token: Any?

    init(player: AVPlayer) {
        self.player = player
        token = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] t in
            guard let self, !self.isScrubbing else { return }
            self.current = t.seconds
            if let d = self.player.currentItem?.duration.seconds, d.isFinite { self.duration = d }
        }
    }
    func seek(to s: Double) { player.seek(to: CMTime(seconds: s, preferredTimescale: 600)) }
    deinit { if let token { player.removeTimeObserver(token) } }
}

struct FullScreenVideoView: View {
    let player: AVPlayer
    @ObservedObject private var manager = FeedVideoManager.shared
    @StateObject private var progress: PlaybackProgress
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: FeedVideoModel
    
    init(player: AVPlayer, model: FeedVideoModel) {
        self.player = player
        self.model = model
        _progress = StateObject(wrappedValue: PlaybackProgress(player: player))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .onTapGesture { model.togglePause() }
            PlayerLayerRepresentable(player: player, gravity: .resizeAspect)   // whole video, nothing cropped
                .ignoresSafeArea().allowsHitTesting(false)
            if model.userPaused {
                Button { model.togglePause() } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 72)).foregroundColor(.white.opacity(0.9))
                }
            }
            VStack {
                HStack {
                    Button { dismiss() } label: { icon("arrow.down.right.and.arrow.up.left") }   // minimize
                    Spacer()
                    Button { manager.toggleSound() } label: {
                        icon(manager.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    }
                }
                Spacer()
                VStack(spacing: 4) {
                    Slider(value: $progress.current,
                           in: 0...max(progress.duration, 0.1),
                           onEditingChanged: { progress.isScrubbing = $0 })
                        .tint(.white)
                    HStack {
                        Button { model.togglePause() } label: {
                            Image(systemName: model.userPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 18)).frame(width: 32, height: 32)
                        }
                        Text(format(progress.current)); Spacer(); Text(format(progress.duration))
                    }
                    .font(.caption.monospacedDigit()).foregroundColor(.white)
                }
            }
            .padding()
        }
        .onAppear { player.isMuted = !manager.soundEnabled }
        .onChange(of: manager.soundEnabled) { _, on in player.isMuted = !on }
        .onChange(of: progress.current) { _, v in if progress.isScrubbing { progress.seek(to: v) } }
        .gesture(DragGesture().onEnded { if $0.translation.height > 120 { dismiss() } })   // swipe down = minimize
    }

    private func icon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(Color.white.opacity(0.18), in: Circle())
    }

    private func format(_ t: Double) -> String {
        guard t.isFinite, t >= 0 else { return "0:00" }
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}
