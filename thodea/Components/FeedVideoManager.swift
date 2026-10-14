import Combine
import AVFoundation
import UIKit

final class FeedVideoManager: ObservableObject {
    static let shared = FeedVideoManager()   // singleton: no EnvironmentObject injection needed in every parent

    @Published private(set) var soundEnabled = false { didSet { updateAudioSession() } }
    @Published private(set) var playingIDs: Set<String> = []   // ≥50% visible
    @Published private(set) var audioVideoID: String?          // the one allowed to make noise

    private var visible: [String: CGFloat] = [:]   // id -> distance from screen center
    private var pinnedID: String?                  // video whose speaker the user just tapped
    private var fullScreenID: String?

    private init() { updateAudioSession() }

    func report(id: String, frame: CGRect) {
        let screen = UIScreen.main.bounds        // warning-only on newer SDKs; fine on iPhone
        let shown = frame.intersection(screen)
        let fraction = (shown.isNull || frame.height <= 0) ? 0 : shown.height / frame.height
        visible[id] = fraction >= 0.5 ? abs(frame.midY - screen.midY) : nil
        recompute()
    }

    func remove(id: String) { visible[id] = nil; recompute() }
    func setFullScreen(_ id: String?) { fullScreenID = id; recompute() }

    func toggleSound(for id: String? = nil) {
        soundEnabled.toggle()
        pinnedID = soundEnabled ? id : nil
        recompute()
    }

    private func recompute() {
        if let p = pinnedID, visible[p] == nil { pinnedID = nil }
        let playing: Set<String>
        if let f = fullScreenID { playing = [f] } else { playing = Set(visible.keys) }
        let center = visible.min(by: { $0.value < $1.value })?.key
        let audio = fullScreenID ?? pinnedID ?? center
        if playing != playingIDs { playingIDs = playing }      // @Published fires even on equal values,
        if audio != audioVideoID { audioVideoID = audio }      // so only assign on change
    }

    private func updateAudioSession() {
        // .ambient = muted autoplay won't interrupt the user's Spotify. .playback = audible even on silent switch.
        try? AVAudioSession.sharedInstance().setCategory(soundEnabled ? .playback : .ambient)
    }
}
