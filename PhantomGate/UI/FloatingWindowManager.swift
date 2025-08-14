import SwiftUI
import AppKit

@MainActor
class FloatingWindowManager: ObservableObject {
    @Published private(set) var isVisible = false {
        didSet { isVisible ? showWindow() : hideWindow() }
    }

    private var window: NSWindow?
    private(set) var audioEngine: AudioEngine?

    // Track last size to avoid jitter
    private var lastSize: CGSize = .zero

    init() {
        setupWindow()
    }

    private func setupWindow() {
        // Provisional size just for initial placement & appearance; will be replaced.
        let provisionalSize = NSSize(width: 300, height: 200)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: provisionalSize),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = false
        window.setAccessibilityIdentifier("PhantomGate")
        window.title = "PhantomGate"

        // Initial top-right placement
        if let screen = NSScreen.main?.visibleFrame {
            let origin = NSPoint(
                x: screen.maxX - provisionalSize.width - 20,
                y: screen.minY + 20
            )
            window.setFrameOrigin(origin)
        }

        self.window = window
    }

    func setAudioEngine(_ engine: AudioEngine) {
        audioEngine = engine
        setupContentView()
    }

    private func setupContentView() {
        guard let window else { return }
        let root = FloatingControlView(manager: self)
        let hosting = NSHostingView(rootView: root.fixedSize()) // fixedSize to hug content
        window.contentView = hosting

        // This is breaking in Swift 6 / iOS 26
        /*
        DispatchQueue.main.async { [weak self, weak hosting] in
            guard let self, let hosting, self.window != nil else { return }
            self.applySize(hosting.fittingSize, anchorTopRight: true, animated: false)
        }
         */
    }

    func resize(to newContentSize: CGSize) {
        // Filter out zero / trivial changes
        if newContentSize.width < 5 || newContentSize.height < 5 { return }
        if abs(newContentSize.width - lastSize.width) < 1 &&
            abs(newContentSize.height - lastSize.height) < 1 { return }
        applySize(newContentSize, anchorTopRight: true, animated: true)
    }

    private func applySize(_ size: CGSize, anchorTopRight: Bool, animated: Bool) {
        guard let window else { return }

        // Clamp to sensible minimums
        let minWidth: CGFloat = 200
        let minHeight: CGFloat = 120
        var target = size
        target.width = max(target.width, minWidth)
        target.height = max(target.height, minHeight)

        lastSize = target

        var frame = window.frame
        if anchorTopRight {
            // Adjust origin so top-right corner stays fixed
            let deltaW = target.width - frame.width
            let deltaH = target.height - frame.height
            frame.origin.x -= deltaW
            frame.origin.y -= deltaH
        }
        frame.size = target
        window.setFrame(frame, display: true, animate: animated)
    }

    private func showWindow() {
        window?.orderFront(nil)
    }

    private func hideWindow() {
        window?.orderOut(nil)
    }

    func toggleVisibility() {
        guard window != nil else { return }
        isVisible.toggle()
    }
}

// MARK: - Protocol for Audio Level Provider

protocol AudioLevelProvider {
    func getAudioLevels() -> [CGFloat]
}

// MARK: - SwiftUI Content

struct FloatingControlView: View {
    @ObservedObject var manager: FloatingWindowManager
    @State private var selectedNoiseType: NoiseType = .green
    @State private var isPlaying = false
    @State private var currentFrequency: Float = 0
    @State private var frequencyStreamError: Error?
    @State private var frequencyTask: Task<Void, Never>?

