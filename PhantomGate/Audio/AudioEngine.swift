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

    // Automatic Gain Control (AGC) settings
    @Published var autoAdjustMic: Bool = true  // Enable AGC by default
    private var micLevelTapInstalled: Bool = false
    private let targetMicLevel: Float = 0.3  // Target RMS level (-10 dB)
    private let minMicGain: Float = 0.1      // Minimum gain (prevent too quiet)
    private let maxMicGain: Float = 2.0      // Maximum gain (prevent distortion)
    private let agcSmoothingFactor: Float = 0.1  // How quickly AGC adjusts (0.0-1.0)

    @Published var virtualMicState: VirtualMicState = .driverMissing
    private var injector: VirtualMicInjector?
    private var virtualMicTapInstalled: Bool = false

    private var combinedMixer: AVAudioMixerNode?
    private var micInputNode: AVAudioInputNode?
    private var micFormat: AVAudioFormat?

    private enum ConnectionState {
        case disconnected
        case connecting
        case connected
    }

    @Published private(set) var isPlaying = false
    @Published private(set) var currentFrequency: Float = 0

    private var connectionState: ConnectionState = .disconnected

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
        // Use smaller buffer size for lower latency
        engine.mainMixerNode.installTap(
            onBus: 0, bufferSize: 512, format: format  // Reduced from 1024
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

    func toggleAutoAdjustMic(_ enabled: Bool) {
        autoAdjustMic = enabled

        // If disabling, remove the tap
        if !enabled && micLevelTapInstalled {
            if let inputNode = micInputNode {
                inputNode.removeTap(onBus: 0)
                micLevelTapInstalled = false
            }
        }
        // If enabling and mic is connected, install tap
        else if enabled && !micLevelTapInstalled && micInputNode != nil {
            if let inputNode = micInputNode, let format = micFormat {
                installMicLevelTap(on: inputNode, format: format)
            }
        }
    }

    func updateNoiseVolume(_ volume: Float) {
        noiseVolume = volume
        // Apply immediately if noise generator is active
        if let noiseNode = noiseGenerator {
            noiseNode.volume = volume
        }
    }

    // MARK: - Automatic Gain Control (AGC) - Private Helpers

    private func installMicLevelTap(on inputNode: AVAudioInputNode, format: AVAudioFormat) {
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format
        ) { [weak self] buffer, _ in
            guard let self = self, self.autoAdjustMic else { return }

            let rmsLevel = self.calculateRMS(from: buffer)
            self.adjustMicGainBasedOnLevel(rmsLevel)
        }
        micLevelTapInstalled = true
    }

    private func calculateRMS(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }

        let channelDataPointer = channelData[0]
        let frameLength = Int(buffer.frameLength)

        var sum: Float = 0.0
        for frame in 0..<frameLength {
            let sample = channelDataPointer[frame]
            sum += sample * sample
        }

        let meanSquare = sum / Float(frameLength)
        return sqrt(meanSquare)
    }

    private func adjustMicGainBasedOnLevel(_ rmsLevel: Float) {
        // Avoid division by zero and very small levels
        guard rmsLevel > 0.001 else { return }

        // Calculate the gain adjustment needed to reach target level
        let gainAdjustment = targetMicLevel / rmsLevel

        // Apply smoothing to prevent abrupt changes
        let newGain = micGain + (gainAdjustment - 1.0) * agcSmoothingFactor

        // Clamp to min/max bounds
        let clampedGain = max(minMicGain, min(maxMicGain, newGain))

        // Only update if change is significant (prevents micro-adjustments)
        if abs(clampedGain - micGain) > 0.01 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.micGain = clampedGain
                if let inputNode = self.micInputNode {
                    inputNode.volume = clampedGain
                }
            }
        }
    }

    func checkVirtualMicPresence() {
        let exists = (try? VirtualMicInjector().start(deviceName: "BlackHole 2ch")) != nil
        virtualMicState = exists ? .ready : .driverMissing
    }

    func startVirtualMic(includeUserMic: Bool = true) {
        checkVirtualMicPresence()
        guard case .ready = virtualMicState else { return }

        // Check if system input is properly configured
        if includeUserMic && AudioInputManager.isDefaultInputVirtual() {
            let currentInput = AudioInputManager.getCurrentInputDescription()
            print("⚠️ IMPORTANT: Your system microphone is set to '\(currentInput)'")
            print("   For PhantomGate to work correctly, set your system input to your hardware microphone.")
            print("   System Settings → Sound → Input → Select 'MacBook Pro Microphone' or similar")

            // Continue anyway, but user may experience issues
        }

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
        // Remove microphone level tap if installed
        if micLevelTapInstalled, let inputNode = micInputNode {
            inputNode.removeTap(onBus: 0)
            micLevelTapInstalled = false
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
            case .ultrasonic, .chatter, .hybrid, .spectralSweep, .temporalJitter, .whisperMask,
                    .pitchFormantDrift, .phaseScramble, .quantizePulse, .rotationCycle:
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
        guard combinedMixer != nil else { return }
        guard connectionState != .connecting else { return } // Prevent concurrent connections

        connectionState = .connecting

        // Clean up any existing connections first
        cleanupAudioNodes()

        // Small delay to ensure cleanup is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Connect ONLY the selected protection type
            switch self.enhancedNoiseType {
            case .green, .pink, .pinkBabble:
                // Traditional noise types use the noise generator
                self.connectTraditionalNoise()

            case .ultrasonic:
                // ONLY ultrasonic protection
                self.connectUltrasonicProtection()

            case .chatter:
                // ONLY sine wave chatter protection
                self.connectChatterProtection()

            case .hybrid:
                // Hybrid cycles between methods
                self.connectHybridProtection()

            case .spectralSweep, .temporalJitter, .whisperMask, .pitchFormantDrift,
                    .phaseScramble, .quantizePulse, .rotationCycle:
                // Advanced disruptive modes
                self.connectAdvancedDisruption()
            }

            self.connectionState = .connected
        }
    }

    private func cleanupAudioNodes() {
        connectionState = .disconnected

        // Stop players first
        ultrasonicPlayer?.stop()
        chatterPlayer?.stop()

        // Disconnect and cleanup noise generator
        if let generator = noiseGenerator {
            engine.disconnectNodeOutput(generator)
            engine.detach(generator)
            noiseGenerator = nil
        }

        // Disconnect player nodes but keep them attached for reuse
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
              let player = ultrasonicPlayer else { return }

        // Ensure player is stopped before reconfiguring
        player.stop()

        // Generate ultrasonic buffer
        guard let buffer = audioEnhancer.generateInaudibleTones(duration: 10.0) else { return }

        let format = buffer.format

        // Connect player to mixer
        engine.connect(player, to: combinedMixer, format: format)

        // Schedule buffer
        player.scheduleBuffer(buffer, at: nil, options: .loops)

        // Set volume
        player.volume = ultrasonicVolume

        // Ensure engine is running before starting player
        startEngineIfNeeded()

        // Start player
        player.play()
    }

    private func connectChatterProtection() {
        guard let combinedMixer = combinedMixer,
              let player = chatterPlayer else {
            print("AudioEngine: Failed to get combinedMixer or chatterPlayer")
            return
        }

        print("AudioEngine: Connecting chatter protection")

        // Ensure player is stopped before reconfiguring
        player.stop()

        // Generate chatter buffer with higher volume for visibility in recordings
        guard let buffer = audioEnhancer.generateBackgroundChatter(duration: 30.0) else {
            print("AudioEngine: Failed to generate chatter buffer")
            return
        }

        let format = buffer.format
        print("AudioEngine: Generated chatter buffer with format: \(format)")

        do {
            // Connect player to mixer
            engine.connect(player, to: combinedMixer, format: format)
            print("AudioEngine: Connected chatter player to mixer")

            // Schedule buffer
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            print("AudioEngine: Scheduled chatter buffer")

            // Set volume (increased for better detection in recordings)
            player.volume = chatterVolume * 3.0  // Boost volume for recordings
            print("AudioEngine: Set chatter volume to \(player.volume)")

            // Ensure engine is running before starting player
            startEngineIfNeeded()

            // Start player
            player.play()
            print("AudioEngine: Started chatter player")

        }
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

    private func connectAdvancedDisruption() {
        guard let combinedMixer = combinedMixer else { return }

        // Create a new audio player for advanced disruption
        let advancedPlayer = AVAudioPlayerNode()
        engine.attach(advancedPlayer)

        // Generate buffer for the selected advanced mode
        guard let buffer = audioEnhancer.generateAdvancedDisruption(
            type: enhancedNoiseType,
            duration: 30.0,  // Longer duration for sustained effect
            intensity: artifactIntensity
        ) else {
            print("AudioEngine: Failed to generate advanced disruption buffer")
            return
        }

        let format = buffer.format

        // Connect player to mixer
        engine.connect(advancedPlayer, to: combinedMixer, format: format)

        // Schedule buffer with looping
        advancedPlayer.scheduleBuffer(buffer, at: nil, options: .loops)

        // Set volume based on noise type
        advancedPlayer.volume = noiseVolume * 2.0  // Boost for effectiveness

        // Store reference for cleanup (reuse ultrasonicPlayer slot for simplicity)
        ultrasonicPlayer = advancedPlayer

        // Ensure engine is running before starting player
        startEngineIfNeeded()

        // Start player
        advancedPlayer.play()

        print("AudioEngine: Started advanced disruption mode: \(enhancedNoiseType.rawValue)")
    }

    func connectMicInputIfNeeded(includeUserMic: Bool) {
        guard let combinedMixer = combinedMixer else { return }
        if includeUserMic {
            // Validate input source before connecting
            if AudioInputManager.isDefaultInputVirtual() {
                let currentInput = AudioInputManager.getCurrentInputDescription()
                print("⚠️ WARNING: System input is set to virtual device '\(currentInput)'")
                print("   This may cause audio routing issues. Please set system input to your hardware microphone.")
                print("   Go to: System Settings → Sound → Input → Select your MacBook microphone")

                // Try to find and use hardware microphone instead
                if let hardwareMic = AudioInputManager.findHardwareMicrophone() {
                    print("   Found hardware microphone: '\(hardwareMic.name)'")
                    print("   NOTE: PhantomGate will use system default. Please update system settings.")
                }
            }

            let inputNode = engine.inputNode
            let micFormat = inputNode.outputFormat(forBus: 0)
            self.micInputNode = inputNode
            self.micFormat = micFormat
            engine.disconnectNodeOutput(inputNode)
            engine.connect(inputNode, to: combinedMixer, format: micFormat)
            // Apply microphone gain
            inputNode.volume = micGain
            // Install AGC tap if auto-adjust is enabled
            if autoAdjustMic && !micLevelTapInstalled {
                installMicLevelTap(on: inputNode, format: micFormat)
            }

            print("✓ Microphone connected: \(AudioInputManager.getCurrentInputDescription())")
        } else if let inputNode = micInputNode {
            engine.disconnectNodeOutput(inputNode)
          // Remove tap if installed
                if micLevelTapInstalled {
                    inputNode.removeTap(onBus: 0)
                    micLevelTapInstalled = false
                }
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
                // Use smaller buffer size for lower latency
                combinedMixer.installTap(
                    onBus: 0,
                    bufferSize: 512,  // Reduced from 1024 for lower latency
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
