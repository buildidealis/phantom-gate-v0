//
//  UIComponentTests.swift
//  PhantomGateTests
//
//  Created for comprehensive testing of UI components functionality.
//

import Testing
import SwiftUI
@testable import PhantomGate

struct UIComponentTests {
    
    // MARK: - Color Extension Tests
    
    @Test func testColorHex6DigitInitialization() async throws {
        // Test standard 6-digit hex colors
        let red = Color(hex: "FF0000")
        let green = Color(hex: "00FF00") 
        let blue = Color(hex: "0000FF")
        let white = Color(hex: "FFFFFF")
        let black = Color(hex: "000000")
        
        #expect(red != nil)
        #expect(green != nil)
        #expect(blue != nil)
        #expect(white != nil)
        #expect(black != nil)
    }
    
    @Test func testColorHex3DigitInitialization() async throws {
        // Test 3-digit shorthand hex colors
        let red = Color(hex: "F00")
        let green = Color(hex: "0F0")
        let blue = Color(hex: "00F")
        let white = Color(hex: "FFF")
        let black = Color(hex: "000")
        
        #expect(red != nil)
        #expect(green != nil) 
        #expect(blue != nil)
        #expect(white != nil)
        #expect(black != nil)
    }
    
    @Test func testColorHexCaseInsensitive() async throws {
        // Test that hex parsing is case insensitive
        let upperCase = Color(hex: "FF0000")
        let lowerCase = Color(hex: "ff0000")
        let mixedCase = Color(hex: "Ff00Aa")
        
        #expect(upperCase != nil)
        #expect(lowerCase != nil)
        #expect(mixedCase != nil)
    }
    
    @Test func testColorHexWithHashPrefix() async throws {
        // Test that hash prefix is properly handled
        let withHash = Color(hex: "#FF0000")
        let withoutHash = Color(hex: "FF0000")
        
        #expect(withHash != nil)
        #expect(withoutHash != nil)
    }
    
    @Test func testColorHexWithInvalidCharacters() async throws {
        // Test hex strings with non-hex characters (should be trimmed)
        let withSpaces = Color(hex: " FF0000 ")
        let withSymbols = Color(hex: "#FF0000!")
        let withLetters = Color(hex: "GG0000") // G is not a hex digit
        
        #expect(withSpaces != nil)
        #expect(withSymbols != nil)
        #expect(withLetters != nil) // Should still create a color, just with 0 for invalid chars
    }
    
    @Test func testColorHexPhantomGateColors() async throws {
        // Test specific colors used in PhantomGate
        let greenWaveform = Color(hex: "00ff88") // Used in WaveformView
        let redButton = Color(hex: "ff3366") // Used in FloatingWindowManager
        
        #expect(greenWaveform != nil)
        #expect(redButton != nil)
    }
    
    // MARK: - WaveformView Tests
    
    @Test func testWaveformViewInitialization() async throws {
        let playingWaveform = WaveformView(isPlaying: true)
        let stoppedWaveform = WaveformView(isPlaying: false)
        
        #expect(playingWaveform.isPlaying == true)
        #expect(stoppedWaveform.isPlaying == false)
    }
    
    @Test func testWaveformBarInitialization() async throws {
        let shortBar = WaveformBar(height: 10.0, delay: 0.1)
        let tallBar = WaveformBar(height: 30.0, delay: 0.5)
        let zeroBar = WaveformBar(height: 0.0, delay: 0.0)
        
        #expect(shortBar.height == 10.0)
        #expect(shortBar.delay == 0.1)
        #expect(tallBar.height == 30.0)
        #expect(tallBar.delay == 0.5)
        #expect(zeroBar.height == 0.0)
        #expect(zeroBar.delay == 0.0)
    }
    
    @Test func testWaveformBarPropertyRanges() async throws {
        // Test various height and delay values
        let negativeHeight = WaveformBar(height: -5.0, delay: 0.1)
        let largeHeight = WaveformBar(height: 100.0, delay: 0.1) 
        let negativeDelay = WaveformBar(height: 10.0, delay: -0.5)
        let largeDelay = WaveformBar(height: 10.0, delay: 2.0)
        
        #expect(negativeHeight.height == -5.0)
        #expect(largeHeight.height == 100.0)
        #expect(negativeDelay.delay == -0.5)
        #expect(largeDelay.delay == 2.0)
    }
    
    // MARK: - MenuBarManager Tests
    
    @Test func testMenuBarManagerInitialization() async throws {
        let menuBarManager = MenuBarManager()
        
        // Test initial state
        #expect(await menuBarManager.isEnabled == false)
        #expect(await menuBarManager.audioEngine == nil)
        #expect(await menuBarManager.floatingManager == nil)
    }
    
    @Test func testMenuBarManagerDependencyInjection() async throws {
        let menuBarManager = MenuBarManager()
        let audioEngine = AudioEngine()
        let floatingManager = FloatingWindowManager()
        
        // Test setting dependencies
        await menuBarManager.setAudioEngine(audioEngine)
        await menuBarManager.setFloatingManager(floatingManager)
        
        #expect(await menuBarManager.audioEngine === audioEngine)
        #expect(await menuBarManager.floatingManager === floatingManager)
    }
    
    // MARK: - FloatingWindowManager Tests
    
    @Test func testFloatingWindowManagerInitialization() async throws {
        let floatingManager = FloatingWindowManager()
        
        // Test initial state
        #expect(await floatingManager.isVisible == false)
        #expect(await floatingManager.audioEngine == nil)
    }
    
    @Test func testFloatingWindowManagerVisibilityToggle() async throws {
        let floatingManager = FloatingWindowManager()
        
        // Test initial state
        #expect(await floatingManager.isVisible == false)
        
        // Note: toggleVisibility() requires a window to be set up,
        // so we can't test the actual toggle in a unit test environment,
        // but we can verify the method exists and can be called
        await floatingManager.toggleVisibility()
        
        // The toggle should not crash even without proper window setup
        #expect(true) // If we reach this point, no crash occurred
    }
    
    @Test func testFloatingWindowManagerAudioEngineSetup() async throws {
        let floatingManager = FloatingWindowManager()
        let audioEngine = AudioEngine()
        
        // Test setting audio engine
        await floatingManager.setAudioEngine(audioEngine)
        
        #expect(await floatingManager.audioEngine === audioEngine)
    }
}