import AVFoundation
import CoreGraphics
import Foundation

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

class AudioEngine: ObservableObject {
    let engine = AVAudioEngine()
    let mainMixer: AVAudioMixerNode
    private var noiseGenerator: AVAudioSourceNode?

    // Virtual mic state and injector
    @Published var virtualMicState: VirtualMicState = .driverMissing
    private var injector: VirtualMicInjector?
    private var virtualMicTapInstalled: Bool = false

    // Combined mixer for noise + mic
    private var combinedMixer: AVAudioMixerNode?
    private var micInputNode: AVAudioInputNode?
    private var micFormat: AVAudioFormat?

    // Playback state
    @Published private(set) var isPlaying = false
    @Published private(set) var currentFrequency: Float = 0

    // Noise generation params
    private var currentNoiseType: NoiseType = .green
    private let sampleRate: Double = 44100
    private let nyquistFrequency: Double = 22050 // sampleRate / 2 (unused for now)

    init() {
        self.mainMixer = engine.mainMixerNode
        setupEngine()
        checkVirtualMicPresence()
    }

    deinit {
        print("AudioEngine deinit; cleaning up virtual mic")
        stopAllAudio()
    }

    private func stopAllAudio() {
        stopPlaybackIfNeeded()
        stopVirtualMicIfNeeded()
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
        // Frequency estimation tap (does not interfere with virtual mic path)
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
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

        let generator = { [currentNoiseType] (frameCount: Int) -> [Float] in
            var samples = [Float](repeating: 0, count: frameCount)
            for frame in 0..<frameCount {
                switch currentNoiseType {
                case .green:
                    samples[frame] = Float.random(in: -1...1) * 0.8
                case .pink:
                    samples[frame] = Float.random(in: -1...1) * 0.6
                case .pinkBabble:
                    let pink = Float.random(in: -1...1) * 0.6
                    let babble = Float.random(in: -0.3...0.3)
                    samples[frame] = (pink + babble) * 0.7
                }
            }
            return samples
        }

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
        if isPlaying {
            return (0..<8).map { _ in CGFloat.random(in: -40...0) }
        } else {
            return Array(repeating: -160, count: 8)
        }
    }

    // MARK: - Virtual Mic Integration

    /// Checks for BlackHole (or other device)
    func checkVirtualMicPresence() {
        let exists = (try? VirtualMicInjector().start(deviceName: "BlackHole 2ch")) != nil
        virtualMicState = exists ? .ready : .driverMissing
    }

    /// Start the virtual mic with a combined audio path (noise + user's mic)
    func startVirtualMic(includeUserMic: Bool = true) {
        checkVirtualMicPresence()
        guard case .ready = virtualMicState else { return }

        // 1. Setup combined mixer
        if combinedMixer == nil {
            let mixer = AVAudioMixerNode()
            engine.attach(mixer)
            combinedMixer = mixer
        }

        guard let combinedMixer = combinedMixer else {
            virtualMicState = .error("Mixer creation failed")
            return
        }

        // 2. Connect noise generator
        if noiseGenerator == nil {
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            let generator = { [currentNoiseType] (frameCount: Int) -> [Float] in
                var samples = [Float](repeating: 0, count: frameCount)
                for frame in 0..<frameCount {
                    switch currentNoiseType {
                    case .green:
                        samples[frame] = Float.random(in: -1...1) * 0.8
                    case .pink:
                        samples[frame] = Float.random(in: -1...1) * 0.6
                    case .pinkBabble:
                        let pink = Float.random(in: -1...1) * 0.6
                        let babble = Float.random(in: -0.3...0.3)
                        samples[frame] = (pink + babble) * 0.7
                    }
                }
                return samples
            }
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
        }
        if let noiseNode = noiseGenerator {
            // Reconnect to combined mixer (even if already connected)
            engine.disconnectNodeOutput(noiseNode)
            engine.connect(noiseNode, to: combinedMixer, format: mainMixer.outputFormat(forBus: 0))
        }

        // 3. Optionally connect mic input
        if includeUserMic {
            let inputNode = engine.inputNode
            let micFormat = inputNode.outputFormat(forBus: 0)
            self.micInputNode = inputNode
            self.micFormat = micFormat
            engine.disconnectNodeOutput(inputNode)
            engine.connect(inputNode, to: combinedMixer, format: micFormat)
        } else if let inputNode = micInputNode {
            // Disconnect mic if previously connected
            engine.disconnectNodeOutput(inputNode)
        }

        // 4. Connect combined mixer to main output (local monitoring)
        engine.disconnectNodeOutput(combinedMixer)
        engine.connect(combinedMixer, to: mainMixer, format: mainMixer.outputFormat(forBus: 0))

        // 5. Create injector & tap on combined mixer
        if injector == nil {
            injector = VirtualMicInjector(sampleRate: 44100, channels: 1)
        }
        do {
            try injector?.start(deviceName: "BlackHole 2ch")
            if !virtualMicTapInstalled {
                combinedMixer.installTap(onBus: 0, bufferSize: 1024, format: combinedMixer.outputFormat(forBus: 0)) { [weak self] buf, _ in
                    self?.injector?.push(buf)
                }
                virtualMicTapInstalled = true
            }
            if !engine.isRunning {
                try engine.start()
            }
            virtualMicState = .streaming
        } catch {
            virtualMicState = .error(error.localizedDescription)
        }
    }

    /// Stops the virtual mic and cleans up
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
        // Disconnect combined mixer and input
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
}
