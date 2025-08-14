//
//  PhantomGateUITestsLaunchTests.swift
//  PhantomGateUITests
//
//  Created by David Jensenius on 2025-08-07.
//

import XCTest

/*
class PhantomGateUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        // Verify the app is in the correct state for UI testing
        XCTAssert(app.state == .runningForeground, "App should be running in foreground")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchInMenuBarMode() throws {
        let app = XCUIApplication()
        // Don't add --ui-testing to test normal menu bar mode
        app.launch()

        // App should launch successfully in menu bar mode (runs as accessory app in background)
        XCTAssert(app.state == .runningBackground || app.state == .runningForeground,
                 "App should be running in menu bar mode (actual state: \(app.state))")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Menu Bar Launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
*/
