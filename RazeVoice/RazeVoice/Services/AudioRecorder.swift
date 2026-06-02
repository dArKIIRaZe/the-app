import AVFoundation
import Combine

class AudioRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var power: Float = 0.0

    private var engine = AVAudioEngine()
    private var mixer: AVAudioMixerNode { engine.mainMixerNode }
    private var buffer = Data()
    private let sampleRate: Double = 16000
    private let format = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                        sampleRate: 16000,
                                        channels: 1,
                                        interleaved: true)!

    var onData: ((Data) -> Void)?

    func start() {
        buffer.removeAll()
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try? session.setActive(true)

        let input = engine.inputNode
        let bus = 0
        input.installTap(onBus: bus, bufferSize: 1024, format: format) { [weak self] avBuffer, _ in
            guard let self = self else { return }
            let channelData = avBuffer.int16ChannelData![0]
            let length = Int(avBuffer.frameLength)
            let data = Data(bytes: channelData, count: length * MemoryLayout<Int16>.size)
            self.buffer.append(data)
            // simple power meter
            var sum: Float = 0
            for i in 0..<length {
                let sample = Float(channelData[i])
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(length))
            DispatchQueue.main.async {
                self.power = min(1.0, rms / 3000.0)
            }
        }

        engine.prepare()
        try? engine.start()
        isRecording = true
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        isRecording = false
        power = 0.0
        onData?(buffer)
        buffer.removeAll()
    }
}
