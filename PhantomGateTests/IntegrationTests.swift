//
//  IntegrationTests.swift
//  PhantomGateTests
//
//  Created for integration and edge case testing.
//

import Testing
import SwiftUI
@testable import PhantomGate

struct IntegrationTests {
    
    // MARK: - App State Integration Tests
    
    @Test func testAppStateInitialization() async throws {
        let appState = AppState()
        
        // Test that all components are properly initialized
        #expect(appState.audioEngine != nil)
        #expect(appState.menuBarManager != nil)
        #expect(appState.floatingManager != nil)
        #expect(appState.isInitialized == true)
    }
    
    @Test func testAppStateDependencyWiring() async throws {
        let appState = AppState()
        
        // Test that dependencies are properly wired
        #expect(appState.menuBarManager.audioEngine === appState.audioEngine)
        #expect(appState.menuBarManager.floatingManager === appState.floatingManager)
        #expect(appState.floatingManager.audioEngine === appState.audioEngine)
    }
    
    // MARK: - Component Interaction Tests
    
    @Test func testMenuBarManagerFloatingManagerInteraction() async throws {
        let menuBarManager = MenuBarManager()
        let floatingManager = FloatingWindowManager()
        
        menuBarManager.setFloatingManager(floatingManager)
        
        // Initial states
        #expect(menuBarManager.isEnabled == false)
        #expect(floatingManager.isVisible == false)
        
        // Note: Actual UI interaction testing would require AppKit to be available
        // In a real test environment with UI, we would test the toggle functionality
    }
    
    @Test func testAudioEngineMenuBarManagerInteraction() async throws {
        let menuBarManager = MenuBarManager()
        let audioEngine = AudioEngine()
        
        menuBarManager.setAudioEngine(audioEngine)
        
        // Verify the audio engine is properly set
        #expect(menuBarManager.audioEngine === audioEngine)
        
        // Test initial audio state
        #expect(audioEngine.isPlaying == false)
    }
    
    // MARK: - Edge Case Tests
    
    @Test func testMultipleAudioEngineInstances() async throws {
        let engine1 = AudioEngine()
        let engine2 = AudioEngine()
        
        // Test that multiple instances can coexist
        #expect(engine1.isPlaying == false)
        #expect(engine2.isPlaying == false)
        #expect(engine1 !== engine2) // Different instances
    }
    
    @Test func testAudioEngineStateConsistency() async throws {
        let audioEngine = AudioEngine()
        
        // Test initial state consistency
        #expect(audioEngine.isPlaying == false)
        #expect(audioEngine.currentFrequency == 0.0)
        
        // Test noise type selection consistency
        for noiseType in NoiseType.allCases {
            audioEngine.selectNoiseType(noiseType)
            // State should remain consistent
            #expect(audioEngine.isPlaying == false)
            #expect(audioEngine.currentFrequency == 0.0)
        }
    }
    
    @Test func testColorHexEdgeCases() async throws {
        // Test empty and malformed hex strings
        let emptyColor = Color(hex: "")
        let shortColor = Color(hex: "F")
        let longColor = Color(hex: "FF00001122") // Too long
        let justHashColor = Color(hex: "#")
        
        // These should not crash, even if they produce default colors
        #expect(emptyColor != nil)
        #expect(shortColor != nil)
        #expect(longColor != nil)
        #expect(justHashColor != nil)
    }
    
    @Test func testFontManagerMemoryConsistency() async throws {
        let manager1 = FontManager.shared
        let manager2 = FontManager.shared
        
        // Create fonts from both references
        let font1 = manager1.font(weight: .bold, size: 16)
        let font2 = manager2.font(weight: .bold, size: 16)
        
        // Both should work since they're the same singleton
        #expect(font1 != nil)
        #expect(font2 != nil)
        #expect(manager1 === manager2)
    }
    
    // MARK: - Concurrency Safety Tests
    
    @Test func testAudioEngineAsyncOperations() async throws {
        let audioEngine = AudioEngine()
        
        // Test that async operations can be called without immediate errors
        do {
            try await audioEngine.stopPlayback() // Should not error when already stopped
            #expect(audioEngine.isPlaying == false)
        } catch {
            Issue.record("stopPlayback should not throw when already stopped: \(error)")
        }
    }
    
    @Test func testMultipleFontCreationCalls() async throws {
        let fontManager = FontManager.shared
        
        // Test creating many fonts rapidly
        let fonts = (0..<10).map { index in
            fontManager.font(weight: .regular, size: CGFloat(12 + index))
        }
        
        // All fonts should be created successfully
        for font in fonts {
            #expect(font != nil)
        }
        #expect(fonts.count == 10)
    }
    
    // MARK: - Performance Consideration Tests
    
    @Test func testWaveformViewMultipleInstances() async throws {
        // Test creating multiple waveform views
        let waveforms = (0..<5).map { index in
            WaveformView(isPlaying: index % 2 == 0)
        }
        
        #expect(waveforms.count == 5)
        #expect(waveforms[0].isPlaying == true)
        #expect(waveforms[1].isPlaying == false)
        #expect(waveforms[2].isPlaying == true)
        #expect(waveforms[3].isPlaying == false)
        #expect(waveforms[4].isPlaying == true)
    }
    
    @Test func testWaveformBarVariations() async throws {
        // Test various waveform bar configurations
        let minHeightBar = WaveformBar(height: 4.0, delay: 0.0)
        let maxHeightBar = WaveformBar(height: 30.0, delay: 0.7)
        let midHeightBar = WaveformBar(height: 17.0, delay: 0.35)
        
        #expect(minHeightBar.height == 4.0)
        #expect(maxHeightBar.height == 30.0)
        #expect(midHeightBar.height == 17.0)
        
        #expect(minHeightBar.delay == 0.0)
        #expect(maxHeightBar.delay == 0.7)
        #expect(midHeightBar.delay == 0.35)
    }
}