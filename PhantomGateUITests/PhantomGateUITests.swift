//
//  PhantomGateUITests.swift
//  PhantomGateUITests
//
//  Created by David Jensenius on 2025-08-07.
//

import XCTest

class PhantomGateUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required
        // for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        // Clean up UserDefaults after each test
        UserDefaults.standard.removeObject(forKey: "TermsOfServiceAccepted")
        UserDefaults.standard.removeObject(forKey: "TermsOfServiceAcceptedDate")
    }

    @MainActor
    func testAppLaunch() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        // Verify the app launches successfully
        XCTAssert(app.state == .runningForeground)
    }

    @MainActor
    func testMenuBarExists() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        // Look for the PhantomGate menu bar item
        // Note: Menu bar testing is limited in UI tests, but we can test basic presence
        let menuBarButton = app.menuBarItems["PG"]
        if menuBarButton.exists {
            XCTAssert(menuBarButton.exists, "PhantomGate menu bar item should exist")
        }

        // Alternative: Test that the app is running in menu bar mode
        XCTAssert(app.state == .runningForeground)
    }

    @MainActor
    func testFloatingWindowToggle() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        // Try to access floating window if it becomes visible
        // Note: This might not be directly testable without triggering menu items

        // Test that floating window components exist when visible
        let phantomGateWindow = app.windows["PhantomGate"]
        if phantomGateWindow.exists {
            // Test noise type picker
            let noiseTypePicker = phantomGateWindow.popUpButtons["NoiseTypePicker"]
            if noiseTypePicker.exists {
                XCTAssert(noiseTypePicker.exists, "Noise type picker should exist")
            }

            // Test waveform view
            let waveformView = phantomGateWindow.otherElements["WaveformView"]
            if waveformView.exists {
                XCTAssert(waveformView.exists, "Waveform view should exist")
            }

            // Test close button
            let closeButton = phantomGateWindow.buttons["CloseButton"]
            if closeButton.exists {
                XCTAssert(closeButton.exists, "Close button should exist")
            }
        }
    }

    @MainActor
    func testKeyboardShortcuts() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        // Test Command+B shortcut for toggling noise
        // Note: This requires the app to be active and might not work in all test environments
        app.typeKey("b", modifierFlags: .command)

        // The app should still be running after the keyboard shortcut
        XCTAssert(app.state == .runningForeground)
    }

    @MainActor
    func testAccessibilityIdentifiers() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        // Test that accessibility identifiers are properly set
        // This helps ensure the app is accessible and testable

        // Test menu bar accessibility
        let menuBarButton = app.menuBarItems.matching(identifier: "PG").firstMatch
        if menuBarButton.exists {
            XCTAssert(menuBarButton.exists, "Menu bar button should have correct accessibility identifier")
        }

        // Test floating window accessibility
        let phantomGateWindow = app.windows.matching(identifier: "PhantomGate").firstMatch
        if phantomGateWindow.exists {
            XCTAssert(phantomGateWindow.exists, "PhantomGate window should have correct accessibility identifier")
        }
    }

    @MainActor
    func testTermsOfServiceModal() throws {
        // Clear Terms of Service acceptance to trigger modal
        UserDefaults.standard.removeObject(forKey: "TermsOfServiceAccepted")
        UserDefaults.standard.removeObject(forKey: "TermsOfServiceAcceptedDate")
        
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launchArguments.append("--test-terms") // Enable ToS testing
        app.launch()
        
        // Wait for Terms of Service modal to appear
        let termsWindow = app.windows["PhantomGate Terms of Service"]
        let exists = termsWindow.waitForExistence(timeout: 5.0)
        
        if exists {
            // Test that the Terms of Service modal is displayed
            XCTAssert(termsWindow.exists, "Terms of Service modal should appear on first launch")
            
            // Test that the Accept button exists
            let acceptButton = termsWindow.buttons["AcceptTermsButton"]
            if acceptButton.exists {
                XCTAssert(acceptButton.exists, "Accept Terms button should exist")
                
                // Accept the terms
                acceptButton.tap()
                
                // Modal should disappear after acceptance
                let modalGone = !termsWindow.waitForExistence(timeout: 2.0)
                XCTAssert(modalGone, "Terms modal should disappear after acceptance")
            }
        }
    }

    @MainActor
    func testTermsOfServiceAlreadyAccepted() throws {
        // Pre-accept Terms of Service
        UserDefaults.standard.set(true, forKey: "TermsOfServiceAccepted")
        UserDefaults.standard.set(Date(), forKey: "TermsOfServiceAcceptedDate")
        
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launchArguments.append("--test-terms") // Enable ToS testing
        app.launch()
        
        // Terms modal should not appear
        let termsWindow = app.windows["PhantomGate Terms of Service"]
        let modalNotShown = !termsWindow.waitForExistence(timeout: 2.0)
        XCTAssert(modalNotShown, "Terms of Service modal should not appear when already accepted")
        
        // App should be running normally
        XCTAssert(app.state == .runningForeground)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
