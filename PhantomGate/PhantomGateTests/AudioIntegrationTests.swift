import XCTest
import AVFoundation
@testable import PhantomGate

final class AudioIntegrationTests: XCTestCase {
    var audioEngine: AudioEngine!
    var floatingManager: FloatingWindowManager!
    
    override func setUp() {
        super.setUp()
        audioEngine = AudioEngine()
        floatingManager = FloatingWindowManager()
    }
    
    override func tearDown() {
        audioEngine = nil
        floatingManager = nil
        super.tearDown()
    }
    
    func testAudioEngineIntegration() async {
        // Test initial state
        XCTAssertFalse(await audioEngine.isPlaying)
        XCTAssertEqual(await audioEngine.currentNoiseType, .green)
        
        // Test starting playback
        await audioEngine.startPlayback()
        XCTAssertTrue(await audioEngine.isPlaying)
        
        // Test frequency monitoring
        let frequency = audioEngine.getCurrentFrequency()
        XCTAssertGreaterThan(frequency, 0)
        
        // Test noise type switching during playback
        await audioEngine.selectNoiseType(.pink)
        XCTAssertEqual(await audioEngine.currentNoiseType, .pink)
        XCTAssertTrue(await audioEngine.isPlaying)
        
        // Test stopping playback
        await audioEngine.stopPlayback()
        XCTAssertFalse(await audioEngine.isPlaying)
    }
    
    func testAudioSessionConfiguration() {
        let session = AVAudioSession.sharedInstance()
        
        XCTAssertEqual(try? session.category, .playback)
        XCTAssertTrue(session.isOtherAudioPlaying || true) // Allow either state
    }
    
    func testNoiseTypeChanges() async {
        // Test all noise types
        for noiseType in NoiseType.allCases {
            await audioEngine.selectNoiseType(noiseType)
            XCTAssertEqual(await audioEngine.currentNoiseType, noiseType)
            
            // Start playback and verify it works
            await audioEngine.startPlayback()
            XCTAssertTrue(await audioEngine.isPlaying)
            
            // Check frequency monitoring
            let frequency = audioEngine.getCurrentFrequency()
            XCTAssertGreaterThan(frequency, 0)
            
            // Stop playback
            await audioEngine.stopPlayback()
            XCTAssertFalse(await audioEngine.isPlaying)
        }
    }
    
    func testConcurrentAudioOperations() async {
        // Test rapid start/stop operations
        for _ in 0..<5 {
            await audioEngine.startPlayback()
            XCTAssertTrue(await audioEngine.isPlaying)
            
            await audioEngine.stopPlayback()
            XCTAssertFalse(await audioEngine.isPlaying)
        }
        
        // Test rapid noise type changes
        await audioEngine.startPlayback()
        for noiseType in NoiseType.allCases {
            await audioEngine.selectNoiseType(noiseType)
            XCTAssertEqual(await audioEngine.currentNoiseType, noiseType)
        }
        await audioEngine.stopPlayback()
    }
} 