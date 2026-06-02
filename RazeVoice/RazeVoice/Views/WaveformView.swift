import SwiftUI

struct WaveformView: View {
    var power: Float
    var barCount: Int = 20

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                let norm = CGFloat(index) / CGFloat(barCount - 1)
                let dist = abs(norm - 0.5) * 2
                let intensity = max(0.1, (1 - dist) * CGFloat(power) * 1.5)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red)
                    .frame(width: 4, height: 10 + intensity * 60)
                    .animation(.easeInOut(duration: 0.08), value: power)
            }
        }
    }
}
