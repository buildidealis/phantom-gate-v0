import AVFoundation
import CoreGraphics
import Foundation

class AudioEngine: ObservableObject {
    let engine = AVAudioEngine()
    let mainMixer: AVAudioMixerNode
    private var noiseGenerator: AVAudioSourceNode?

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

        let generator = makeNoiseGenerator()

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
        if noiseGenerator == nil {
            let generator = makeNoiseGenerator()
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
        if let noiseNode = noiseGenerator, let combinedMixer = combinedMixer {
            engine.disconnectNodeOutput(noiseNode)
            engine.connect(
                noiseNode,
                to: combinedMixer,
                format: mainMixer.outputFormat(forBus: 0)
            )
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

    func makeNoiseGenerator() -> (Int) -> [Float] {
        let type = currentNoiseType
        return { frameCount in
            var samples = [Float](repeating: 0, count: frameCount)
            for frame in 0..<frameCount {
                switch type {
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
    }
}
