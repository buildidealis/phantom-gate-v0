import SwiftUI

enum FontWeight {
    case regular
    case medium
    case bold
    case semiBold
    
    var filename: String {
        switch self {
        case .regular: return "JetBrainsMono-Regular"
        case .medium: return "JetBrainsMono-Medium"
        case .bold: return "JetBrainsMono-Bold"
        case .semiBold: return "JetBrainsMono-SemiBold"
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
        registerFont(name: FontWeight.semiBold.filename)
    }
    
    private func registerFont(name: String) {
        guard !loadedFonts.contains(name),
              let fontURL = Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Resources/Fonts/fonts/ttf"),
              let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(fontDataProvider) else {
            print("Failed to load font: \(name)")
            return
        }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            print("Failed to register font \(name): \(error.debugDescription)")
        } else {
            loadedFonts.insert(name)
        }
    }
    
    func font(weight: FontWeight = .regular, size: CGFloat) -> Font {
        Font.custom(weight.filename, size: size)
    }
}

extension View {
    func jetBrainsMonoFont(weight: FontWeight = .regular, size: CGFloat) -> some View {
        self.font(FontManager.shared.font(weight: weight, size: size))
    }
} 