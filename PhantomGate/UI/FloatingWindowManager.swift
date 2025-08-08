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

        // Defer first intrinsic sizing one tick
        DispatchQueue.main.async { [weak self, weak hosting] in
            guard let self, let hosting, let _ = self.window else { return }
            self.applySize(hosting.fittingSize, anchorTopRight: true, animated: false)
        }
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
        VStack(spacing: 16) {
            HStack {
                Text("PhantomGate")
                    .font(FontManager.shared.font(weight: .bold, size: 18))
                    .foregroundColor(.white)
                Spacer()
                Button(
                    action: { manager.toggleVisibility() },
                    label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .accessibilityIdentifier("CloseButton")
                    }
                )
            }

            Text("Select broadband interference option:")
                .font(FontManager.shared.font(weight: .medium, size: 14))
                .foregroundColor(.white)

            Picker("Noise Type", selection: $selectedNoiseType) {
                ForEach(NoiseType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)
            .disabled(isPlaying)
            .accessibilityIdentifier("NoiseTypePicker")
            .onChange(of: selectedNoiseType) { _, newValue in
                guard let engine = manager.audioEngine else { return }
                Task { engine.selectNoiseType(newValue) }
            }

            HStack {
                VStack(alignment: .leading) {
                    WaveformView(isPlaying: isPlaying)
                        .frame(width: 100)
                        .accessibilityIdentifier("WaveformView")
                    if isPlaying {
                        Text(String(format: "%.1f kHz", currentFrequency / 1000))
                            .font(FontManager.shared.font(weight: .medium, size: 12))
                            .foregroundColor(.white)
                            .accessibilityIdentifier("FrequencyLabel")
                    }
                }

                Button(action: togglePlayback) {
                    Text(isPlaying ? "Stop scramble" : "Start scramble")
                        .font(FontManager.shared.font(weight: .medium, size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: isPlaying ? "ff3366" : "00ff88"))
                        .cornerRadius(4)
                }
                .accessibilityIdentifier("TogglePlaybackButton")
                .disabled(manager.audioEngine == nil)
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
