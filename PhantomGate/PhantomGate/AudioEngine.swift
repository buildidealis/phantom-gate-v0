import AVFoundation

enum NoiseType: String, CaseIterable {
    case green = "Green noise"
    case pink = "Pink noise"
    case pinkBabble = "Pink babble noise"
}

actor AudioEngine: ObservableObject {
    nonisolated let engine = AVAudioEngine()
    nonisolated let mainMixer: AVAudioMixerNode
    private var noiseGenerator: AVAudioSourceNode?
    @MainActor @Published private(set) var isPlaying = false
    private(set) var currentNoiseType: NoiseType = .green
    
    init() {
        self.mainMixer = engine.mainMixerNode
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func selectNoiseType(_ type: NoiseType) {
        currentNoiseType = type
        if isPlaying {
            Task {
                await stopPlayback()
                await startPlayback()
            }
        }
    }
    
    func startPlayback() async {
        guard !isPlaying else { return }
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        
        noiseGenerator = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let sample = self.generateNoiseSample()
                ablPointer[0].mData?.assumingMemoryBound(to: Float.self)[frame] = sample
            }
            return noErr
        }
        
        engine.attach(noiseGenerator!)
        engine.connect(noiseGenerator!, to: mainMixer, format: format)
        
        do {
            try engine.start()
            await MainActor.run {
                self.isPlaying = true
            }
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stopPlayback() async {
        guard isPlaying else { return }
        
        engine.stop()
        if let generator = noiseGenerator {
            engine.disconnectNodeOutput(generator)
            engine.detach(generator)
            noiseGenerator = nil
        }
        
        await MainActor.run {
            self.isPlaying = false
        }
    }
    
    private func generateNoiseSample() -> Float {
        switch currentNoiseType {
        case .green:
            return generateGreenNoise()
        case .pink:
            return generatePinkNoise()
        case .pinkBabble:
            return generatePinkBabbleNoise()
        }
    }
    
    private func generateGreenNoise() -> Float {
        // Green noise emphasizes middle frequencies
        // This is a simplified implementation
        let random = Float.random(in: -1...1)
        let middleFreqEmphasis = random * 0.8 // Emphasize mid-range
        return middleFreqEmphasis
    }
    
    private func generatePinkNoise() -> Float {
        // Pink noise has equal energy per octave
        // This is a simplified implementation
        let random = Float.random(in: -1...1)
        let pinkScale = random * 0.6 // Reduce high frequencies
        return pinkScale
    }
    
    private func generatePinkBabbleNoise() -> Float {
        // Combination of pink noise and babbling frequencies
        let pink = generatePinkNoise()
        let babble = Float.random(in: -0.3...0.3) // Simulate speech frequencies
        return (pink + babble) * 0.7 // Mix and normalize
    }
    
    nonisolated func getCurrentFrequency() -> Float {
        // In a real implementation, this would analyze the actual frequency content
        // For now, return a mock value
        return 2000.0 // 2kHz
    }
} 