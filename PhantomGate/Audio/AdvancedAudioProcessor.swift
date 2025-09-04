//
//  AdvancedAudioProcessor.swift
//  PhantomGate
//
//  Created by David Jensenius on 2025-09-04.
//

import AVFoundation
import Accelerate
import Foundation

/// Advanced audio processing techniques for disrupting ASR systems
class AdvancedAudioProcessor {
    private let sampleRate: Double = 44100.0
    private let nyquistFrequency: Double = 22050.0
    
    // FFT setup for spectral operations
    private let fftSize = 2048
    private let hopSize = 1024
    private var fftSetup: FFTSetup?
    private var window: [Float] = []
    
    // State for dynamic effects
    private var dynamicNotchFrequency: Double = 300.0
    private var notchDirection: Double = 1.0
    private var quantizationMode: Int = 0
    private var rotationCycleTimer: Double = 0.0
    
    init() {
        setupFFT()
        generateWindow()
    }
    
    deinit {
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
        }
    }
    
    private func setupFFT() {
        let log2n = vDSP_Length(log2(Double(fftSize)))
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
    }
    
    private func generateWindow() {
        window = Array(0..<fftSize).map { i in
            Float(0.5 - 0.5 * cos(2.0 * .pi * Double(i) / Double(fftSize - 1)))
        }
    }
    
    // MARK: - Spectral Manipulation
    
    /// Dynamic Bandstop Sweeps ("Spectral Hole Punching")
    func generateSpectralSweep(duration: TimeInterval = 10.0, intensity: Float = 0.5) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: sampleRate,
                                         channels: 2,
                                         interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                           frameCapacity: AVAudioFrameCount(sampleRate * duration)) else {
            return nil
        }
        
        buffer.frameLength = buffer.frameCapacity
        guard let channelData = buffer.floatChannelData else { return nil }
        
        let frameCount = Int(buffer.frameLength)
        var tempBuffer = [Float](repeating: 0, count: frameCount)
        
        // Generate base noise signal
        for frame in 0..<frameCount {
            tempBuffer[frame] = Float.random(in: -1...1) * 0.3
        }
        
        // Apply dynamic bandstop filtering
        applyDynamicBandstop(to: &tempBuffer, intensity: intensity)
        
        // Copy to stereo channels
        for channel in 0..<2 {
            for frame in 0..<frameCount {
                channelData[channel][frame] = tempBuffer[frame] * (0.8 + Float(channel) * 0.2)
            }
        }
        
        return buffer
    }
    
    private func applyDynamicBandstop(to samples: inout [Float], intensity: Float) {
        let frameCount = samples.count
        let notchWidth: Double = 200.0 * Double(intensity)
        let updateRate = Int(sampleRate * 0.1) // Update every 100ms
        
        for frame in 0..<frameCount {
            if frame % updateRate == 0 {
                updateDynamicNotch()
            }
            
            // Apply simple IIR bandstop filter approximation
            let time = Double(frame) / sampleRate
            let notchCenter = dynamicNotchFrequency
            
            // Create notch effect by subtracting filtered content
            let notchSignal = sin(2.0 * .pi * notchCenter * time)
            let attenuationFactor = 1.0 - Double(intensity) * 0.6
            
            samples[frame] *= Float(attenuationFactor + 0.4 * sin(2.0 * .pi * notchCenter * time / sampleRate))
        }
    }
    
    private func updateDynamicNotch() {
        // Sweep through vocal formant range (300-3400 Hz)
        dynamicNotchFrequency += notchDirection * 50.0
        
        if dynamicNotchFrequency > 3400.0 {
            dynamicNotchFrequency = 3400.0
            notchDirection = -1.0
        } else if dynamicNotchFrequency < 300.0 {
            dynamicNotchFrequency = 300.0
            notchDirection = 1.0
        }
    }
    
    // MARK: - Temporal Disruption
    
    /// Micro Time-Jitter (Sub‑Frame Warble)
    func generateTemporalJitter(duration: TimeInterval = 10.0, intensity: Float = 0.5) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: sampleRate,
                                         channels: 2,
                                         interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                           frameCapacity: AVAudioFrameCount(sampleRate * duration)) else {
            return nil
        }
        
        buffer.frameLength = buffer.frameCapacity
        guard let channelData = buffer.floatChannelData else { return nil }
        
        let frameCount = Int(buffer.frameLength)
        var baseSignal = generateBaseVoiceSignal(frameCount: frameCount)
        
        // Apply temporal jitter
        applyTimeJitter(to: &baseSignal, intensity: intensity)
        
        // Copy to stereo channels
        for channel in 0..<2 {
            for frame in 0..<frameCount {
                channelData[channel][frame] = baseSignal[frame] * (0.8 + Float(channel) * 0.2)
            }
        }
        
        return buffer
    }
    
    private func generateBaseVoiceSignal(frameCount: Int) -> [Float] {
        var signal = [Float](repeating: 0, count: frameCount)
        
        for frame in 0..<frameCount {
            let time = Double(frame) / sampleRate
            
            // Generate formant-like signal
            let f1 = 500.0 + sin(time * 0.5) * 200.0  // First formant
            let f2 = 1400.0 + sin(time * 0.7) * 300.0 // Second formant
            let f3 = 2800.0 + sin(time * 0.3) * 400.0 // Third formant
            
            var sample = 0.0
            sample += sin(2.0 * .pi * f1 * time) * 0.3
            sample += sin(2.0 * .pi * f2 * time) * 0.2
            sample += sin(2.0 * .pi * f3 * time) * 0.1
            
            // Add harmonic content
            sample += sin(2.0 * .pi * 150.0 * time) * 0.4  // Fundamental
            
            signal[frame] = Float(sample)
        }
        
        return signal
    }
    
    private func applyTimeJitter(to samples: inout [Float], intensity: Float) {
        let frameCount = samples.count
        let maxJitter = Int(intensity * 6.0 * sampleRate / 1000.0) // Up to 6ms jitter
        
        var tempBuffer = samples
        
        for frame in 0..<frameCount {
            if Int.random(in: 0...100) < Int(intensity * 10) {
                let jitter = Int.random(in: -maxJitter...maxJitter)
                let sourceFrame = frame + jitter
                
                if sourceFrame >= 0 && sourceFrame < frameCount {
                    samples[frame] = tempBuffer[sourceFrame]
                }
            }
        }
    }
    
    // MARK: - Voice Feature Distortion
    
    /// Phase Randomization
    func generatePhaseScramble(duration: TimeInterval = 10.0, intensity: Float = 0.5) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: sampleRate,
                                         channels: 2,
                                         interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                           frameCapacity: AVAudioFrameCount(sampleRate * duration)) else {
            return nil
        }
        
        buffer.frameLength = buffer.frameCapacity
        guard let channelData = buffer.floatChannelData else { return nil }
        
        let frameCount = Int(buffer.frameLength)
        var baseSignal = generateBaseVoiceSignal(frameCount: frameCount)
        
        // Apply FFT-based phase scrambling
        applyPhaseScrambling(to: &baseSignal, intensity: intensity)
        
        // Copy to stereo channels
        for channel in 0..<2 {
            for frame in 0..<frameCount {
                channelData[channel][frame] = baseSignal[frame] * (0.6 + Float(channel) * 0.2)
            }
        }
        
        return buffer
    }
    
    private func applyPhaseScrambling(to samples: inout [Float], intensity: Float) {
        // Simple phase scrambling approximation without full FFT implementation
        // This creates a similar effect by modulating the signal with random phases
        
        let frameCount = samples.count
        
        for frame in 0..<frameCount {
            let time = Double(frame) / sampleRate
            
            // Generate multiple phase-shifted versions
            var scrambledSample: Float = 0.0
            let numPhases = 8
            
            for phase in 0..<numPhases {
                let randomPhase = Double.random(in: 0...2.0 * .pi) * Double(intensity)
                let frequency = 800.0 + Double(phase) * 300.0
                let phasedSignal = sin(2.0 * .pi * frequency * time + randomPhase)
                scrambledSample += Float(phasedSignal) / Float(numPhases)
            }
            
            // Mix with original signal
            samples[frame] = samples[frame] * (1.0 - intensity * 0.8) + scrambledSample * intensity * 0.4
        }
    }
    
    // MARK: - Quantization and Dithering
    
    /// Quantization + Dither Cycling
    func generateQuantizePulse(duration: TimeInterval = 10.0, intensity: Float = 0.5) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: sampleRate,
                                         channels: 2,
                                         interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                           frameCapacity: AVAudioFrameCount(sampleRate * duration)) else {
            return nil
        }
        
        buffer.frameLength = buffer.frameCapacity
        guard let channelData = buffer.floatChannelData else { return nil }
        
        let frameCount = Int(buffer.frameLength)
        var baseSignal = generateBaseVoiceSignal(frameCount: frameCount)
        
        // Apply quantization cycling
        applyQuantizationCycling(to: &baseSignal, intensity: intensity)
        
        // Copy to stereo channels
        for channel in 0..<2 {
            for frame in 0..<frameCount {
                channelData[channel][frame] = baseSignal[frame] * (0.7 + Float(channel) * 0.2)
            }
        }
        
        return buffer
    }
    
    private func applyQuantizationCycling(to samples: inout [Float], intensity: Float) {
        let frameCount = samples.count
        let cycleLength = Int(sampleRate * 0.2) // 200ms cycles
        
        for frame in 0..<frameCount {
            let cyclePosition = frame % cycleLength
            let cyclePhase = Double(cyclePosition) / Double(cycleLength)
            
            // Cycle through different quantization levels
            var quantizationBits: Int
            if cyclePhase < 0.33 {
                quantizationBits = 8
            } else if cyclePhase < 0.66 {
                quantizationBits = 6
            } else {
                quantizationBits = 5
            }
            
            // Apply quantization
            let quantizationLevels = Float(1 << quantizationBits)
            let quantized = round(samples[frame] * quantizationLevels) / quantizationLevels
            
            // Add noise-shaped dither
            let dither = Float.random(in: -1...1) * (1.0 / quantizationLevels) * intensity
            
            samples[frame] = quantized + dither * 0.5
        }
    }
    
    // MARK: - Whisperization
    
    /// Adversarial Whisperization
    func generateWhisperMask(duration: TimeInterval = 10.0, intensity: Float = 0.5) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: sampleRate,
                                         channels: 2,
                                         interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                           frameCapacity: AVAudioFrameCount(sampleRate * duration)) else {
            return nil
        }
        
        buffer.frameLength = buffer.frameCapacity
        guard let channelData = buffer.floatChannelData else { return nil }
        
        let frameCount = Int(buffer.frameLength)
        
        for channel in 0..<2 {
            for frame in 0..<frameCount {
                let time = Double(frame) / sampleRate
                
                // Generate band-limited whisper-like noise (200-1200 Hz)
                var sample: Float = 0.0
                
                // Multiple frequency bands for whisper texture
                for band in 0..<6 {
                    let frequency = 200.0 + Double(band) * 200.0
                    let noise = Float.random(in: -1...1)
                    let bandpass = sin(2.0 * .pi * frequency * time) * noise
                    sample += bandpass * 0.15
                }
                
                // Add turbulent breath-like noise
                let breathNoise = Float.random(in: -1...1) * 0.1
                sample += breathNoise
                
                // Apply envelope for speech-like rhythm
                let envelope = Float(abs(sin(time * 2.5)) * 0.7 + 0.3)
                sample *= envelope * intensity
                
                channelData[channel][frame] = sample * (0.6 + Float(channel) * 0.2)
            }
        }
        
        return buffer
    }
    
    // MARK: - Pitch and Formant Drift
    
    /// Controlled Pitch & Formant Divergence
    func generatePitchFormantDrift(duration: TimeInterval = 10.0, intensity: Float = 0.5) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: sampleRate,
                                         channels: 2,
                                         interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                           frameCapacity: AVAudioFrameCount(sampleRate * duration)) else {
            return nil
        }
        
        buffer.frameLength = buffer.frameCapacity
        guard let channelData = buffer.floatChannelData else { return nil }
        
        let frameCount = Int(buffer.frameLength)
        
        for channel in 0..<2 {
            for frame in 0..<frameCount {
                let time = Double(frame) / sampleRate
                
                // Pitch drift over time
                let pitchDrift = sin(time * 0.1) * Double(intensity) * 50.0 // ±50 Hz drift
                let fundamentalFreq = 150.0 + pitchDrift
                
                // Formant drift (independent of pitch)
                let formantDrift1 = sin(time * 0.15) * Double(intensity) * 100.0
                let formantDrift2 = sin(time * 0.08) * Double(intensity) * 150.0
                
                let formant1 = 500.0 + formantDrift1
                let formant2 = 1400.0 + formantDrift2
                let formant3 = 2800.0 + sin(time * 0.12) * Double(intensity) * 200.0
                
                // Generate signal with drifting characteristics
                var sample = 0.0
                sample += sin(2.0 * .pi * fundamentalFreq * time) * 0.3
                sample += sin(2.0 * .pi * formant1 * time) * 0.25
                sample += sin(2.0 * .pi * formant2 * time) * 0.2
                sample += sin(2.0 * .pi * formant3 * time) * 0.15
                
                // Add harmonic richness
                sample += sin(2.0 * .pi * fundamentalFreq * 2.0 * time) * 0.1
                sample += sin(2.0 * .pi * fundamentalFreq * 3.0 * time) * 0.05
                
                channelData[channel][frame] = Float(sample) * (0.7 + Float(channel) * 0.2)
            }
        }
        
        return buffer
    }
    
    // MARK: - Rotation Cycle
    
    /// Rotation Cycle (cycles through different modes)
    func generateRotationCycle(duration: TimeInterval = 10.0, intensity: Float = 0.5) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: sampleRate,
                                         channels: 2,
                                         interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                           frameCapacity: AVAudioFrameCount(sampleRate * duration)) else {
            return nil
        }
        
        buffer.frameLength = buffer.frameCapacity
        guard let channelData = buffer.floatChannelData else { return nil }
        
        let frameCount = Int(buffer.frameLength)
        let modeChangeDuration = 2.0 // Change mode every 2 seconds
        
        for frame in 0..<frameCount {
            let time = Double(frame) / sampleRate
            let currentMode = Int(time / modeChangeDuration) % 5 // Cycle through 5 modes
            
            var sample: Float = 0.0
            
            switch currentMode {
            case 0: // Spectral sweep mode
                let sweepFreq = 300.0 + sin(time * 2.0) * 1600.0
                sample = Float(sin(2.0 * .pi * sweepFreq * time) * 0.3)
                
            case 1: // Temporal jitter mode
                let jitteredTime = time + sin(time * 10.0) * 0.001 * Double(intensity)
                sample = Float(sin(2.0 * .pi * 800.0 * jitteredTime) * 0.3)
                
            case 2: // Phase scramble mode
                let phase1 = sin(2.0 * .pi * 600.0 * time + Double.random(in: 0...2.0 * .pi))
                let phase2 = sin(2.0 * .pi * 1200.0 * time + Double.random(in: 0...2.0 * .pi))
                sample = Float((phase1 + phase2) * 0.15)
                
            case 3: // Whisper mode
                let noise = Float.random(in: -1...1)
                let whisperFreq = 400.0 + sin(time * 3.0) * 300.0
                sample = Float(sin(2.0 * .pi * whisperFreq * time)) * noise * 0.2
                
            case 4: // Pitch drift mode
                let driftFreq = 200.0 + sin(time * 0.5) * 100.0 * Double(intensity)
                sample = Float(sin(2.0 * .pi * driftFreq * time) * 0.3)
                
            default:
                sample = 0.0
            }
            
            // Copy to stereo channels
            for channel in 0..<2 {
                channelData[channel][frame] = sample * (0.8 + Float(channel) * 0.2)
            }
        }
        
        return buffer
    }
}