import XCTest
@testable import PhantomGate

final class FloatingWindowManagerTests: XCTestCase {
    var floatingManager: FloatingWindowManager!
    
    override func setUp() {
        super.setUp()
        floatingManager = FloatingWindowManager()
    }
    
    override func tearDown() {
        floatingManager = nil
        super.tearDown()
    }
    
    func testWindowInitialization() {
        XCTAssertNotNil(floatingManager.panel)
        XCTAssertEqual(floatingManager.isVisible, false)
    }
    
    func testToggleVisibility() {
        XCTAssertFalse(floatingManager.isVisible)
        floatingManager.toggleVisibility()
        XCTAssertTrue(floatingManager.isVisible)
        floatingManager.toggleVisibility()
        XCTAssertFalse(floatingManager.isVisible)
    }
    
    func testWindowLevel() {
        XCTAssertEqual(floatingManager.panel.level, .floating)
    }
} 