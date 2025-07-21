//
//  PhantomGate2UITests.swift
//  PhantomGate2UITests
//
//  Created by Mariesa Lenz on 7/17/25.
//

import XCTest

final class PhantomGate2UITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Configure the app for testing
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["UI_TESTING": "1"]
        
        app.launch()
    }
    
    func testBasicAppPresence() throws {
        // Verify menu bar item exists
        let menuExtra = app.menuBars.element(boundBy: 0).menuBarItems["PG"]
        XCTAssertTrue(menuExtra.waitForExistence(timeout: 5), "Menu bar item should exist")
        
        // Basic menu verification
        menuExtra.click()
        XCTAssertTrue(app.menuItems["Enable/Disable"].exists, "Enable/Disable menu item should exist")
        XCTAssertTrue(app.menuItems["Toggle Noise"].exists, "Toggle Noise menu item should exist")
        XCTAssertTrue(app.menuItems["Quit"].exists, "Quit menu item should exist")
    }
}
