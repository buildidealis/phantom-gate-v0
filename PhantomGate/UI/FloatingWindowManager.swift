import SwiftUI
import AppKit
import Combine

@MainActor
class FloatingWindowManager: ObservableObject {
    @Published private(set) var isVisible = false {
        didSet { isVisible ? showWindow() : hideWindow() }
    }
    @Published var isMouseInWindow = false
    @Published private(set) var audioEngineIsPlaying = false

    private var window: NSWindow?
    private(set) var audioEngine: AudioEngine?
    var menuBarManager: MenuBarManager?
    private var trackingArea: NSTrackingArea?
    private var eventMonitor: Any?
    private var audioEngineObserver: AnyCancellable?

    // Track last size to avoid jitter - but we'll disable resizing
    private var lastSize: CGSize = .zero
    private var fixedSize: CGSize?

    init(menuBarManager: MenuBarManager?) {
        self.menuBarManager = menuBarManager
        setupWindow()
    }

    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        audioEngineObserver?.cancel()
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
        setupMouseTracking()
    }

    private func setupMouseTracking() {
        guard let window = window else { return }

        // Create a custom view that handles mouse tracking
        let trackingView = MouseTrackingView { [weak self] isInside in
            self?.isMouseInWindow = isInside
        }

        // If there's already a content view, wrap it
        if let existingContent = window.contentView {
            trackingView.addSubview(existingContent)
            existingContent.frame = trackingView.bounds
            existingContent.autoresizingMask = [.width, .height]
        }

        window.contentView = trackingView
    }

    func setAudioEngine(_ engine: AudioEngine) {
        audioEngine = engine
        // Observe the AudioEngine's isPlaying state and mirror it in our own @Published property
        audioEngineObserver = engine.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                self?.audioEngineIsPlaying = isPlaying
            }
        setupContentView()
    }

    private func setupContentView() {
        guard let window else { return }
        let root = FloatingControlView(manager: self, menuBarManager: menuBarManager)
        let hosting = NSHostingView(rootView: root)

        // Wrap in tracking view
        let trackingView = MouseTrackingView { [weak self] isInside in
            self?.isMouseInWindow = isInside
        }
        trackingView.addSubview(hosting)
        hosting.frame = trackingView.bounds
        hosting.autoresizingMask = [.width, .height]

        window.contentView = trackingView
    }

    func resize(to newContentSize: CGSize) {
        // Only allow initial sizing, then lock the size
        guard fixedSize == nil else { return }
        
        // Filter out zero / trivial changes
        if newContentSize.width < 5 || newContentSize.height < 5 { return }
        
        // Set the fixed size on first meaningful resize
        fixedSize = newContentSize
        applySize(newContentSize, anchorTopRight: true, animated: false)
    }

    private func applySize(_ size: CGSize, anchorTopRight: Bool, animated: Bool) {
        guard let window else { return }

        // Clamp to sensible minimums
        let minWidth: CGFloat = 320
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

// MARK: - Custom NSView for Mouse Tracking

class MouseTrackingView: NSView {
    private var trackingArea: NSTrackingArea?
    private let mouseHandler: (Bool) -> Void

    init(mouseHandler: @escaping (Bool) -> Void) {
        self.mouseHandler = mouseHandler
        super.init(frame: .zero)
        updateTrackingAreas()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        if let existingArea = trackingArea {
            removeTrackingArea(existingArea)
        }

        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeAlways,
            .inVisibleRect
        ]

        trackingArea = NSTrackingArea(
            rect: bounds,
            options: options,
            owner: self,
            userInfo: nil
        )

        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }

        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) {
        mouseHandler(true)
    }

    override func mouseExited(with event: NSEvent) {
        mouseHandler(false)
    }
}

// MARK: - Stoplight Close Button View

