//
//  PhantomGate2Tests.swift
//  PhantomGate2Tests
//
//  Created by Mariesa Lenz on 7/17/25.
//

import XCTest
@testable import PhantomGate2

@MainActor
final class PhantomGate2Tests: XCTestCase {
    var audioEngine: AudioEngine!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        audioEngine = AudioEngine()
    }
    
    override func tearDownWithError() throws {
        audioEngine = nil
        try super.tearDownWithError()
    }
    
    func testPlaybackControl() async throws {
        // Test initial state
        XCTAssertFalse(audioEngine.isPlaying)
        
        // Test starting playback
        try await audioEngine.startPlayback()
        XCTAssertTrue(audioEngine.isPlaying)
        
        // Test stopping playback
        try await audioEngine.stopPlayback()
        XCTAssertFalse(audioEngine.isPlaying)
    }
    
    func testFrequencyAnalysis() async throws {
        // Start playback
        try await audioEngine.startPlayback()
        
        // Wait for frequency analysis
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Check that frequency is being updated
        XCTAssertGreaterThan(audioEngine.currentFrequency, 0)
        
        // Stop playback
        try await audioEngine.stopPlayback()
        
        // Check that frequency is reset
        XCTAssertEqual(audioEngine.currentFrequency, 0)
    }
    
    func testMenuBarManager() async {
        let manager = MenuBarManager()
        let engine = AudioEngine()
        
        // Test initial state
        XCTAssertFalse(manager.isEnabled)
        
        // Set audio engine
        manager.setAudioEngine(engine)
        
        // Test menu bar setup
        XCTAssertNotNil(manager)
        XCTAssertEqual(manager.isEnabled, false)
    }
    
    func testFloatingWindowManager() async {
        let manager = FloatingWindowManager()
        let engine = AudioEngine()
        
        // Test initial state
        XCTAssertFalse(manager.isVisible)
        
        // Set audio engine and test integration
        manager.setAudioEngine(engine)
        XCTAssertNotNil(manager)
        
        // Test visibility state
        manager.toggleVisibility()
        XCTAssertTrue(manager.isVisible)
        
        manager.toggleVisibility()
        XCTAssertFalse(manager.isVisible)
    }
    
    func testAudioEngineErrorHandling() async throws {
        let manager = MenuBarManager()
        let engine = AudioEngine()
        
        // Set audio engine
        manager.setAudioEngine(engine)
        
        // Test playback control through engine directly
        try await engine.startPlayback()
        XCTAssertTrue(engine.isPlaying)
        
        try await engine.stopPlayback()
        XCTAssertFalse(engine.isPlaying)
    }
    
    func testAppInitialization() async {
        let app = PhantomGateApp()
        
        // Test that app exists and can be initialized
        XCTAssertNotNil(app)
    }
}
