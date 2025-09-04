import AVFoundation
import CoreGraphics
import Foundation

class AudioEngine: ObservableObject {
    let engine = AVAudioEngine()
    let mainMixer: AVAudioMixerNode
    private var noiseGenerator: AVAudioSourceNode?
    private let audioEnhancer = AudioEnhancer()

    // New nodes for enhanced features
    private var ultrasonicPlayer: AVAudioPlayerNode?
    private var chatterPlayer: AVAudioPlayerNode?
    private var artifactProcessor: AVAudioUnit?

    // Enhanced noise configuration
    @Published var enhancedNoiseType: NoiseType = .green
    @Published var enableArtifacts: Bool = true
    @Published var artifactIntensity: Float = 0.5
    @Published var chatterVolume: Float = 0.08
    @Published var ultrasonicVolume: Float = 0.03

    // Volume controls for mixing
    @Published var micGain: Float = 0.3  // Default increased from typical low levels
    @Published var noiseVolume: Float = 0.1  // Default noise volume

    @Published var virtualMicState: VirtualMicState = .driverMissing
    private var injector: VirtualMicInjector?
    private var virtualMicTapInstalled: Bool = false

    private var combinedMixer: AVAudioMixerNode?
    private var micInputNode: AVAudioInputNode?
    private var micFormat: AVAudioFormat?

    @Published private(set) var isPlaying = false
    @Published private(set) var currentFrequency: Float = 0

    private var currentNoiseType: NoiseType = .green
    private let sampleRate: Double = 44100
    private let nyquistFrequency: Double = 22050

    init() {
        self.mainMixer = engine.mainMixerNode
        setupEngine()
        setupEnhancedNodes()
        checkVirtualMicPresence()
    }

    deinit {
        print("AudioEngine deinit; cleaning up virtual mic")
        stopAllAudio()
    }

    private func setupEnhancedNodes() {
        // Setup ultrasonic player
        ultrasonicPlayer = AVAudioPlayerNode()
        engine.attach(ultrasonicPlayer!)

        // Setup chatter player
        chatterPlayer = AVAudioPlayerNode()
        engine.attach(chatterPlayer!)
    }

    private func stopAllAudio() {
        stopPlaybackIfNeeded()
        stopVirtualMicIfNeeded()
        stopEnhancedFeatures()
    }

    private func stopEnhancedFeatures() {
        ultrasonicPlayer?.stop()
        chatterPlayer?.stop()
    }

    private func stopPlaybackIfNeeded() {
        if isPlaying {
            Task {
                do {
                    try await stopPlayback()
                } catch {
                    print("Error stopping playback during deinit: \(error)")
                }
            }
        }
    }

    private func stopVirtualMicIfNeeded() {
        if case .streaming = virtualMicState {
            stopVirtualMic()
        } else if injector != nil {
            injector?.stop()
            injector = nil
        }
    }

    private func setupEngine() {
        let outputNode = engine.outputNode
        let format = outputNode.inputFormat(forBus: 0)

        engine.mainMixerNode.outputVolume = 1.0
        engine.mainMixerNode.installTap(
            onBus: 0, bufferSize: 1024, format: format
        ) { [weak self] buffer, _ in
            guard let self else { return }
            let frequency = self.calculateApproximateFrequency(buffer)
            Task { @MainActor in
                self.currentFrequency = frequency
            }
        }
    }