struct StoplightCloseButton: View {
    let isVisible: Bool
    @State private var isHovered = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.373, blue: 0.341)) // #FF5F57
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                    )

                if isHovered {
                    Image(systemName: "xmark")
                        .font(.system(size: 6, weight: .medium))
                        .foregroundColor(Color.black.opacity(0.5))
                }
            }
            .frame(width: 12, height: 12)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: isVisible)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityIdentifier("StoplightCloseButton")
        .accessibilityLabel("Close window")
    }
}

// MARK: - Protocol for Audio Level Provider

protocol AudioLevelProvider {
    func getAudioLevels() -> [CGFloat]
}

// MARK: - SwiftUI Content

struct FloatingControlView: View {
    @ObservedObject var manager: FloatingWindowManager
    var menuBarManager: MenuBarManager?
    @State private var selectedNoiseType: NoiseType = .green
    @State private var showAdvancedSettings = false
    @State private var enableArtifacts = true
    @State private var artifactIntensity: Float = 0.5
    @State private var chatterVolume: Float = 0.08
    @State private var ultrasonicVolume: Float = 0.03
    @State private var micGain: Float = 0.3
    @State private var noiseVolume: Float = 0.1
    @State private var currentFrequency: Float = 0
    @State private var frequencyStreamError: Error?
    @State private var frequencyTask: Task<Void, Never>?

    // Use the published property from the manager that observes the AudioEngine
    private var isPlaying: Bool {
        manager.audioEngineIsPlaying
    }

    var body: some View {
        content
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .frame(width: 490, height: 600) // Fixed size for the entire view
            .overlay(SizeReader { manager.resize(to: $0) })
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with close button
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("PhantomGate")
                        .font(FontManager.shared.font(weight: .bold, size: 48))
                        .foregroundColor(Color.phantomGreen)
                        .padding(.top, 0)

                    Text("Privacy Protection System")
                        .font(FontManager.shared.font(weight: .medium, size: 12))
                        .foregroundColor(Color.white.opacity(0.7))
                        .padding(.bottom, 8)

                    Text("Select protection mode:")
                        .font(FontManager.shared.font(weight: .medium, size: 14))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)

                    // Enhanced protection mode picker
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("", selection: $selectedNoiseType) {
                            ForEach(NoiseType.allCases, id: \.self) { type in
                                Text(type.rawValue)
                                    .font(FontManager.shared.font(weight: .medium, size: 13))
                                    .tag(type)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .disabled(isPlaying)
                        .accessibilityIdentifier("EnhancedNoiseTypePicker")
                        .colorScheme(.dark) // Ensure dark color scheme
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .onChange(of: selectedNoiseType) { _, newValue in
                            guard let engine = manager.audioEngine else { return }
                            engine.selectEnhancedNoiseType(newValue)
                        }


                        // Show description of selected mode
                        Text(selectedNoiseType.description)
                            .font(FontManager.shared.font(weight: .regular, size: 11))
                            .foregroundColor(Color.white.opacity(0.6))
                            .padding(.horizontal, 4)
                    }
                }

