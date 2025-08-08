//
//  AsyncTests.swift
//  PhantomGateTests
//
//  Created for testing async functionality and concurrent operations.
//

import Testing
import Foundation
import SwiftUI
import CoreGraphics
@testable import PhantomGate

struct AsyncTests {
    
    // MARK: - Async AudioEngine Tests
    
    @Test func testAudioEngineStopPlaybackWhenStopped() async throws {
        let audioEngine = await MainActor.run { AudioEngine() }
        
        // Verify initial state
        #expect(await audioEngine.isPlaying == false)
        
        // Test that stopping when already stopped doesn't throw
        do {
            try await audioEngine.stopPlayback()
            #expect(await audioEngine.isPlaying == false)
        } catch {
            Issue.record("stopPlayback should not throw when already stopped: \(error)")
        }
    }
    
    @Test func testMultipleStopCallsInSequence() async throws {
        let audioEngine = await MainActor.run { AudioEngine() }
        
        // Test multiple stop calls in sequence
        for _ in 0..<3 {
            do {
                try await audioEngine.stopPlayback()
                #expect(await audioEngine.isPlaying == false)
            } catch {
                Issue.record("Multiple stop calls should not throw: \(error)")
            }
        }
    }
    
    @Test func testConcurrentStopCalls() async throws {
        let audioEngine = await MainActor.run { AudioEngine() }
        
        // Test concurrent stop calls
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    do {
                        try await audioEngine.stopPlayback()
                    } catch {
                        Issue.record("Concurrent stop calls should not throw: \(error)")
                    }
                }
            }
        }
        
        #expect(await audioEngine.isPlaying == false)
    }
    
    @Test func testAudioEngineStateConsistencyAfterAsyncOperations() async throws {
        let audioEngine = await MainActor.run { AudioEngine() }
        
        // Test that state remains consistent after async operations
        let initialPlaying = await audioEngine.isPlaying
        let initialFrequency = await audioEngine.currentFrequency
        
        try await audioEngine.stopPlayback()
        
        #expect(await audioEngine.isPlaying == initialPlaying) // Should remain false
        #expect(await audioEngine.currentFrequency == initialFrequency) // Should remain 0
    }
    
    // MARK: - Task-based Tests
    
    @Test func testAsyncNoiseTypeSelection() async throws {
        let audioEngine = await MainActor.run { AudioEngine() }
        
        // Test noise type selection in async context
        await withTaskGroup(of: Void.self) { group in
            for noiseType in NoiseType.allCases {
                group.addTask {
                    await audioEngine.selectNoiseType(noiseType)
                }
            }
        }
        
        // Should not crash and should remain in stopped state
        #expect(await audioEngine.isPlaying == false)
    }
    
    @Test func testComponentInitializationConcurrency() async throws {
        // Test creating multiple components concurrently
        await withTaskGroup(of: (AudioEngine, MenuBarManager, FloatingWindowManager).self) { group in
            for _ in 0..<3 {
                group.addTask {
                    let audioEngine = await MainActor.run { AudioEngine() }
                    let menuBarManager = await MainActor.run { MenuBarManager() }
                    let floatingManager = await MainActor.run { FloatingWindowManager() }
                    return (audioEngine, menuBarManager, floatingManager)
                }
            }
            
            for await (audioEngine, menuBarManager, floatingManager) in group {
                #expect(await audioEngine.isPlaying == false)
                #expect(await menuBarManager.isEnabled == false)
                #expect(await floatingManager.isVisible == false)
            }
        }
    }
    
    // MARK: - Async State Management Tests
    
    @Test func testAppStateAsyncInitialization() async throws {
        // Test AppState initialization doesn't block
        let startTime = Date()
        let appState = await MainActor.run { AppState() }
        let endTime = Date()
        
        #expect(await appState.isInitialized == true)
        
        // Initialization should be relatively quick
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration < 1.0) // Should take less than 1 second
    }
    
    @Test func testConcurrentFontCreation() async throws {
        let fontManager = FontManager.shared
        
        // Test creating fonts concurrently
        await withTaskGroup(of: Void.self) { group in
            for size in stride(from: 12, through: 24, by: 2) {
                group.addTask {
                    let font = fontManager.font(weight: .regular, size: CGFloat(size))
                    #expect(font != nil)
                }
            }
        }
    }
    
    @Test func testAsyncColorCreation() async throws {
        let hexColors = ["FF0000", "00FF00", "0000FF", "FFFFFF", "000000", "ff3366", "00ff88"]
        
        // Test creating colors concurrently
        await withTaskGroup(of: Void.self) { group in
            for hex in hexColors {
                group.addTask {
                    let color = Color(hex: hex)
                    #expect(color != nil)
                }
            }
        }
    }
}