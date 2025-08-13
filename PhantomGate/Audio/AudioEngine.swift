import AVFoundation

enum NoiseType: String, CaseIterable {
    case green = "Green noise"
    case pink = "Pink noise"
    case pinkBabble = "Pink babble noise"
}

enum AudioEngineError: Error {
    case formatCreationFailed
    case engineStartFailed(Error)
    case noAudioFormat
}

@MainActor
class AudioEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode
    private var noiseGenerator: AVAudioSourceNode?
    @Published private(set) var isPlaying = false
    @Published private(set) var currentFrequency: Float = 0
    private var currentNoiseType: NoiseType = .green

    private let sampleRate: Double = 44100
    private let nyquistFrequency: Double = 22050 // sampleRate / 2

    init() {
        self.mainMixer = engine.mainMixerNode
        setupEngine()
    }

    private func setupEngine() {
        // Configure the audio engine for macOS
        let outputNode = engine.outputNode
        let format = outputNode.inputFormat(forBus: 0)

        // Set the maximum frames per slice for better real-time performance
        engine.mainMixerNode.outputVolume = 1.0
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            // Calculate approximate frequency from buffer
            guard let self = self else { return }
            let frequency = self.calculateApproximateFrequency(buffer)
            Task { @MainActor in
                self.currentFrequency = frequency
            }
        }
    }

    private func calculateApproximateFrequency(_ buffer: AVAudioPCMBuffer) -> Float {
        // Simple zero-crossing method for frequency approximation
        guard let data = buffer.floatChannelData?[0],
              buffer.frameLength > 0 else { return 0 }

        var crossings = 0
        var prev = data[0]

        for index in 1..<Int(buffer.frameLength) {
            let current = data[index]
            if (prev < 0 && current >= 0) || (prev >= 0 && current < 0) {
                crossings += 1
            }
            prev = current
        }

        let duration = Double(buffer.frameLength) / sampleRate
        return Float(Double(crossings) / (2 * duration))
    }

    func selectNoiseType(_ type: NoiseType) {
        currentNoiseType = type
        if isPlaying {
            Task {
                try? await stopPlayback()
                try? await startPlayback()
            }
        }
    }

    func startPlayback() async throws {
        guard !isPlaying else { return }

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            throw AudioEngineError.formatCreationFailed
        }

        // Create a generator function that doesn't need actor access
        let generator = { [currentNoiseType] (frameCount: Int) -> [Float] in
            var samples = [Float](repeating: 0, count: frameCount)
            for frame in 0..<frameCount {
                switch currentNoiseType {
                case .green:
                    samples[frame] = Float.random(in: -1...1) * 0.8 // Green noise
                case .pink:
                    samples[frame] = Float.random(in: -1...1) * 0.6 // Pink noise
                case .pinkBabble:
                    let pink = Float.random(in: -1...1) * 0.6
                    let babble = Float.random(in: -0.3...0.3)
                    samples[frame] = (pink + babble) * 0.7 // Pink babble
                }
            }
            return samples
        }

        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let samples = generator(Int(frameCount))

            guard let mData = ablPointer[0].mData else { return kAudioUnitErr_InvalidParameter }

            samples.withUnsafeBufferPointer { buffer in
                guard let baseAddress = buffer.baseAddress else { return }
                mData.copyMemory(from: baseAddress,
                               byteCount: Int(frameCount) * MemoryLayout<Float>.stride)
            }
            return noErr
        }

        noiseGenerator = node
        engine.attach(node)
        engine.connect(node, to: mainMixer, format: format)

        do {
            try engine.start()
            isPlaying = true
        } catch {
            throw AudioEngineError.engineStartFailed(error)
        }
    }

    func stopPlayback() async throws {
        guard isPlaying else { return }

        engine.stop()
        if let generator = noiseGenerator {
            engine.disconnectNodeOutput(generator)
            engine.detach(generator)
            noiseGenerator = nil
        }

        isPlaying = false
        currentFrequency = 0
    }
    
    func getAudioLevels() -> [CGFloat] {
            // Base implementation
            if isPlaying {
                // Add your actual audio analysis here
                return (0..<8).map { _ in CGFloat.random(in: -40...0) }
            } else {
                return Array(repeating: -160, count: 8)
            }
        }
}

