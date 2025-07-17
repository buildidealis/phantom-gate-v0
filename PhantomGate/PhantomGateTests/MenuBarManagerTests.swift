import XCTest
@testable import PhantomGate

final class MenuBarManagerTests: XCTestCase {
    var menuBarManager: MenuBarManager!
    
    override func setUp() {
        super.setUp()
        menuBarManager = MenuBarManager()
    }
    
    override func tearDown() {
        menuBarManager = nil
        super.tearDown()
    }
    
    func testMenuBarManagerInitialization() {
        XCTAssertNotNil(menuBarManager.statusItem)
        XCTAssertNotNil(menuBarManager.statusItem.button)
        XCTAssertEqual(menuBarManager.isEnabled, false)
    }
    
    func testToggleEnabled() {
        XCTAssertFalse(menuBarManager.isEnabled)
        menuBarManager.toggleEnabled()
        XCTAssertTrue(menuBarManager.isEnabled)
        menuBarManager.toggleEnabled()
        XCTAssertFalse(menuBarManager.isEnabled)
    }
    
    func testMenuItemCount() {
        let menu = menuBarManager.constructMenu()
        // PhantomGate toggle + Shortcut + Feedback + Help + 2 separators
        XCTAssertEqual(menu.items.count, 6)
    }
} 