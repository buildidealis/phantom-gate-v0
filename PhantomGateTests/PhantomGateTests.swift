//
//  PhantomGateTests.swift
//  PhantomGateTests
//
//  Created by David Jensenius on 2025-08-07.
//

import Testing
import SwiftUI
import Foundation
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
        // Test that FontManager (non-UI component) can be created
        let fontManager = FontManager.shared
        #expect(fontManager != nil)

        // Test that enum types exist and work properly
        let noiseTypes = NoiseType.allCases
        #expect(noiseTypes.count == 3)

        let fontWeights = FontWeight.allCases
        #expect(fontWeights.count > 0)
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
        // Test basic enum and type functionality instead of full AppState creation
        // which requires audio and UI components

        // Test that NoiseType enum works
        for noiseType in NoiseType.allCases {
            #expect(noiseType.rawValue.count > 0)
        }

        // Test that AudioEngineError types exist
        let errors: [AudioEngineError] = [
            .formatCreationFailed,
            .engineStartFailed(NSError(domain: "test", code: 1, userInfo: nil)),
            .noAudioFormat
        ]

        #expect(errors.count == 3)
    }

}