    private func calculateApproximateFrequency(_ buffer: AVAudioPCMBuffer) -> Float {
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

    func selectEnhancedNoiseType(_ type: NoiseType) {
        enhancedNoiseType = type
        if isPlaying {
            Task {
                try? await stopPlayback()
                try? await startPlayback()
            }
        }
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

    func getAudioLevels() -> [CGFloat] {
        if isPlaying {
            return (0..<8).map { _ in CGFloat.random(in: -40...0) }
        } else {
            return Array(repeating: -160, count: 8)
        }
    }

    func updateMicGain(_ gain: Float) {
        micGain = gain
        // Apply immediately if mic is connected
        if let inputNode = micInputNode {
            inputNode.volume = gain
        }
    }

    func updateNoiseVolume(_ volume: Float) {
        noiseVolume = volume
        // Apply immediately if noise generator is active
        if let noiseNode = noiseGenerator {
            noiseNode.volume = volume
        }
    }

    func checkVirtualMicPresence() {
        let exists = (try? VirtualMicInjector().start(deviceName: "BlackHole 2ch")) != nil
        virtualMicState = exists ? .ready : .driverMissing
    }

    func startVirtualMic(includeUserMic: Bool = true) {
        checkVirtualMicPresence()
        guard case .ready = virtualMicState else { return }

        setupCombinedMixerIfNeeded()
        connectNoiseGenerator()
        connectMicInputIfNeeded(includeUserMic: includeUserMic)
        connectCombinedMixerToMainMixer()
        setupVirtualMicInjectorAndTap()
        startEngineIfNeeded()
    }

    func stopVirtualMic() {
        guard case .streaming = virtualMicState else {
            injector?.stop()
            injector = nil
            return
        }
        if virtualMicTapInstalled, let combinedMixer = combinedMixer {
            combinedMixer.removeTap(onBus: 0)
            virtualMicTapInstalled = false
        }
        injector?.stop()
        injector = nil
        if let combinedMixer = combinedMixer {
            engine.disconnectNodeInput(combinedMixer)
            engine.disconnectNodeOutput(combinedMixer)
            engine.detach(combinedMixer)
            self.combinedMixer = nil
        }
        if let inputNode = micInputNode {
            engine.disconnectNodeOutput(inputNode)
        }
        virtualMicState = .ready
    }

    // Update the makeEnhancedNoiseGenerator to only handle traditional noise types
    private func makeEnhancedNoiseGenerator() -> (Int) -> [Float] {
        let type = enhancedNoiseType
        let enableArtifacts = self.enableArtifacts
        let intensity = self.artifactIntensity
        let enhancer = self.audioEnhancer

        return { frameCount in
            var samples = [Float](repeating: 0, count: frameCount)

            // Only generate noise for traditional noise types
            switch type {
            case .green:
                for frame in 0..<frameCount {
                    samples[frame] = Float.random(in: -1...1) * 0.8
                }
            case .pink:
                for frame in 0..<frameCount {
                    samples[frame] = Float.random(in: -1...1) * 0.6
                }
            case .pinkBabble:
                for frame in 0..<frameCount {
                    let pink = Float.random(in: -1...1) * 0.6
                    let babble = Float.random(in: -0.3...0.3)
                    samples[frame] = (pink + babble) * 0.7
                }
            case .ultrasonic, .chatter, .hybrid:
                // These types don't use the noise generator - they have dedicated implementations
                // Return silence since they're handled separately
                break
            }

            // Apply artifacts only to traditional noise types if enabled
            if enableArtifacts && [.green, .pink, .pinkBabble].contains(type) {
                enhancer.addVoiceArtifacts(to: &samples, intensity: intensity)
            }

            return samples
        }
    }

    // Update startPlayback to route ALL audio through BlackHole virtual mic for privacy
    func startPlayback() async throws {
        guard !isPlaying else { return }

        // Check virtual mic presence first
        checkVirtualMicPresence()
        guard case .ready = virtualMicState else {
            throw AudioEngineError.formatCreationFailed // Use appropriate error
        }

        // Always use virtual mic routing for privacy protection
        // This ensures ALL audio goes to BlackHole, not system speakers
        startVirtualMic(includeUserMic: true)

        isPlaying = true
    }

    // Update the stopPlayback method to handle virtual mic properly
    func stopPlayback() async throws {
        guard isPlaying else { return }

        // Stop virtual mic which handles all cleanup
        stopVirtualMic()

        isPlaying = false
        currentFrequency = 0
    }
}

// MARK: - Virtual Mic Helpers (moved out of type body for linting)
private extension AudioEngine {
    func setupCombinedMixerIfNeeded() {
        guard combinedMixer == nil else { return }
        let mixer = AVAudioMixerNode()
        engine.attach(mixer)
        combinedMixer = mixer
    }

    func connectNoiseGenerator() {
        guard let combinedMixer = combinedMixer else { return }

        // Clean up any existing noise generators and players
        cleanupAudioNodes()

        // Connect ONLY the selected protection type
        switch enhancedNoiseType {
        case .green, .pink, .pinkBabble:
            // Traditional noise types use the noise generator
            connectTraditionalNoise()

        case .ultrasonic:
            // ONLY ultrasonic protection
            connectUltrasonicProtection()

        case .chatter:
            // ONLY sine wave chatter protection  
            connectChatterProtection()

        case .hybrid:
            // Hybrid cycles between methods
            connectHybridProtection()
        }
    }

    private func cleanupAudioNodes() {
        // Stop and disconnect existing nodes
        ultrasonicPlayer?.stop()
        chatterPlayer?.stop()

        if let generator = noiseGenerator {
            engine.disconnectNodeOutput(generator)
            engine.detach(generator)
            noiseGenerator = nil
        }

        if let player = ultrasonicPlayer {
            engine.disconnectNodeOutput(player)
        }

        if let player = chatterPlayer {
            engine.disconnectNodeOutput(player)
        }
    }

    private func connectTraditionalNoise() {
        guard let combinedMixer = combinedMixer else { return }

        let generator = makeEnhancedNoiseGenerator()
        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let samples = generator(Int(frameCount))
            guard let mData = ablPointer[0].mData else { return kAudioUnitErr_InvalidParameter }
            samples.withUnsafeBufferPointer { buffer in
                let countBytes = Int(frameCount) * MemoryLayout<Float>.stride
                mData.copyMemory(from: buffer.baseAddress!, byteCount: countBytes)
            }
            return noErr
        }

        noiseGenerator = node
        engine.attach(node)
        node.volume = noiseVolume
        engine.connect(
            node,
            to: combinedMixer,
            format: mainMixer.outputFormat(forBus: 0)
        )
    }

    private func connectUltrasonicProtection() {
        guard let combinedMixer = combinedMixer,
              let buffer = audioEnhancer.generateInaudibleTones(duration: 10.0),
              let player = ultrasonicPlayer else { return }

        let format = buffer.format
        engine.connect(player, to: combinedMixer, format: format)

        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.volume = ultrasonicVolume
        player.play()
    }

    private func connectChatterProtection() {
        guard let combinedMixer = combinedMixer,
              let buffer = audioEnhancer.generateBackgroundChatter(duration: 30.0),
              let player = chatterPlayer else { return }

        let format = buffer.format
        engine.connect(player, to: combinedMixer, format: format)

        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.volume = chatterVolume
        player.play()
    }

    private func connectHybridProtection() {
        // For hybrid, start with ultrasonic and let it cycle
        connectUltrasonicProtection()

        // Schedule transition to chatter after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self, self.isPlaying else { return }
            self.switchToChatterInHybrid()
        }
    }

