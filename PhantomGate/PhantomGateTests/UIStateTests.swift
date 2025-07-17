import XCTest
@testable import PhantomGate

final class UIStateTests: XCTestCase {
    var menuBarManager: MenuBarManager!
    var floatingManager: FloatingWindowManager!
    
    override func setUp() {
        super.setUp()
        menuBarManager = MenuBarManager()
        floatingManager = FloatingWindowManager()
    }
    
    override func tearDown() {
        menuBarManager = nil
        floatingManager = nil
        super.tearDown()
    }
    
    func testMenuBarState() {
        // Test initial state
        XCTAssertFalse(menuBarManager.isEnabled)
        
        // Test toggle
        menuBarManager.toggleEnabled()
        XCTAssertTrue(menuBarManager.isEnabled)
        
        menuBarManager.toggleEnabled()
        XCTAssertFalse(menuBarManager.isEnabled)
    }
    
    func testFloatingWindowState() {
        // Test initial state
        XCTAssertFalse(floatingManager.isVisible)
        
        // Test visibility toggle
        floatingManager.toggleVisibility()
        XCTAssertTrue(floatingManager.isVisible)
        
        floatingManager.toggleVisibility()
        XCTAssertFalse(floatingManager.isVisible)
    }
    
    func testStateCoordination() {
        // Test that menu bar and floating window states are coordinated
        XCTAssertFalse(menuBarManager.isEnabled)
        XCTAssertFalse(floatingManager.isVisible)
        
        menuBarManager.toggleEnabled()
        floatingManager.toggleVisibility()
        
        XCTAssertTrue(menuBarManager.isEnabled)
        XCTAssertTrue(floatingManager.isVisible)
        
        menuBarManager.toggleEnabled()
        floatingManager.toggleVisibility()
        
        XCTAssertFalse(menuBarManager.isEnabled)
        XCTAssertFalse(floatingManager.isVisible)
    }
    
    func testMenuConstruction() {
        let menu = menuBarManager.constructMenu()
        
        // Test menu structure
        XCTAssertEqual(menu.items.count, 6) // Toggle + Separator + Shortcut + Separator + Feedback + Help
        
        // Test menu item properties
        XCTAssertEqual(menu.items[0].title, "PhantomGate")
        XCTAssertTrue(menu.items[1].isSeparatorItem)
        XCTAssertEqual(menu.items[2].title, "Enable/Disable (⌘M)")
        XCTAssertTrue(menu.items[3].isSeparatorItem)
        XCTAssertEqual(menu.items[4].title, "Submit feedback")
        XCTAssertEqual(menu.items[5].title, "Help")
    }
    
    func testKeyboardShortcut() {
        let menu = menuBarManager.constructMenu()
        let shortcutItem = menu.items[2]
        
        XCTAssertEqual(shortcutItem.keyEquivalent, "m")
        XCTAssertEqual(shortcutItem.keyEquivalentModifierMask, .command)
    }
} 