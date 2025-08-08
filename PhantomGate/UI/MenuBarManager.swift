import SwiftUI
import AppKit

@MainActor
class MenuBarManager: ObservableObject {
    @Published private(set) var isEnabled = false
    private var statusItem: NSStatusItem?
    private(set) var audioEngine: AudioEngine?
    private(set) var floatingManager: FloatingWindowManager?

    init() {
        setupStatusItem()
    }

    private func setupStatusItem() {
        let isUITesting = ProcessInfo
            .processInfo
            .arguments
            .contains("--ui-testing")
        statusItem = NSStatusBar
            .system
            .statusItem(withLength: isUITesting ? NSStatusItem.squareLength : NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "PG"
            button.target = self
            button.action = #selector(statusItemClicked(_:))

            button.setAccessibilityIdentifier("PG")
            button.setAccessibilityLabel("PhantomGate Menu")
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "Enable/Disable", action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.target = self
        toggleItem.state = isEnabled ? .on : .off
        menu.addItem(toggleItem)

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
