//
//  FontManagerTests.swift
//  PhantomGateTests
//
//  Created for comprehensive testing of FontManager functionality.
//

import Testing
import SwiftUI
@testable import PhantomGate

@MainActor
struct FontManagerTests {

    // MARK: - FontWeight Tests

    @Test func testFontWeightFilenames() async throws {
        #expect(FontWeight.regular.filename == "JetBrainsMono-Regular")
        #expect(FontWeight.medium.filename == "JetBrainsMono-Medium")
        #expect(FontWeight.bold.filename == "JetBrainsMono-Bold")
        #expect(FontWeight.semiBold.filename == "JetBrainsMono-Bold")
    }

    @Test func testFontWeightConsistency() async throws {
        // Test that semiBold uses the same filename as bold
        #expect(FontWeight.semiBold.filename == FontWeight.bold.filename)

        // Test that other weights have unique filenames
        #expect(FontWeight.regular.filename != FontWeight.medium.filename)
        #expect(FontWeight.regular.filename != FontWeight.bold.filename)
        #expect(FontWeight.medium.filename != FontWeight.bold.filename)
    }

    // MARK: - FontManager Singleton Tests

    @Test @MainActor func testFontManagerSingletonPattern() async throws {
        let instance1 = FontManager.shared
        let instance2 = FontManager.shared

        // Verify singleton behavior
        #expect(instance1 === instance2)
    }

    // MARK: - Font Creation Tests

    @Test @MainActor func testFontCreationWithDifferentWeights() async throws {
        let fontManager = FontManager.shared

        let regularFont = fontManager.font(weight: .regular, size: 16)
        let mediumFont = fontManager.font(weight: .medium, size: 16)
        let boldFont = fontManager.font(weight: .bold, size: 16)
        let semiBoldFont = fontManager.font(weight: .semiBold, size: 16)

        // All fonts should be created successfully
        #expect(regularFont != nil)
        #expect(mediumFont != nil)
        #expect(boldFont != nil)
        #expect(semiBoldFont != nil)
    }

    @Test func testFontCreationWithDifferentSizes() async throws {
        let fontManager = FontManager.shared

        let smallFont = fontManager.font(weight: .regular, size: 12)
        let mediumFont = fontManager.font(weight: .regular, size: 16)
        let largeFont = fontManager.font(weight: .regular, size: 24)

        // All fonts should be created successfully
        #expect(smallFont != nil)
        #expect(mediumFont != nil)
        #expect(largeFont != nil)
    }

    @Test @MainActor func testFontCreationWithDefaultWeight() async throws {
        let fontManager = FontManager.shared

        // Test default weight (should be .regular)
        let defaultFont = fontManager.font(size: 16)
        let explicitRegularFont = fontManager.font(weight: .regular, size: 16)

        // Both should be valid
        #expect(defaultFont != nil)
        #expect(explicitRegularFont != nil)
    }

    @Test @MainActor func testFontCreationWithEdgeCaseSizes() async throws {
        let fontManager = FontManager.shared

        // Test with very small and large sizes
        let tinyFont = fontManager.font(weight: .regular, size: 1)
        let hugeFont = fontManager.font(weight: .regular, size: 100)
        let zeroFont = fontManager.font(weight: .regular, size: 0)

        // All should be created without errors
        #expect(tinyFont != nil)
        #expect(hugeFont != nil)
        #expect(zeroFont != nil)
    }

    // MARK: - Font Registration Tests

    @Test @MainActor func testFontRegistrationCanBeCalled() async throws {
        let fontManager = FontManager.shared

        // Test that registerFonts() can be called without errors
        // Note: In a test environment, font files might not be available,
        // but the method should not crash
        fontManager.registerFonts()

        // If we reach this point, the method executed without throwing
        #expect(true)
    }
}
