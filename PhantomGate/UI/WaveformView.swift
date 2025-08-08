import SwiftUI

struct WaveformView: View {
    let isPlaying: Bool

    private let numberOfBars = 8
    private let minHeight: CGFloat = 4
    private let maxHeight: CGFloat = 30

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<numberOfBars, id: \.self) { index in
                WaveformBar(
                    height: isPlaying ? .random(in: minHeight...maxHeight) : minHeight,
                    delay: Double(index) * 0.1
                )
            }
        }
        .frame(height: maxHeight)
    }
}

struct WaveformBar: View {
    let height: CGFloat
    let delay: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color(hex: "00ff88"))
            .frame(width: 3, height: height)
            .animation(
                .easeInOut(duration: 0.6)
                .repeatForever()
                .delay(delay),
                value: height
            )
    }
}