    var body: some View {
        content
            .padding(16)
            // Ensure the view reports its natural size (no expansion)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 6)
            )
            // If you prefer a macOS material look instead, replace the above with:
            // .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            // .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
            .fixedSize(horizontal: true, vertical: true) // Hug content
            // Measure AFTER background so size includes padding & shape
            .overlay(SizeReader { manager.resize(to: $0) })
    }

    private var content: some View {
        VStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("PhantomGate")
                        .font(FontManager.shared.font(weight: .bold, size: 48))
                        .foregroundColor(Color.phantomGreen)
                    Spacer()
                    Button(
                        action: { manager.toggleVisibility() },
                        label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .accessibilityIdentifier("CloseButton")
                        }
                    )
                    .environment(\.colorScheme, .dark)
                }

                Text("Select broadband interference option:")
                    .font(FontManager.shared.font(weight: .medium, size: 14))
                    .foregroundColor(.white)

                Picker("", selection: $selectedNoiseType) {
                    ForEach(NoiseType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .disabled(isPlaying)
                .accessibilityIdentifier("NoiseTypePicker")
                .accessibilityLabel("Select broadband interface option")
                .onChange(of: selectedNoiseType) { _, newValue in
                    guard let engine = manager.audioEngine else { return }
                    Task { engine.selectNoiseType(newValue) }
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    if isPlaying {
                        HStack {
                            // Pass the audio engine to WaveformView for real audio data
                            if let audioEngine = manager.audioEngine as? AudioLevelProvider {
                                WaveformView(isPlaying: isPlaying, audioLevelProvider: audioEngine)
                                    .frame(width: 100)
                                    .accessibilityIdentifier("WaveformView")
                            } else {
                                // Fallback to original behavior if no audio engine
                                WaveformView(isPlaying: isPlaying)
                                    .frame(width: 100)
                                    .accessibilityIdentifier("WaveformView")
                            }

                            if isPlaying {
                                Text(String(format: "%.1f kHz", currentFrequency / 1000))
                                    .font(FontManager.shared.font(weight: .medium, size: 12))
                                    .foregroundColor(.white)
                                    .accessibilityIdentifier("FrequencyLabel")
                            }
                        }
                    }
                    Button(action: togglePlayback) {
                        Text(isPlaying ? "Stop scramble" : "Start scramble")
                            .font(FontManager.shared.font(weight: .medium, size: 14))
                            .foregroundColor(
                                isPlaying ? .phantomRed : .phantomGreen
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .accessibilityIdentifier("TogglePlaybackButton")
                    .disabled(manager.audioEngine == nil)
                    .environment(\.colorScheme, .dark)
                }
            }
        }
        .onChange(of: isPlaying) { _, newValue in
            if newValue {
                startFrequencyMonitoring()
            } else {
                frequencyTask?.cancel()
                frequencyTask = nil
            }
        }
    }

    private func startFrequencyMonitoring() {
        guard let engine = manager.audioEngine else { return }

        frequencyTask?.cancel()
        frequencyTask = Task {
            let stream = AsyncStream(Float.self) { continuation in
                Task {
                    while !Task.isCancelled {
                        continuation.yield(engine.currentFrequency)
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                    continuation.finish()
                }
            }

            for await frequency in stream {
                guard !Task.isCancelled else { break }
                currentFrequency = frequency
            }
        }
    }

    private func togglePlayback() {
        guard let engine = manager.audioEngine else { return }

        Task {
            do {
                if isPlaying {
                    try await engine.stopPlayback()
                } else {
                    try await engine.startPlayback()
                }
                isPlaying = engine.isPlaying
            } catch {
                print("Audio playback error: \(error)")
            }
        }
    }
}

// MARK: - Simple Geometry helper (no PreferenceKey)

private struct SizeReader: View {
    var onChange: (CGSize) -> Void
    @State private var lastSize: CGSize = .zero

    init(_ onChange: @escaping (CGSize) -> Void) {
        self.onChange = onChange
    }

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    let size = proxy.size
                    lastSize = size
                    onChange(size)
                }
                .onChange(of: proxy.size, initial: true) { _, newSize in
                    guard abs(newSize.width - lastSize.width) > 0.5 ||
                          abs(newSize.height - lastSize.height) > 0.5 else { return }
                    lastSize = newSize
                    onChange(newSize)
                }
        }
        // GeometryReader expands—collapse it back down
        .allowsHitTesting(false) // ensure it doesn't swallow events
        .accessibilityHidden(true)
    }
}

#if DEBUG

// MARK: - Mock Audio Engine

final class MockAudioEngine: AudioEngine {
    override var isPlaying: Bool {
        get { _isPlaying }
        set { _isPlaying = newValue }
    }
    private var _isPlaying = false

    override var currentFrequency: Float { mockFrequency }
    var mockFrequency: Float = 12_345

    // Override the method from the parent class
    // (Assuming getAudioLevels() is declared in the main AudioEngine class)
    override func getAudioLevels() -> [CGFloat] {
        if _isPlaying {
            // Generate random levels for mock visualization
            return (0..<8).map { _ in CGFloat.random(in: -40...0) }
        } else {
            return Array(repeating: -160, count: 8)
        }
    }

    override func selectNoiseType(_ type: NoiseType) {
        // no-op
    }

    override func startPlayback() async throws {
        _isPlaying = true
    }

    override func stopPlayback() async throws {
        _isPlaying = false
    }
}

// MARK: - Preview Manager (skips real window sizing side-effects)

@MainActor
final class PreviewFloatingWindowManager: FloatingWindowManager {
    override init() {
        super.init()
        // Inject a mock engine if you want interactive pieces enabled
        let mock = MockAudioEngine()
        self.setAudioEngine(mock)
    }
}

// Convenience helpers
@MainActor
private extension PreviewFloatingWindowManager {
    static func idle() -> PreviewFloatingWindowManager {
        PreviewFloatingWindowManager()
    }

    static func playing() -> PreviewFloatingWindowManager {
        let mgr = PreviewFloatingWindowManager()
        if let engine = mgr.audioEngine as? MockAudioEngine {
            engine.isPlaying = true
        }
        return mgr
    }
}

// MARK: - Previews

#Preview("Idle (Dark)") {
    FloatingControlView(manager: PreviewFloatingWindowManager.idle())
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}

#Preview("Playing (Dark)") {
    FloatingControlView(manager: PreviewFloatingWindowManager.playing())
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}

#Preview("Idle (Light)") {
    FloatingControlView(manager: PreviewFloatingWindowManager.idle())
        .padding()
        .background(Color.gray.opacity(0.15))
        .preferredColorScheme(.light)
}

#endif
