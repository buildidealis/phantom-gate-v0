import SwiftUI
import AppKit

@MainActor
class FloatingWindowManager: ObservableObject {
    @Published private(set) var isVisible = false {
        didSet {
            if isVisible {
                showWindow()
            } else {
                hideWindow()
            }
        }
    }
    private var window: NSWindow?
    private(set) var audioEngine: AudioEngine?
    private var contentView: NSHostingView<FloatingControlView>?
    
    init() {
        setupWindow()
    }
    
    private func setupWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.ignoresMouseEvents = false
        window.isReleasedWhenClosed = false
        
        window.setAccessibilityIdentifier("PhantomGate")
        window.title = "PhantomGate"
        
        if let screenFrame = NSScreen.main?.visibleFrame {
            let windowFrame = window.frame
            let newOrigin = NSPoint(
                x: screenFrame.maxX - windowFrame.width - 20,
                y: screenFrame.minY + 20
            )
            window.setFrameOrigin(newOrigin)
        }
        
        self.window = window
    }
    
    func setAudioEngine(_ engine: AudioEngine) {
        self.audioEngine = engine
        setupContentView()
    }
    
    private func setupContentView() {
        guard let window = window else { return }
        let view = FloatingControlView(manager: self)
        let hostingView = NSHostingView(rootView: view)
        window.contentView = hostingView
        self.contentView = hostingView
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

struct FloatingControlView: View {
    @ObservedObject var manager: FloatingWindowManager
    @State private var selectedNoiseType: NoiseType = .green
    @State private var isPlaying = false
    @State private var currentFrequency: Float = 0
    @State private var frequencyStreamError: Error?
    @State private var frequencyTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("PhantomGate")
                    .font(FontManager.shared.font(weight: .bold, size: 18))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { manager.toggleVisibility() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .accessibilityIdentifier("CloseButton")
                }
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
            .onChange(of: selectedNoiseType) { oldValue, newValue in
                guard let engine = manager.audioEngine else { return }
                Task {
                    engine.selectNoiseType(newValue)
                }
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
        .padding(16)
        .background(Color.black.opacity(0.8))
        .cornerRadius(8)
        .onAppear {
            startFrequencyMonitoring()
        }
        .onDisappear {
            frequencyTask?.cancel()
            frequencyTask = nil
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 