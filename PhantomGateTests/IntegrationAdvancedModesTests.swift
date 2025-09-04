//
//  IntegrationAdvancedModesTests.swift
//  PhantomGateTests
//
//  Created by David Jensenius on 2025-09-04.
//

import Testing
@testable import PhantomGate

struct IntegrationAdvancedModesTests {

    // MARK: - End-to-End Integration Tests

    @Test func testCompleteAdvancedModeWorkflow() async throws {
        // Test the complete workflow for advanced modes
        let audioEngine = AudioEngine()
        
        // Test each advanced mode can be selected and configured
        let advancedModes: [NoiseType] = [
            .spectralSweep, .temporalJitter, .whisperMask,
            .pitchFormantDrift, .phaseScramble, .quantizePulse, .rotationCycle
        ]
        
        for mode in advancedModes {
            // Select the mode
            audioEngine.selectEnhancedNoiseType(mode)
            #expect(audioEngine.enhancedNoiseType == mode, "Should select mode \(mode)")
            
            // Configure intensity
            audioEngine.artifactIntensity = 0.7
            #expect(audioEngine.artifactIntensity == 0.7, "Should set intensity")
            
            // Configure volume
            audioEngine.noiseVolume = 0.2
            #expect(audioEngine.noiseVolume == 0.2, "Should set volume")
        }
    }

    @Test func testAdvancedModeUIModelIntegration() async throws {
        // Test that the UI model correctly identifies advanced modes
        let advancedModes: [NoiseType] = [
            .spectralSweep, .temporalJitter, .whisperMask,
            .pitchFormantDrift, .phaseScramble, .quantizePulse, .rotationCycle
        ]
        
        let traditionalModes: [NoiseType] = [
            .green, .pink, .pinkBabble, .ultrasonic, .chatter, .hybrid
        ]
        
        // Verify all advanced modes are distinct from traditional modes
        for advancedMode in advancedModes {
            #expect(!traditionalModes.contains(advancedMode), 
                   "Advanced mode \(advancedMode) should not be in traditional modes")
        }
        
        // Verify all modes have descriptions
        for mode in NoiseType.allCases {
            #expect(!mode.description.isEmpty, "Mode \(mode) should have a description")
            #expect(mode.description.count > 10, "Mode \(mode) description should be descriptive")
        }
    }

    @Test func testAudioEnhancerAdvancedModeRouting() async throws {
        let enhancer = AudioEnhancer()
        
        // Test that advanced modes route to advanced processor
        let spectralBuffer = enhancer.generateAdvancedDisruption(
            type: .spectralSweep, duration: 0.5, intensity: 0.5)
        #expect(spectralBuffer != nil, "Should generate spectral sweep buffer")
        
        let jitterBuffer = enhancer.generateAdvancedDisruption(
            type: .temporalJitter, duration: 0.5, intensity: 0.5)
        #expect(jitterBuffer != nil, "Should generate temporal jitter buffer")
        
        // Test that traditional modes return nil (handled elsewhere)
        let traditionalBuffer = enhancer.generateAdvancedDisruption(
            type: .green, duration: 0.5, intensity: 0.5)
        #expect(traditionalBuffer == nil, "Traditional modes should return nil")
    }

    @Test func testAdvancedModeParameterValidation() async throws {
        let enhancer = AudioEnhancer()
        
        // Test parameter boundaries
        let modes: [NoiseType] = [.spectralSweep, .temporalJitter, .whisperMask]
        
        for mode in modes {
            // Test minimum parameters
            let minBuffer = enhancer.generateAdvancedDisruption(
                type: mode, duration: 0.1, intensity: 0.0)
            #expect(minBuffer != nil, "Should handle minimum parameters for \(mode)")
            
            // Test maximum parameters
            let maxBuffer = enhancer.generateAdvancedDisruption(
                type: mode, duration: 10.0, intensity: 1.0)
            #expect(maxBuffer != nil, "Should handle maximum parameters for \(mode)")
        }
    }

    @Test func testNoiseTypeCountConsistency() async throws {
        // Ensure all noise types are accounted for
        let expectedCount = 13 // 6 traditional + 7 advanced
        let actualCount = NoiseType.allCases.count
        
        #expect(actualCount == expectedCount, 
               "Expected \(expectedCount) noise types, got \(actualCount)")
        
        // Verify specific modes exist
        let requiredModes: [NoiseType] = [
            // Traditional
            .green, .pink, .pinkBabble, .ultrasonic, .chatter, .hybrid,
            // Advanced
            .spectralSweep, .temporalJitter, .whisperMask,
            .pitchFormantDrift, .phaseScramble, .quantizePulse, .rotationCycle
        ]
        
        for mode in requiredModes {
            #expect(NoiseType.allCases.contains(mode), "Should contain mode \(mode)")
        }
    }

    @Test func testAdvancedModeDescriptionsQuality() async throws {
        let advancedModes: [NoiseType] = [
            .spectralSweep, .temporalJitter, .whisperMask,
            .pitchFormantDrift, .phaseScramble, .quantizePulse, .rotationCycle
        ]
        
        for mode in advancedModes {
            let description = mode.description
            
            // Check description quality
            #expect(description.count >= 20, "Description for \(mode) should be descriptive")
            #expect(!description.contains("TODO"), "Description for \(mode) should be complete")
            #expect(!description.isEmpty, "Description for \(mode) should not be empty")
            
            // Check for technical keywords that indicate sophistication
            let hasRelevantKeywords = description.lowercased().contains("disrupts") ||
                                    description.lowercased().contains("formant") ||
                                    description.lowercased().contains("phase") ||
                                    description.lowercased().contains("spectral") ||
                                    description.lowercased().contains("temporal") ||
                                    description.lowercased().contains("whisper") ||
                                    description.lowercased().contains("cycles")
            
            #expect(hasRelevantKeywords, "Description for \(mode) should contain relevant keywords")
        }
    }
}