import SwiftUI

enum FontWeight: CaseIterable {
    case regular
    case medium
    case bold
    case semiBold
    
    var filename: String {
        switch self {
        case .regular: return "JetBrainsMono-Regular"
        case .medium: return "JetBrainsMono-Medium"
        case .bold: return "JetBrainsMono-Bold"
        case .semiBold: return "JetBrainsMono-Bold" // Using Bold for SemiBold
        }
    }
}

final class FontManager {
    static let shared = FontManager()
    private var loadedFonts: Set<String> = []
    
    private init() {}
    
    func registerFonts() {
        registerFont(name: FontWeight.regular.filename)
        registerFont(name: FontWeight.medium.filename)
        registerFont(name: FontWeight.bold.filename)
    }
    
    private func registerFont(name: String) {
        // Early exit if font already loaded
        guard !loadedFonts.contains(name) else { return }

        // Locate font file in bundle
        guard let fontURL = Bundle.main.url(forResource: name, withExtension: "ttf") else {
            print("Error: Font file '\(name).ttf' not found in bundle.")
            return
        }

        // Register font with CoreText
        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
        if !success {
            let message = (error?.takeRetainedValue().localizedDescription) ?? "Unknown error"
            print("Error: Failed to register font '\(name)' via URL: \(message)")
            return
        }
        // Mark as loaded
        loadedFonts.insert(name)
    }
    
    func font(weight: FontWeight = .regular, size: CGFloat) -> Font {
        Font.custom(weight.filename, size: size)
    }
}
