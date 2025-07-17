import SwiftUI
import AppKit

@MainActor
final class MenuBarManager: ObservableObject {
    @Published private(set) var isEnabled = false
    let statusItem: NSStatusItem
    private let shortcutKey = "CommandM"
    
    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "PG"
            button.font = .jetBrainsMono(size: 12, weight: .medium)
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        statusItem.menu = constructMenu()
    }
    
    func constructMenu() -> NSMenu {
        let menu = NSMenu()
        
        // PhantomGate toggle
        let toggleItem = NSMenuItem(
            title: "PhantomGate",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(.separator())
        
        // Keyboard shortcut
        let shortcutItem = NSMenuItem(
            title: "Enable/Disable (⌘M)",
            action: #selector(toggleEnabled),
            keyEquivalent: "m"
        )
        shortcutItem.keyEquivalentModifierMask = .command
        shortcutItem.target = self
        menu.addItem(shortcutItem)
        
        menu.addItem(.separator())
        
        // Feedback
        let feedbackItem = NSMenuItem(
            title: "Submit feedback",
            action: #selector(openFeedback),
            keyEquivalent: ""
        )
        feedbackItem.target = self
        menu.addItem(feedbackItem)
        
        // Help
        let helpItem = NSMenuItem(
            title: "Help",
            action: #selector(openHelp),
            keyEquivalent: ""
        )
        helpItem.target = self
        menu.addItem(helpItem)
        
        return menu
    }
    
    @objc func toggleEnabled() {
        isEnabled.toggle()
        updateStatusItemAppearance()
    }
    
    private func updateStatusItemAppearance() {
        if let button = statusItem.button {
            button.title = isEnabled ? "PG" : "PG"  // We'll update this with different styling later
        }
    }
    
    @objc private func openFeedback() {
        if let url = URL(string: "mailto:lenzmariesa@gmail.com") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func openHelp() {
        if let url = URL(string: "mailto:lenzmariesa@gmail.com") {
            NSWorkspace.shared.open(url)
        }
    }
}

// Font extension for JetBrains Mono
extension NSFont {
    static func jetBrainsMono(size: CGFloat, weight: Weight = .regular) -> NSFont {
        guard let font = NSFont(name: "JetBrainsMono-Regular", size: size) else {
            return .monospacedSystemFont(ofSize: size, weight: weight)
        }
        return font
    }
} 