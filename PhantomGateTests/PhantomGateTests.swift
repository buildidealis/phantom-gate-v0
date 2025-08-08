//
//  PhantomGateTests.swift
//  PhantomGateTests
//
//  Created by David Jensenius on 2025-08-07.
//

import Testing
import SwiftUI
@testable import PhantomGate

struct PhantomGateTests {

    // MARK: - Basic Smoke Tests
    
    @Test func testBasicImports() async throws {
        // Verify that the main modules can be imported and basic types exist
        let noiseType: NoiseType = .green
        let fontWeight: FontWeight = .regular
        let audioError = AudioEngineError.formatCreationFailed
        
        #expect(noiseType.rawValue == "Green noise")
        #expect(fontWeight.filename == "JetBrainsMono-Regular")
        
        // Verify error types exist
        switch audioError {
        case .formatCreationFailed:
            break // Expected
        default:
            Issue.record("Unexpected error type")
        }
    }
    
    @Test func testBasicComponentCreation() async throws {
        // Test that basic components can be created without errors
        let audioEngine = AudioEngine()
        let menuBarManager = MenuBarManager()
        let floatingManager = FloatingWindowManager()
        let fontManager = FontManager.shared
        
        #expect(audioEngine != nil)
        #expect(menuBarManager != nil)
        #expect(floatingManager != nil)
        #expect(fontManager != nil)
    }
    
    @Test func testBasicUIComponents() async throws {
        // Test that UI components can be created
        let waveformView = WaveformView(isPlaying: false)
        let waveformBar = WaveformBar(height: 10.0, delay: 0.1)
        let color = Color(hex: "FF0000")
        
        #expect(waveformView.isPlaying == false)
        #expect(waveformBar.height == 10.0)
        #expect(color != nil)
    }
    
    @Test func testAppStateBasics() async throws {
        // Test that the main app state can be created
        let appState = AppState()
        
        #expect(await appState.isInitialized == true)
        #expect(await appState.audioEngine != nil)
        #expect(await appState.menuBarManager != nil)
        #expect(await appState.floatingManager != nil)
    }

}
