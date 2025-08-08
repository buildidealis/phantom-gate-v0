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
        // Test that noise types have proper string representations
        #expect(NoiseType.green.rawValue == "Green noise")
        #expect(NoiseType.pink.rawValue == "Pink noise")
        #expect(NoiseType.pinkBabble.rawValue == "Pink babble noise")
    }
    
    @Test func testNoiseTypeIterability() async throws {
        // Test that all cases are accessible
        let allCases = NoiseType.allCases
        #expect(allCases.count == 3)
        
        // Verify each case is present
        for noiseType in allCases {
            switch noiseType {
            case .green, .pink, .pinkBabble:
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
    
    // MARK: - AudioEngine Basic Tests
    
    @Test func testAudioEngineInitialState() async throws {
        let audioEngine = AudioEngine()
        
        // Test initial state
        #expect(await audioEngine.isPlaying == false)
        #expect(await audioEngine.currentFrequency == 0.0)
    }
    
    @Test func testAudioEngineNoiseTypeSelection() async throws {
        let audioEngine = AudioEngine()
        
        // Test that noise type selection doesn't crash when not playing
        for noiseType in NoiseType.allCases {
            await audioEngine.selectNoiseType(noiseType)
            // Should remain in non-playing state
            #expect(await audioEngine.isPlaying == false)
        }
    }
    
    @Test func testAudioEnginePlaybackStateTransitions() async throws {
        let audioEngine = AudioEngine()
        
        // Test initial state
        #expect(await audioEngine.isPlaying == false)
        
        // Test that multiple stop calls don't cause issues
        do {
            try await audioEngine.stopPlayback()
            try await audioEngine.stopPlayback()
            #expect(await audioEngine.isPlaying == false)
        } catch {
            // StopPlayback should not throw when already stopped
            Issue.record("stopPlayback should not throw when already stopped: \(error)")
        }
    }
}

// MARK: - Test Helper Types

private enum TestAudioError: Error {
    case sampleError
}