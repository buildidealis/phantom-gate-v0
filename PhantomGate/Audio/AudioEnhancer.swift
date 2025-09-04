//
//  AudioEnhancer.swift
//  PhantomGate
//
//  Created by David Jensenius on 2025-08-28.
//

import AVFoundation
import Accelerate

/// Audio enhancement features for privacy protection against AI transcription
class AudioEnhancer {
    private let sampleRate: Double = 44100.0

    /// Generate buffer with ultrasonic and infrasonic tones
    func generateInaudibleTones(duration: TimeInterval = 1.0) -> AVAudioPCMBuffer? {
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

        for frame in 0..<frameCount {
            let time = Double(frame) / sampleRate

            // Ultrasonic (22kHz - above typical hearing)
            let ultrasonic = sin(2.0 * .pi * 22000.0 * time) * 0.03

            // Infrasonic (15Hz - below typical hearing)
            let infrasonic = sin(2.0 * .pi * 15.0 * time) * 0.05

            // Add frequency modulation for variation
            let modulation = sin(2.0 * .pi * 0.5 * time)
            let ultrasonicModulated = sin(2.0 * .pi * (22000.0 + modulation * 500.0) * time) * 0.03

            let sample = Float(ultrasonic + infrasonic + ultrasonicModulated)

            channelData[0][frame] = sample
            channelData[1][frame] = sample
        }

        return buffer
    }

    /// Add voice-like artifacts to make transcription difficult
    func addVoiceArtifacts(to samples: inout [Float], intensity: Float = 0.5) {
        let frameCount = samples.count

        for frame in 0..<frameCount {
            // Random micro-glitches
            if Float.random(in: 0...1) < (0.001 * intensity) {
                samples[frame] *= Float.random(in: 0.7...1.3)
            }

            // Phase shifting
            if Float.random(in: 0...1) < (0.003 * intensity) && frame > 50 {
                let phaseShift = Int.random(in: 1...30)
                if frame - phaseShift >= 0 {
                    samples[frame] = (samples[frame] + samples[frame - phaseShift]) / 2.0
                }
            }

            // Micro-dropouts
            if Float.random(in: 0...1) < (0.0002 * intensity) {
                for jjj in 0..<min(3, frameCount - frame) {
                    samples[frame + jjj] *= 0.1
                }
            }
        }
    }

    /// Generate background chatter/crowd noise
    func generateBackgroundChatter(duration: TimeInterval = 10.0) -> AVAudioPCMBuffer? {
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
            let channelOffset = Float(channel) * 0.2

            for frame in 0..<frameCount {
                let time = Double(frame) / sampleRate
                var sample: Float = 0.0

                // Generate more prominent sine waves for better recording visibility
                // Multiple frequencies for robust protection
                let frequencies = [200.0, 400.0, 800.0, 1600.0, 3200.0]
                
                for (index, baseFreq) in frequencies.enumerated() {
                    // Add slight frequency modulation for variation
                    let modulation = sin(time * (0.5 + Double(index) * 0.3)) * 50.0
                    let frequency = baseFreq + modulation
                    
                    // Generate sine wave with higher amplitude
                    let amplitude = 0.15 / Double(frequencies.count)  // Increased amplitude
                    sample += Float(sin(2.0 * .pi * frequency * time) * amplitude)
                }

                // Add harmonic content for richer spectrum
                for harmonic in 2...4 {
                    let harmFreq = 440.0 * Double(harmonic) + sin(time * 0.7) * 100.0
                    sample += Float(sin(2.0 * .pi * harmFreq * time)) * 0.08
                }

                // Simulate multiple voices with envelope
                for voice in 0..<2 {
                    let voiceOffset = Double(voice) * 60.0
                    
                    // Voice fundamental frequency
                    let voiceFreq = 150.0 + voiceOffset + sin(time * (0.4 + Double(voice) * 0.3)) * 100.0
                    let voiceAmplitude = 0.12
                    sample += Float(sin(2.0 * .pi * voiceFreq * time) * voiceAmplitude)
                    
                    // Formant-like frequencies
                    let formant1 = 500.0 + voiceOffset * 1.5 + sin(time * 0.6) * 200.0
                    sample += Float(sin(2.0 * .pi * formant1 * time)) * 0.08
                    
                    let formant2 = 1400.0 + voiceOffset * 2 + sin(time * 0.8) * 300.0
                    sample += Float(sin(2.0 * .pi * formant2 * time)) * 0.06
                }

                // Envelope modulation for speech-like patterns
                let envelope = Float(abs(sin(time * Double.random(in: 2...6))) * 0.7 + 0.3)
                sample *= envelope
                
                // Add some controlled noise for texture
                sample += Float.random(in: -0.02...0.02)

                // Apply to channel with slight stereo variation
                channelData[channel][frame] = sample * (0.8 + channelOffset)
            }
        }

        return buffer
    }
}
