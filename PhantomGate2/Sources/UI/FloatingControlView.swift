import SwiftUI

struct FloatingControlView: View {
    @ObservedObject var manager: FloatingWindowManager
    @State private var selectedNoise: NoiseType = .green
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PhantomGate")
                .font(FontManager.shared.font(weight: .bold, size: 16))
                .foregroundColor(.white)
                .padding(.top, 16)
            
            Text("Select broadband interference option:")
                .font(FontManager.shared.font(weight: .regular, size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            if let audioEngine = manager.audioEngine {
                if audioEngine.isPlaying {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            WaveformView(isPlaying: true)
                                .frame(height: 30)
                            Text("\(String(format: "%.1f", audioEngine.currentFrequency / 1000)) kHz")
                                .font(FontManager.shared.font(weight: .medium, size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Button(action: {
                            Task {
                                try? await audioEngine.stopPlayback()
                            }
                        }) {
                            Text("Stop scramble")
                                .font(FontManager.shared.font(weight: .medium, size: 14))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 36)
                                .background(Color(hex: "00ff88"))
                                .cornerRadius(18)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    HStack {
                        Picker("Noise Type", selection: $selectedNoise) {
                            ForEach(NoiseType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                        .disabled(audioEngine.isPlaying)
                        
                        Button(action: {
                            Task {
                                audioEngine.selectNoiseType(selectedNoise)
                                try? await audioEngine.startPlayback()
                            }
                        }) {
                            Text("Start scramble")
                                .font(FontManager.shared.font(weight: .medium, size: 14))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 36)
                                .background(Color(hex: "00ff88"))
                                .cornerRadius(18)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(Color.black.opacity(0.9))
        .cornerRadius(20)
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