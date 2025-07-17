import XCTest
import AVFoundation
@testable import PhantomGate

final class AudioEngineTests: XCTestCase {
    var audioEngine: AudioEngine!
    
    override func setUp() {
        super.setUp()
        audioEngine = AudioEngine()
    }
    
    override func tearDown() {
        audioEngine = nil
        super.tearDown()
    }
    
    func testAudioEngineInitialization() {
        XCTAssertNotNil(audioEngine.engine)
        XCTAssertNotNil(audioEngine.mainMixer)
        XCTAssertFalse(audioEngine.isPlaying)
    }
    
    func testNoiseTypeSelection() {
        XCTAssertEqual(audioEngine.currentNoiseType, .green)
        audioEngine.selectNoiseType(.pink)
        XCTAssertEqual(audioEngine.currentNoiseType, .pink)
        audioEngine.selectNoiseType(.pinkBabble)
        XCTAssertEqual(audioEngine.currentNoiseType, .pinkBabble)
    }
    
    func testPlayStop() async {
        XCTAssertFalse(audioEngine.isPlaying)
        
        await audioEngine.startPlayback()
        XCTAssertTrue(audioEngine.isPlaying)
        
        await audioEngine.stopPlayback()
        XCTAssertFalse(audioEngine.isPlaying)
    }
} 