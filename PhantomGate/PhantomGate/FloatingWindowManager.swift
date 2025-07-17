import SwiftUI
import AppKit

@MainActor
final class FloatingWindowManager: ObservableObject {
    @Published private(set) var isVisible = false
    let panel: NSPanel
    private let audioEngine: AudioEngine
    
    init() {
        self.audioEngine = AudioEngine()
        
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "PhantomGate"
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.contentView = NSHostingView(rootView: FloatingWindowView(manager: self))
        panel.backgroundColor = .clear
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Position in bottom right corner
        if let screenFrame = NSScreen.main?.visibleFrame {
            let xPos = screenFrame.maxX - panel.frame.width - 20
            let yPos = screenFrame.minY + 20
            panel.setFrameOrigin(NSPoint(x: xPos, y: yPos))
        }
    }
    
    func toggleVisibility() {
        isVisible.toggle()
        if isVisible {
            panel.makeKeyAndOrderFront(nil)
        } else {
            panel.orderOut(nil)
        }
    }
    
    nonisolated func getAudioEngine() -> AudioEngine {
        audioEngine
    }
}

struct FloatingWindowView: View {
    @ObservedObject var manager: FloatingWindowManager
    @State private var selectedNoise = NoiseType.green
    @State private var isPlaying = false
    @State private var currentFrequency: Float = 0
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PhantomGate")
                .jetBrainsMonoFont(weight: .bold, size: 20)
                .foregroundColor(Color(hex: "00ff88"))
            
            Text("Select broadband interference option:")
                .jetBrainsMonoFont(weight: .regular, size: 14)
                .foregroundColor(Color(hex: "00ff88"))
            
            Picker("", selection: $selectedNoise) {
                ForEach(NoiseType.allCases, id: \.self) { option in
                    Text(option.rawValue)
                        .jetBrainsMonoFont(weight: .regular, size: 14)
                }
            }
            .pickerStyle(.menu)
            .disabled(isPlaying)
            .onChange(of: selectedNoise) { newValue in
                Task {
                    await manager.getAudioEngine().selectNoiseType(newValue)
                }
            }
            
            HStack {
                if isPlaying {
                    WaveformView(isPlaying: true)
                        .frame(width: 100)
                    
                    Text("\(Int(currentFrequency))Hz")
                        .jetBrainsMonoFont(weight: .medium, size: 12)
                        .foregroundColor(Color(hex: "00ff88"))
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        if isPlaying {
                            await manager.getAudioEngine().stopPlayback()
                        } else {
                            await manager.getAudioEngine().startPlayback()
                        }
                        isPlaying.toggle()
                    }
                }) {
                    Text(isPlaying ? "Stop scramble" : "Start scramble")
                        .jetBrainsMonoFont(weight: .medium, size: 14)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(hex: "00ff88"))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "1a1a1a"))
        .onReceive(timer) { _ in
            if isPlaying {
                currentFrequency = manager.getAudioEngine().getCurrentFrequency()
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
            (a, r, g, b) = (1, 1, 1, 0)
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