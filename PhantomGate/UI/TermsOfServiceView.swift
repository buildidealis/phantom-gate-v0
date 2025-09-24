//
//  TermsOfServiceView.swift
//  PhantomGate
//
//  Created for Terms of Service acceptance functionality.
//

import SwiftUI
import AppKit

struct TermsOfServiceView: View {
    let onAccept: () -> Void
    @State private var isAccepted = false
    
    var body: some View {
        content
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .frame(width: 520, height: 400)
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to PhantomGate")
                    .font(FontManager.shared.font(weight: .bold, size: 32))
                    .foregroundColor(Color.phantomGreen)
                
                Text("Privacy Protection System")
                    .font(FontManager.shared.font(weight: .medium, size: 16))
                    .foregroundColor(Color.white.opacity(0.7))
            }
            
            // Terms content
            VStack(alignment: .leading, spacing: 16) {
                Text("Before using PhantomGate, please review and accept our Terms of Service.")
                    .font(FontManager.shared.font(weight: .medium, size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                // Terms link
                HStack {
                    Text("Read the full Terms of Service:")
                        .font(FontManager.shared.font(weight: .regular, size: 13))
                        .foregroundColor(Color.white.opacity(0.8))
                    
                    Button("View Terms") {
                        openTermsURL()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(Color.phantomGreen)
                    .font(FontManager.shared.font(weight: .medium, size: 13))
                    .underline()
                }
                
                // Agreement notice
                Text("By clicking \"I Accept\", you agree to our Terms of Service and understand that PhantomGate is an audio privacy protection tool.")
                    .font(FontManager.shared.font(weight: .regular, size: 12))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Accept button
            HStack {
                Spacer()
                
                Button("I Accept") {
                    acceptTerms()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .font(FontManager.shared.font(weight: .medium, size: 14))
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.phantomGreen)
                )
                .disabled(false)
                .accessibilityIdentifier("AcceptTermsButton")
            }
        }
    }
    
    private func openTermsURL() {
        if let url = URL(string: "https://mkdale.github.io/PGmarketingsite/terms.html") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func acceptTerms() {
        // Store acceptance in UserDefaults
        UserDefaults.standard.set(true, forKey: "TermsOfServiceAccepted")
        UserDefaults.standard.set(Date(), forKey: "TermsOfServiceAcceptedDate")
        
        // Call the acceptance handler
        onAccept()
    }
}

// MARK: - Terms of Service Manager

@MainActor
class TermsOfServiceManager: ObservableObject {
    @Published var shouldShowTerms = false
    private var window: NSWindow?
    
    init() {
        checkIfShouldShowTerms()
    }
    
    func checkIfShouldShowTerms() {
        let hasAccepted = UserDefaults.standard.bool(forKey: "TermsOfServiceAccepted")
        shouldShowTerms = !hasAccepted
    }
    
    func showTermsModal(onAccept: @escaping () -> Void) {
        guard shouldShowTerms else {
            onAccept()
            return
        }
        
        let termsView = TermsOfServiceView {
            self.hideTermsModal()
            onAccept()
        }
        
        let hostingView = NSHostingView(rootView: termsView)
        
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: NSSize(width: 520, height: 400)),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.level = .modalPanel
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.isReleasedWhenClosed = false
        window.title = "PhantomGate Terms of Service"
        window.setAccessibilityIdentifier("TermsOfServiceWindow")
        
        // Center the window on screen
        if let screen = NSScreen.main?.visibleFrame {
            let origin = NSPoint(
                x: screen.midX - 260, // Half of window width
                y: screen.midY - 200  // Half of window height
            )
            window.setFrameOrigin(origin)
        }
        
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        
        self.window = window
    }
    
    private func hideTermsModal() {
        window?.close()
        window = nil
        shouldShowTerms = false
    }
    
    static func hasAcceptedTerms() -> Bool {
        return UserDefaults.standard.bool(forKey: "TermsOfServiceAccepted")
    }
}

#if DEBUG
struct TermsOfServiceView_Previews: PreviewProvider {
    static var previews: some View {
        TermsOfServiceView(onAccept: {})
            .preferredColorScheme(.dark)
    }
}
#endif