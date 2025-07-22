import SwiftUI
import AppKit

@MainActor
class MenuBarManager: ObservableObject {
    @Published private(set) var isEnabled = false {
        didSet {
            updateStatusItemIcon()
        }
    }
    private var statusItem: NSStatusItem?
    private(set) var audioEngine: AudioEngine?
    private(set) var floatingManager: FloatingWindowManager?
    
    init() {
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            if let iconImage = NSImage(named: "PGicon") {
                iconImage.size = NSSize(width: 18, height: 18)
                iconImage.isTemplate = true  // This ensures proper dark/light mode handling
                button.image = iconImage
            } else {
                print("Failed to load PGicon image")
                button.title = "PG"  // Fallback to text if image fails to load
            }
            
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
            button.setAccessibilityIdentifier("PG")
            button.setAccessibilityLabel("PhantomGate Menu")
        }
    }
    
    private func updateStatusItemIcon() {
        guard let button = statusItem?.button else { return }
        if isEnabled {
            if let closeImage = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close") {
                closeImage.size = NSSize(width: 18, height: 18)
                button.image = closeImage
            }
        } else {
            if let iconImage = NSImage(named: "PGicon") {
                iconImage.size = NSSize(width: 18, height: 18)
                iconImage.isTemplate = true
                button.image = iconImage
            }
        }
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                showMenu()
            } else {
                toggleEnabled()
            }
        }
    }
    
    private func showMenu() {
        let menu = NSMenu()
        
        let noiseToggleItem = NSMenuItem(title: "Toggle Noise", action: #selector(toggleNoise), keyEquivalent: "b")
        noiseToggleItem.target = self
        noiseToggleItem.keyEquivalentModifierMask = .command
        noiseToggleItem.isEnabled = isEnabled
        menu.addItem(noiseToggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let feedbackItem = NSMenuItem(title: "Submit Feedback", action: #selector(submitFeedback), keyEquivalent: "")
        feedbackItem.target = self
        menu.addItem(feedbackItem)
        
        let helpItem = NSMenuItem(title: "Help", action: #selector(openHelp), keyEquivalent: "")
        helpItem.target = self
        menu.addItem(helpItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleEnabled() {
        isEnabled.toggle()
        floatingManager?.toggleVisibility()
    }
    
    @objc private func toggleNoise() {
        guard let engine = audioEngine else {
            print("Audio engine not initialized")
            return
        }
        
        Task {
            do {
                if engine.isPlaying {
                    try await engine.stopPlayback()
                } else {
                    try await engine.startPlayback()
                }
            } catch {
                print("Audio engine error: \(error)")
            }
        }
    }
    
    @objc private func submitFeedback() {
        if let url = URL(string: "mailto:lenzmariesa@gmail.com") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func openHelp() {
        if let url = URL(string: "mailto:lenzmariesa@gmail.com") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func setAudioEngine(_ engine: AudioEngine) {
        self.audioEngine = engine
    }
    
    func setFloatingManager(_ manager: FloatingWindowManager) {
        self.floatingManager = manager
    }
} 
