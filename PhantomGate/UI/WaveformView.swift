import SwiftUI
import AVFoundation

struct WaveformView: View {
    let isPlaying: Bool
    var audioLevelProvider: AudioLevelProvider?

    @State private var audioLevels: [CGFloat] = Array(repeating: -160, count: 8)
    private let numberOfBars = 8
    private let minHeight: CGFloat = 4
    private let maxHeight: CGFloat = 30

    // Timer for updating audio levels
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<numberOfBars, id: \.self) { index in
                WaveformBar(
                    height: getBarHeight(for: index),
                    delay: Double(index) * 0.1
                )
            }
        }
        .frame(height: maxHeight)
        .onReceive(timer) { _ in
            updateAudioLevels()
        }
    }

    private func getBarHeight(for index: Int) -> CGFloat {
        guard isPlaying else { return minHeight }

        // If we have an audio level provider, use real levels
        if audioLevelProvider != nil {
            guard index < audioLevels.count else { return minHeight }

            // Convert audio level (-160 to 0 dB) to height
            let normalizedLevel = (audioLevels[index] + 160) / 160 // Normalize to 0...1
            let height = minHeight + (normalizedLevel * (maxHeight - minHeight))

            return max(minHeight, min(height, maxHeight))
        } else {
            // Fallback to random heights for visual effect when no provider
            return isPlaying ? .random(in: minHeight...maxHeight) : minHeight
        }
    }

    private func updateAudioLevels() {
        guard isPlaying, let provider = audioLevelProvider else {
            audioLevels = Array(repeating: -160, count: 8)
            return
        }

        // Get audio levels from the provider
        audioLevels = provider.getAudioLevels()
    }
}

struct WaveformBar: View {
    let height: CGFloat
    let delay: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color(.phantomGreen))
            .frame(width: 3, height: height)
            .animation(
                .easeInOut(duration: 0.6)
                .repeatForever()
                .delay(delay),
                value: height
            )
    }
}