                // Stoplight close button
                StoplightCloseButton(
                    isVisible: manager.isMouseInWindow,
                    action: { menuBarManager?.toggleEnabled() }
                )
                .offset(x: -12, y: -12)
            }

            // Advanced Settings Section
            VStack(alignment: .leading, spacing: 12) {
                // Toggle for advanced settings
                Button {
                    withAnimation(.easeInOut) {
                        showAdvancedSettings.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showAdvancedSettings ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10))
                        Text("Advanced Settings")
                            .font(FontManager.shared.font(weight: .medium, size: 12))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .contentShape(Rectangle())               // improves tap target
                    .accessibilityLabel("Advanced Settings")
                    .accessibilityValue(showAdvancedSettings ? "Shown" : "Hidden")
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isPlaying)

                if showAdvancedSettings {
                    // Volume Controls Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Audio Mix Controls:")
                            .font(FontManager.shared.font(weight: .medium, size: 14))
                            .foregroundColor(.white)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 8) {
                            // Microphone Gain Control
                            HStack {
                                Text("Mic Gain:")
                                    .font(FontManager.shared.font(weight: .regular, size: 12))
                                    .foregroundColor(Color.white.opacity(0.8))
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: $micGain, in: 0...1.0)
                                    .frame(width: 120)
                                    .onChange(of: micGain) { _, newValue in
                                        manager.audioEngine?.updateMicGain(newValue)
                                    }
                                Text("\(Int(micGain * 100))%")
                                    .font(FontManager.shared.font(weight: .regular, size: 10))
                                    .foregroundColor(Color.white.opacity(0.7))
                                    .frame(width: 35)
                            }

                            // Noise Volume Control
                            HStack {
                                Text("Noise Vol:")
                                    .font(FontManager.shared.font(weight: .regular, size: 12))
                                    .foregroundColor(Color.white.opacity(0.8))
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: $noiseVolume, in: 0...0.5)
                                    .frame(width: 120)
                                    .onChange(of: noiseVolume) { _, newValue in
                                        manager.audioEngine?.updateNoiseVolume(newValue)
                                    }
                                Text("\(Int(noiseVolume * 200))%")
                                    .font(FontManager.shared.font(weight: .regular, size: 10))
                                    .foregroundColor(Color.white.opacity(0.7))
                                    .frame(width: 35)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        if enableArtifacts {
                            HStack {
                                Text("Intensity:")
                                    .font(FontManager.shared.font(weight: .regular, size: 10))
                                    .foregroundColor(Color.white.opacity(0.7))
                                Slider(value: $artifactIntensity, in: 0...1)
                                    .frame(width: 100)
                                    .disabled(isPlaying)
                                    .onChange(of: artifactIntensity) { _, newValue in
                                        manager.audioEngine?.artifactIntensity = newValue
                                    }
                                Text("\(Int(artifactIntensity * 100))%")
                                    .font(FontManager.shared.font(weight: .regular, size: 10))
                                    .foregroundColor(Color.white.opacity(0.7))
                                    .frame(width: 35)
                            }
                        }

                        // Volume controls for enhanced features
                        if [.ultrasonic, .hybrid].contains(selectedNoiseType) {
                            HStack {
                                Text("Ultrasonic Vol:")
                                    .font(FontManager.shared.font(weight: .regular, size: 10))
                                    .foregroundColor(Color.white.opacity(0.7))
                                Slider(value: $ultrasonicVolume, in: 0...0.1)
                                    .frame(width: 100)
                                    .disabled(isPlaying)
                                    .onChange(of: ultrasonicVolume) { _, newValue in
                                        manager.audioEngine?.ultrasonicVolume = newValue
                                    }
                                Text("\(Int(ultrasonicVolume * 1000))%")
                                    .font(FontManager.shared.font(weight: .regular, size: 10))
                                    .foregroundColor(Color.white.opacity(0.7))
                                    .frame(width: 35)
                            }
                        }

                        if [.chatter, .hybrid].contains(selectedNoiseType) {
                            HStack {
                                Text("Chatter Vol:")
                                    .font(FontManager.shared.font(weight: .regular, size: 10))
                                    .foregroundColor(Color.white.opacity(0.7))
                                Slider(value: $chatterVolume, in: 0...0.2)
                                    .frame(width: 100)
                                    .disabled(isPlaying)
                                    .onChange(of: chatterVolume) { _, newValue in
                                        manager.audioEngine?.chatterVolume = newValue
                                    }
                                Text("\(Int(chatterVolume * 1500))%")
                                    .font(FontManager.shared.font(weight: .regular, size: 10))
                                    .foregroundColor(Color.white.opacity(0.7))
                                    .frame(width: 35)
                            }
                        }

                        // Advanced mode controls
                        if [.spectralSweep, .temporalJitter, .whisperMask, .pitchFormantDrift,
                            .phaseScramble, .quantizePulse, .rotationCycle].contains(selectedNoiseType) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Advanced Mode Settings:")
                                    .font(FontManager.shared.font(weight: .medium, size: 12))
                                    .foregroundColor(.white.opacity(0.9))

                                HStack {
                                    Text("Disruption Strength:")
                                        .font(FontManager.shared.font(weight: .regular, size: 10))
                                        .foregroundColor(Color.white.opacity(0.7))
                                    Slider(value: $artifactIntensity, in: 0...1)
                                        .frame(width: 100)
                                        .disabled(isPlaying)
                                        .onChange(of: artifactIntensity) { _, newValue in
                                            manager.audioEngine?.artifactIntensity = newValue
                                        }
                                    Text("\(Int(artifactIntensity * 100))%")
                                        .font(FontManager.shared.font(weight: .regular, size: 10))
                                        .foregroundColor(Color.white.opacity(0.7))
                                        .frame(width: 35)
                                }

                                HStack {
                                    Text("Output Volume:")
                                        .font(FontManager.shared.font(weight: .regular, size: 10))
                                        .foregroundColor(Color.white.opacity(0.7))
                                    Slider(value: $noiseVolume, in: 0...0.5)
                                        .frame(width: 100)
                                        .disabled(isPlaying)
                                        .onChange(of: noiseVolume) { _, newValue in
                                            manager.audioEngine?.noiseVolume = newValue
                                        }
                                    Text("\(Int(noiseVolume * 200))%")
                                        .font(FontManager.shared.font(weight: .regular, size: 10))
                                        .foregroundColor(Color.white.opacity(0.7))
                                        .frame(width: 35)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.vertical, 4)
                }
            }

            // Playback controls - Reserve space for all states
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    // Always reserve space for waveform and status
                    HStack(spacing: 12) {
                        if let audioEngine = manager.audioEngine as? AudioLevelProvider {
                            WaveformView(isPlaying: isPlaying, audioLevelProvider: audioEngine)
                                .frame(width: 50)
                                .opacity(isPlaying ? 1.0 : 0.0)
                                .accessibilityIdentifier("WaveformView")
                        } else {
                            WaveformView(isPlaying: isPlaying)
                                .frame(width: 50)
                                .opacity(isPlaying ? 1.0 : 0.0)
                                .accessibilityIdentifier("WaveformView")
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(isPlaying ? String(format: "%.1f kHz", currentFrequency / 1000) : "")
                                .font(FontManager.shared.font(weight: .medium, size: 12))
                                .foregroundColor(.white)
                                .frame(minWidth: 60, alignment: .leading)

                            Text(isPlaying ? protectionStatusText : "")
                                .font(FontManager.shared.font(weight: .regular, size: 10))
                                .foregroundColor(Color.phantomGreen.opacity(0.8))
                                .frame(minWidth: 120, alignment: .leading)
                        }
                        .opacity(isPlaying ? 1.0 : 0.0)
                    }

                    Spacer(minLength: 0)

                    Button(action: togglePlayback) {
                        HStack(spacing: 6) {
                            Image(systemName: isPlaying ? "shield.slash.fill" : "shield.fill")
                                .font(.system(size: 14))
                            Text(isPlaying ? "Stop Protection" : "Start Protection")
                                .font(FontManager.shared.font(weight: .medium, size: 14))
                        }
                        .foregroundColor(isPlaying ? .phantomRed : .phantomGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(minWidth: 200) // Fixed minimum width for button
                    }
                    .accessibilityIdentifier("ToggleProtectionButton")
                    .disabled(manager.audioEngine == nil)
                    .environment(\.colorScheme, .dark)
                }
                .frame(minHeight: 50) // Reserve minimum height

                // Protection indicators - Always reserve space
                HStack(spacing: 16) {
                    // Show the active protection method based on selected noise type
                    Group {
                        switch selectedNoiseType {
                        case .green, .pink, .pinkBabble:
                            ProtectionIndicator(
                                icon: "waveform",
                                label: "Noise",
                                isActive: isPlaying
                            )
                            if enableArtifacts {
                                ProtectionIndicator(
                                    icon: "waveform.path.ecg",
                                    label: "Artifacts",
                                    isActive: isPlaying
                                )
                            }

                        case .ultrasonic:
                            ProtectionIndicator(
                                icon: "antenna.radiowaves.left.and.right",
                                label: "Ultrasonic",
                                isActive: isPlaying
                            )

                        case .chatter:
                            ProtectionIndicator(
                                icon: "water.waves",
                                label: "Sine Waves",
                                isActive: isPlaying
                            )

                        case .hybrid:
                            ProtectionIndicator(
                                icon: "shuffle",
                                label: "Rotating",
                                isActive: isPlaying
                            )

                        case .spectralSweep:
                            ProtectionIndicator(
                                icon: "waveform.path.badge.minus",
                                label: "Spectral Sweep",
                                isActive: isPlaying
                            )

                        case .temporalJitter:
                            ProtectionIndicator(
                                icon: "timer",
                                label: "Temporal Jitter",
                                isActive: isPlaying
                            )

                        case .whisperMask:
                            ProtectionIndicator(
                                icon: "waveform.path.ecg.rectangle",
                                label: "Whisper Mask",
                                isActive: isPlaying
                            )

                        case .pitchFormantDrift:
                            ProtectionIndicator(
                                icon: "tuningfork",
                                label: "Pitch/Formant Drift",
                                isActive: isPlaying
                            )

                        case .phaseScramble:
                            ProtectionIndicator(
                                icon: "waveform.circle",
                                label: "Phase Scramble",
                                isActive: isPlaying
                            )

                        case .quantizePulse:
                            ProtectionIndicator(
                                icon: "square.stack.3d.up",
                                label: "Quantize Pulse",
                                isActive: isPlaying
                            )

                        case .rotationCycle:
                            ProtectionIndicator(
                                icon: "arrow.triangle.2.circlepath",
                                label: "Rotation Cycle",
                                isActive: isPlaying
                            )
                        }

                        // Always show BlackHole indicator
                        ProtectionIndicator(
                            icon: "personalhotspot",
                            label: "BlackHole",
                            isActive: isPlaying
                        )
                    }
                }
                .padding(.top, 8)
                .frame(minHeight: 60) // Reserve minimum height for indicators
            }
            .padding(8)
        }
        .onAppear {
            setupInitialValues()
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

    private var protectionStatusText: String {
        switch selectedNoiseType {
        case .hybrid:
            return "Maximum Protection"
        case .ultrasonic:
            return "Ultrasonic Active"
        case .chatter:
            return "Sine Waves Active"
        default:
            return "Basic Protection"
        }
    }

    private func setupInitialValues() {
        if let engine = manager.audioEngine {
            enableArtifacts = engine.enableArtifacts
            artifactIntensity = engine.artifactIntensity
            chatterVolume = engine.chatterVolume
            ultrasonicVolume = engine.ultrasonicVolume
            micGain = engine.micGain
            noiseVolume = engine.noiseVolume
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

        // Check BlackHole availability before starting
        if !isPlaying {
            engine.checkVirtualMicPresence()
            guard case .ready = engine.virtualMicState else {
                // Handle BlackHole not available - this should open the install link
                menuBarManager?.installVirtualMic()
                return
            }
        }

        Task {
            do {
                if isPlaying {
                    try await engine.stopPlayback()
                } else {
                    try await engine.startPlayback()
                }
            } catch {
                print("Audio playback error: \(error)")
            }
        }
    }
}

// MARK: - Protection Indicator Component

struct ProtectionIndicator: View {
    let icon: String
    let label: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isActive ? Color.phantomGreen : Color.white.opacity(0.3))

            Text(label)
                .font(FontManager.shared.font(weight: .regular, size: 9))
                .foregroundColor(isActive ? Color.white.opacity(0.8) : Color.white.opacity(0.3))
        }
        .opacity(isActive ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.3), value: isActive)
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

#endif
