import AVFoundation
import Combine

class AudioPlayer: ObservableObject {
    @Published var isPlaying = false

    private var player: AVAudioPlayer?

    func play(data: Data) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetoothHFP])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(data: data)
            player?.prepareToPlay()
            player?.delegate = PlayerDelegate.shared
            PlayerDelegate.shared.onFinish = { [weak self] in
                DispatchQueue.main.async {
                    self?.isPlaying = false
                    try? AVAudioSession.sharedInstance().setActive(false)
                }
            }
            isPlaying = true
            player?.play()
        } catch {
            isPlaying = false
            print("AudioPlayer error: \(error)")
        }
    }

    func stop() {
        player?.stop()
        isPlaying = false
    }
}

class PlayerDelegate: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    static let shared = PlayerDelegate()
    var onFinish: (@Sendable () -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}