    func connectMicInputIfNeeded(includeUserMic: Bool) {
        guard let combinedMixer = combinedMixer else { return }
        if includeUserMic {
            let inputNode = engine.inputNode
            let micFormat = inputNode.outputFormat(forBus: 0)
            self.micInputNode = inputNode
            self.micFormat = micFormat
            engine.disconnectNodeOutput(inputNode)
            engine.connect(inputNode, to: combinedMixer, format: micFormat)
            // Apply microphone gain
            inputNode.volume = micGain
        } else if let inputNode = micInputNode {
            engine.disconnectNodeOutput(inputNode)
        }
    }

    func connectCombinedMixerToMainMixer() {
        guard let combinedMixer = combinedMixer else { return }
        engine.disconnectNodeOutput(combinedMixer)
        engine.connect(
            combinedMixer,
            to: mainMixer,
            format: mainMixer.outputFormat(forBus: 0)
        )
    }

    func setupVirtualMicInjectorAndTap() {
        guard let combinedMixer = combinedMixer else { return }
        if injector == nil {
            injector = VirtualMicInjector(sampleRate: 44100, channels: 1)
        }
        do {
            try injector?.start(deviceName: "BlackHole 2ch")
            if !virtualMicTapInstalled {
                combinedMixer.installTap(
                    onBus: 0,
                    bufferSize: 1024,
                    format: combinedMixer.outputFormat(forBus: 0)
                ) { [weak self] buf, _ in
                    self?.injector?.push(buf)
                }
                virtualMicTapInstalled = true
            }
            virtualMicState = .streaming
        } catch {
            virtualMicState = .error(error.localizedDescription)
        }
    }

    func startEngineIfNeeded() {
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Failed to start engine: \(error)")
            }
        }
    }

    // Updated hybrid switching methods to work with virtual mic routing
    func switchToChatterInHybrid() {
        guard isPlaying, enhancedNoiseType == .hybrid else { return }

        // Stop ultrasonic
        ultrasonicPlayer?.stop()
        if let player = ultrasonicPlayer {
            engine.disconnectNodeOutput(player)
        }

        // Start chatter
        connectChatterProtection()

        // Schedule switch back to ultrasonic
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self, self.isPlaying else { return }
            self.switchToUltrasonicInHybrid()
        }
    }

    func switchToUltrasonicInHybrid() {
        guard isPlaying, enhancedNoiseType == .hybrid else { return }

        // Stop chatter
        chatterPlayer?.stop()
        if let player = chatterPlayer {
            engine.disconnectNodeOutput(player)
        }

        // Start ultrasonic
        connectUltrasonicProtection()

        // Schedule switch back to chatter
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self, self.isPlaying else { return }
            self.switchToChatterInHybrid()
        }
    }

}
