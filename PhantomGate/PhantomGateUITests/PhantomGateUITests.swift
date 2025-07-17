//
//  PhantomGateUITests.swift
//  PhantomGateUITests
//
//  Created by Mariesa Lenz on 7/14/25.
//

import XCTest

final class PhantomGateUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testMenuBarIconExists() throws {
        // Note: Menu bar items are not directly accessible through XCTest
        // This is a limitation of the testing framework
        // Manual testing required for menu bar functionality
    }
    
    func testFloatingWindowVisibility() throws {
        // Find the window by its title
        let window = app.windows["PhantomGate"]
        XCTAssertTrue(window.exists)
        
        // Check initial state
        XCTAssertTrue(window.isEnabled)
    }
    
    func testNoiseTypeSelection() throws {
        let window = app.windows["PhantomGate"]
        let picker = window.popUpButtons.firstMatch
        
        XCTAssertTrue(picker.exists)
        picker.click()
        
        // Test each noise type option exists
        let noiseTypes = ["Green noise", "Pink noise", "Pink babble noise"]
        for noiseType in noiseTypes {
            XCTAssertTrue(picker.menuItems[noiseType].exists)
        }
    }
    
    func testScrambleButton() throws {
        let window = app.windows["PhantomGate"]
        let button = window.buttons["Start scramble"]
        
        XCTAssertTrue(button.exists)
        button.click()
        
        // Button should change to "Stop scramble"
        let stopButton = window.buttons["Stop scramble"]
        XCTAssertTrue(stopButton.exists)
        
        // Verify dropdown is disabled while playing
        let picker = window.popUpButtons.firstMatch
        XCTAssertFalse(picker.isEnabled)
        
        stopButton.click()
        
        // Button should change back to "Start scramble"
        XCTAssertTrue(button.exists)
        
        // Verify dropdown is enabled after stopping
        XCTAssertTrue(picker.isEnabled)
    }
    
    func testWaveformVisualization() throws {
        let window = app.windows["PhantomGate"]
        let button = window.buttons["Start scramble"]
        
        button.click()
        
        // Check if frequency display appears
        let frequencyText = window.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Hz'")).firstMatch
        XCTAssertTrue(frequencyText.exists)
        
        // Stop playback
        window.buttons["Stop scramble"].click()
    }
}
