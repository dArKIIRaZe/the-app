import SwiftUI

struct ContentView: View {
    @StateObject private var recorder = AudioRecorder()
    @StateObject private var player = AudioPlayer()
    @StateObject private var service = HermesService()
    @State private var isAutoListen = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Text("RAZE")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(recorder.isRecording ? "Listening..." : (player.isPlaying ? "Speaking..." : service.status))
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.gray)
                WaveformView(power: recorder.power)
                    .opacity(recorder.isRecording ? 1 : 0.3)
                Spacer()
                Button(action: toggle) {
                    ZStack {
                        Circle()
                            .fill(recorder.isRecording ? Color.red : Color.gray.opacity(0.2))
                            .frame(width: 120, height: 120)
                        Image(systemName: recorder.isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 44))
                            .foregroundColor(recorder.isRecording ? .white : .red)
                    }
                }
                .disabled(player.isPlaying)
                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            recorder.onData = { audioData in
                service.send(audio: audioData) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let audioResponse):
                            player.play(data: audioResponse)
                        case .failure(let error):
                            service.status = "Error: \(error.localizedDescription)"
                        }
                    }
                }
            }
            recorder.onPermissionDenied = {
                service.status = "Microphone permission denied"
            }
        }
        .onDisappear {
            if recorder.isRecording {
                recorder.stop()
            }
            player.stop()
        }
    }

    private func toggle() {
        if recorder.isRecording {
            recorder.stop()
        } else if !player.isPlaying {
            recorder.start()
        }
    }
}
