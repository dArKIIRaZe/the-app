import AVFoundation
import Combine

class AudioRecorder: ObservableObject, @unchecked Sendable {
    @Published var isRecording = false
    @Published var power: Float = 0.0

    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private let sampleRate: Double = 16000
    private let recordingURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent("raze_recording.wav")

    var onData: ((Data) -> Void)?
    var onPermissionDenied: (() -> Void)?

    func requestPermission(thenStart: Bool = false) {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            if thenStart { beginRecording() }
        case .denied:
            DispatchQueue.main.async { self.onPermissionDenied?() }
        case .undetermined:
            session.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if granted && thenStart {
                        self.beginRecording()
                    } else if !granted {
                        self.onPermissionDenied?()
                    }
                }
            }
        @unknown default:
            break
        }
    }

    func start() {
        requestPermission(thenStart: true)
    }

    private func beginRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
        } catch {
            print("RazeVoice: AudioSession error – \(error)")
            return
        }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        do {
            recorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
            isRecording = true

            meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.recorder?.updateMeters()
                let db = self.recorder?.averagePower(forChannel: 0) ?? -160
                let linear = pow(10, db / 20)
                self.power = min(1.0, max(0.0, linear * 10))
            }
        } catch {
            print("RazeVoice: Recorder init error – \(error)")
            isRecording = false
        }
    }

    func stop() {
        meterTimer?.invalidate()
        meterTimer = nil
        recorder?.stop()
        isRecording = false
        power = 0.0

        do {
            let data = try Data(contentsOf: recordingURL)
            onData?(data)
            try? FileManager.default.removeItem(at: recordingURL)
        } catch {
            print("RazeVoice: Read recording error – \(error)")
        }

        try? AVAudioSession.sharedInstance().setActive(false)
        recorder = nil
    }
}
