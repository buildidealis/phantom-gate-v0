//
//  AdvancedAudioProcessorTests.swift
//  PhantomGateTests
//
//  Created by David Jensenius on 2025-09-04.
//

import Testing
@testable import PhantomGate
import AVFoundation

struct AdvancedAudioProcessorTests {

    // MARK: - Basic Functionality Tests

    @Test func testAdvancedAudioProcessorInitialization() async throws {
        let processor = AdvancedAudioProcessor()
        // If initialization succeeds without throwing, the test passes
        #expect(processor != nil)
    }

    @Test func testSpectralSweepGeneration() async throws {
        let processor = AdvancedAudioProcessor()
        let buffer = processor.generateSpectralSweep(duration: 1.0, intensity: 0.5)
        
        #expect(buffer != nil, "Spectral sweep buffer should be generated")
        #expect(buffer?.frameLength ?? 0 > 0, "Buffer should have frames")
        #expect(buffer?.format.channelCount == 2, "Buffer should be stereo")
        #expect(buffer?.format.sampleRate == 44100.0, "Buffer should have correct sample rate")
    }

    @Test func testTemporalJitterGeneration() async throws {
        let processor = AdvancedAudioProcessor()
        let buffer = processor.generateTemporalJitter(duration: 1.0, intensity: 0.5)
        
        #expect(buffer != nil, "Temporal jitter buffer should be generated")
        #expect(buffer?.frameLength ?? 0 > 0, "Buffer should have frames")
        #expect(buffer?.format.channelCount == 2, "Buffer should be stereo")
    }

    @Test func testWhisperMaskGeneration() async throws {
        let processor = AdvancedAudioProcessor()
        let buffer = processor.generateWhisperMask(duration: 1.0, intensity: 0.5)
        
        #expect(buffer != nil, "Whisper mask buffer should be generated")
        #expect(buffer?.frameLength ?? 0 > 0, "Buffer should have frames")
        #expect(buffer?.format.channelCount == 2, "Buffer should be stereo")
    }

    @Test func testPhaseScrambleGeneration() async throws {
        let processor = AdvancedAudioProcessor()
        let buffer = processor.generatePhaseScramble(duration: 1.0, intensity: 0.5)
        
        #expect(buffer != nil, "Phase scramble buffer should be generated")
        #expect(buffer?.frameLength ?? 0 > 0, "Buffer should have frames")
        #expect(buffer?.format.channelCount == 2, "Buffer should be stereo")
    }

    @Test func testQuantizePulseGeneration() async throws {
        let processor = AdvancedAudioProcessor()
        let buffer = processor.generateQuantizePulse(duration: 1.0, intensity: 0.5)
        
        #expect(buffer != nil, "Quantize pulse buffer should be generated")
        #expect(buffer?.frameLength ?? 0 > 0, "Buffer should have frames")
        #expect(buffer?.format.channelCount == 2, "Buffer should be stereo")
    }

    @Test func testPitchFormantDriftGeneration() async throws {
        let processor = AdvancedAudioProcessor()
        let buffer = processor.generatePitchFormantDrift(duration: 1.0, intensity: 0.5)
        
        #expect(buffer != nil, "Pitch formant drift buffer should be generated")
        #expect(buffer?.frameLength ?? 0 > 0, "Buffer should have frames")
        #expect(buffer?.format.channelCount == 2, "Buffer should be stereo")
    }

    @Test func testRotationCycleGeneration() async throws {
        let processor = AdvancedAudioProcessor()
        let buffer = processor.generateRotationCycle(duration: 2.0, intensity: 0.5)
        
        #expect(buffer != nil, "Rotation cycle buffer should be generated")
        #expect(buffer?.frameLength ?? 0 > 0, "Buffer should have frames")
        #expect(buffer?.format.channelCount == 2, "Buffer should be stereo")
    }

    // MARK: - Parameter Tests

    @Test func testIntensityParameterRange() async throws {
        let processor = AdvancedAudioProcessor()
        
        // Test minimum intensity
        let lowBuffer = processor.generateSpectralSweep(duration: 0.1, intensity: 0.0)
        #expect(lowBuffer != nil, "Should generate buffer with zero intensity")
        
        // Test maximum intensity
        let highBuffer = processor.generateSpectralSweep(duration: 0.1, intensity: 1.0)
        #expect(highBuffer != nil, "Should generate buffer with maximum intensity")
    }

    @Test func testDurationParameter() async throws {
        let processor = AdvancedAudioProcessor()
        
        // Test short duration
        let shortBuffer = processor.generateTemporalJitter(duration: 0.1, intensity: 0.5)
        #expect(shortBuffer != nil, "Should generate short buffer")
        #expect(shortBuffer?.frameLength == AVAudioFrameCount(44100.0 * 0.1), "Frame count should match duration")
        
        // Test longer duration
        let longBuffer = processor.generateTemporalJitter(duration: 5.0, intensity: 0.5)
        #expect(longBuffer != nil, "Should generate longer buffer")
        #expect(longBuffer?.frameLength == AVAudioFrameCount(44100.0 * 5.0), "Frame count should match duration")
    }

    // MARK: - AudioEnhancer Integration Tests

    @Test func testAudioEnhancerAdvancedIntegration() async throws {
        let enhancer = AudioEnhancer()
        
        // Test each advanced noise type
        let spectralBuffer = enhancer.generateAdvancedDisruption(type: .spectralSweep, duration: 1.0, intensity: 0.5)
        #expect(spectralBuffer != nil, "Should generate spectral sweep via enhancer")
        
        let jitterBuffer = enhancer.generateAdvancedDisruption(type: .temporalJitter, duration: 1.0, intensity: 0.5)
        #expect(jitterBuffer != nil, "Should generate temporal jitter via enhancer")
        
        let whisperBuffer = enhancer.generateAdvancedDisruption(type: .whisperMask, duration: 1.0, intensity: 0.5)
        #expect(whisperBuffer != nil, "Should generate whisper mask via enhancer")
        
        // Test non-advanced type returns nil
        let traditionalBuffer = enhancer.generateAdvancedDisruption(type: .green, duration: 1.0, intensity: 0.5)
        #expect(traditionalBuffer == nil, "Should return nil for traditional noise types")
    }

    // MARK: - Audio Quality Tests

    @Test func testBufferAudioQuality() async throws {
        let processor = AdvancedAudioProcessor()
        let buffer = processor.generateSpectralSweep(duration: 0.1, intensity: 0.5)
        
        guard let buffer = buffer,
              let channelData = buffer.floatChannelData else {
            Issue.record("Failed to get buffer data")
            return
        }
        
        let frameCount = Int(buffer.frameLength)
        
        // Check that buffer contains actual audio data (not just silence)
        var hasNonZeroSamples = false
        for channel in 0..<2 {
            for frame in 0..<min(frameCount, 1000) { // Check first 1000 samples
                if abs(channelData[channel][frame]) > 0.001 {
                    hasNonZeroSamples = true
                    break
                }
            }
            if hasNonZeroSamples { break }
        }
        
        #expect(hasNonZeroSamples, "Buffer should contain non-zero audio samples")
        
        // Check for reasonable amplitude levels (not clipping)
        var maxAmplitude: Float = 0.0
        for channel in 0..<2 {
            for frame in 0..<frameCount {
                maxAmplitude = max(maxAmplitude, abs(channelData[channel][frame]))
            }
        }
        
        #expect(maxAmplitude <= 1.0, "Audio should not clip (exceed ±1.0)")
        #expect(maxAmplitude > 0.0, "Audio should have some amplitude")
    }
}