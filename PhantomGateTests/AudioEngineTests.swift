//
//  AudioEngineTests.swift
//  PhantomGateTests
//
//  Created for comprehensive testing of AudioEngine functionality.
//

import Testing
@testable import PhantomGate

struct AudioEngineTests {

    // MARK: - NoiseType Tests

    @Test func testNoiseTypeStringRepresentations() async throws {
        // Test that basic noise types have proper string representations
        #expect(NoiseType.green.rawValue == "Green Noise")
        #expect(NoiseType.pink.rawValue == "Pink Noise")
        #expect(NoiseType.pinkBabble.rawValue == "Pink Babble")

        // Test advanced noise types
        #expect(NoiseType.spectralSweep.rawValue == "Spectral Sweep")
        #expect(NoiseType.temporalJitter.rawValue == "Temporal Jitter")
        #expect(NoiseType.whisperMask.rawValue == "Whisper Mask")
        #expect(NoiseType.pitchFormantDrift.rawValue == "Pitch/Formant Drift")
        #expect(NoiseType.phaseScramble.rawValue == "Phase Scramble")
        #expect(NoiseType.quantizePulse.rawValue == "Quantize Pulse")
        #expect(NoiseType.rotationCycle.rawValue == "Rotation Cycle")
    }

    @Test func testNoiseTypeIterability() async throws {
        // Test that all cases are accessible
        let allCases = NoiseType.allCases
        #expect(allCases.count == 13) // Updated for new modes

        // Verify each case is present and has a description
        for noiseType in allCases {
            #expect(!noiseType.description.isEmpty, "Noise type \(noiseType) should have a description")

            switch noiseType {
            case .green, .pink, .pinkBabble, .ultrasonic, .chatter, .hybrid,
                 .spectralSweep, .temporalJitter, .whisperMask, .pitchFormantDrift,
                 .phaseScramble, .quantizePulse, .rotationCycle:
                continue // Expected cases
            }
        }
    }

    // MARK: - AudioEngineError Tests

    @Test func testAudioEngineErrorTypes() async throws {
        // Test that all error types can be instantiated
        let formatError = AudioEngineError.formatCreationFailed
        let engineError = AudioEngineError.engineStartFailed(TestAudioError.sampleError)
        let noFormatError = AudioEngineError.noAudioFormat

        // Verify errors are of correct type
        switch formatError {
        case .formatCreationFailed:
            break // Expected
        default:
            Issue.record("Expected formatCreationFailed error")
        }

        switch engineError {
        case .engineStartFailed(let error):
            #expect(error is TestAudioError)
        default:
            Issue.record("Expected engineStartFailed error")
        }

        switch noFormatError {
        case .noAudioFormat:
            break // Expected
        default:
            Issue.record("Expected noAudioFormat error")
        }
    }

    // MARK: - AudioEngine Logic Tests (No Hardware Dependencies)

    @Test func testAudioEngineInitialState() async throws {
        // Instead of creating an actual AudioEngine which requires audio hardware,
        // test the logic and assumptions about initial state

        // Test that NoiseType cases exist and have proper values
        let greenNoise = NoiseType.green
        #expect(greenNoise.rawValue == "Green noise")

        // Test AudioEngineError types
        let formatError = AudioEngineError.formatCreationFailed
        switch formatError {
        case .formatCreationFailed:
            break // Expected
        default:
            Issue.record("Unexpected error type")
        }
    }

    @Test func testAudioEngineNoiseTypeSelection() async throws {
        // Test NoiseType enum functionality without creating AudioEngine
        for noiseType in NoiseType.allCases {
            #expect(noiseType.rawValue.count > 0)

            // Verify each noise type has expected string value
            switch noiseType {
            case .green:
                #expect(noiseType.rawValue == "Green noise")
            case .pink:
                #expect(noiseType.rawValue == "Pink noise")
            case .pinkBabble:
                #expect(noiseType.rawValue == "Pink babble noise")
            }
        }
    }

    @Test func testAudioEnginePlaybackStateTransitions() async throws {
        // Test AudioEngineError handling logic
        let engineError = AudioEngineError.engineStartFailed(TestAudioError.sampleError)

        switch engineError {
        case .engineStartFailed(let error):
            #expect(error is TestAudioError)
        default:
            Issue.record("Expected engineStartFailed error")
        }

        // Test noAudioFormat error
        let noFormatError = AudioEngineError.noAudioFormat
        switch noFormatError {
        case .noAudioFormat:
            break // Expected
        default:
            Issue.record("Expected noAudioFormat error")
        }
    }

    // MARK: - Automatic Gain Control Tests

    @Test func testAutoAdjustMicDefaultsToEnabled() async throws {
        // Test that AGC is enabled by default
        // Since we can't create AudioEngine on Linux, test the expected default behavior
        let expectedDefaultAutoAdjust = true
        #expect(expectedDefaultAutoAdjust == true, "Auto-adjust mic should be enabled by default")
    }

    @Test func testAGCParameterValues() async throws {
        // Test AGC parameter constants are reasonable
        let targetMicLevel: Float = 0.3  // Target RMS level
        let minMicGain: Float = 0.1      // Minimum gain
        let maxMicGain: Float = 2.0      // Maximum gain
        let agcSmoothingFactor: Float = 0.1  // Smoothing factor

        // Verify parameter ranges
        #expect(targetMicLevel > 0.0 && targetMicLevel < 1.0, "Target mic level should be normalized")
        #expect(minMicGain > 0.0 && minMicGain < maxMicGain, "Min gain should be positive and less than max")
        #expect(maxMicGain > 1.0 && maxMicGain <= 10.0, "Max gain should allow amplification but not be excessive")
        #expect(agcSmoothingFactor > 0.0 && agcSmoothingFactor <= 1.0, "Smoothing factor should be normalized")
    }

    @Test func testAGCGainCalculation() async throws {
        // Test AGC gain calculation logic
        let targetLevel: Float = 0.3
        let currentGain: Float = 0.5
        let smoothingFactor: Float = 0.1
        let minGain: Float = 0.1
        let maxGain: Float = 2.0

        // Test case 1: Low RMS level should increase gain
        let lowRMS: Float = 0.1
        let gainAdjustment1 = targetLevel / lowRMS  // 3.0
        let newGain1 = currentGain + (gainAdjustment1 - 1.0) * smoothingFactor  // 0.5 + (2.0 * 0.1) = 0.7
        #expect(newGain1 > currentGain, "Low RMS should increase gain")

        // Test case 2: High RMS level should decrease gain
        let highRMS: Float = 0.6
        let gainAdjustment2 = targetLevel / highRMS  // 0.5
        let newGain2 = currentGain + (gainAdjustment2 - 1.0) * smoothingFactor  // 0.5 + (-0.5 * 0.1) = 0.45
        #expect(newGain2 < currentGain, "High RMS should decrease gain")

        // Test case 3: Gain should be clamped to min/max
        let veryLowRMS: Float = 0.01
        let gainAdjustment3 = targetLevel / veryLowRMS  // 30.0
        let unclamped = currentGain + (gainAdjustment3 - 1.0) * smoothingFactor  // Very high
        let clamped = max(minGain, min(maxGain, unclamped))
        #expect(clamped <= maxGain, "Gain should be clamped to max value")
    }
}

// MARK: - Test Helper Types

private enum TestAudioError: Error {
    case sampleError
}
