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

    deinit {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }

    private func setupStatusItem() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        statusItem = NSStatusBar.system.statusItem(
            withLength: isUITesting ? NSStatusItem.squareLength : NSStatusItem.variableLength
        )

        if let button = statusItem?.button {
            button.title = "PG"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.setAccessibilityIdentifier("PG")
            button.setAccessibilityLabel("PhantomGate Menu")
        }
    }

    // Split buildMenu for lint compliance
    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        addToggleItem(to: menu)
        addProtectionToggleItem(to: menu)
        menu.addItem(NSMenuItem.separator())
        addFeedbackAndHelpItems(to: menu)
        addTerms(to: menu)
        menu.addItem(NSMenuItem.separator())
        addQuitItem(to: menu)
        return menu
    }

    private func addToggleItem(to menu: NSMenu) {
        let toggleItem = NSMenuItem(
            title: isEnabled ? "Hide Main Window" : "Show Main Window",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
    }

    private func addProtectionToggleItem(to menu: NSMenu) {
        // Check if BlackHole is available
        guard let engine = audioEngine else { return }
        engine.checkVirtualMicPresence()

        let title: String
        let action: Selector?
        let enabled: Bool

        switch engine.virtualMicState {
        case .driverMissing:
            title = "Install BlackHole for Protection…"
            action = #selector(installVirtualMicFromMenu)
            enabled = true
        case .ready, .streaming:
            title = engine.isPlaying ? "Stop Protection" : "Start Protection"
            action = #selector(toggleProtection)
            enabled = isEnabled
        case .error(let msg):
            title = "Protection Error (\(msg))"
            action = nil
            enabled = false
        }

        let protectionToggleItem = NSMenuItem(
            title: title,
            action: action,
            keyEquivalent: "b"
        )
        protectionToggleItem.target = self
        protectionToggleItem.keyEquivalentModifierMask = .command
        protectionToggleItem.isEnabled = enabled
        menu.addItem(protectionToggleItem)
    }

    private func addFeedbackAndHelpItems(to menu: NSMenu) {
        let feedbackItem = NSMenuItem(
            title: "Submit Feedback",
            action: #selector(submitFeedback),
            keyEquivalent: ""
        )
        feedbackItem.target = self
        menu.addItem(feedbackItem)

        let helpItem = NSMenuItem(
            title: "Help",
            action: #selector(openHelp),
            keyEquivalent: ""
        )
        helpItem.target = self
        menu.addItem(helpItem)
    }

    private func addTerms(to menu: NSMenu) {
        let termsItem = NSMenuItem(
            title: "View of Service",
            action: #selector(viewTerms),
            keyEquivalent: ""
        )
        termsItem.target = self
        menu.addItem(termsItem)

        menu.addItem(.separator())
        let resetTerms = NSMenuItem(
            title: "Reset Terms Popup",
            action: #selector(resetTerms),
            keyEquivalent: ""
        )
        resetTerms.target = self
        menu.addItem(resetTerms)
        menu.addItem(.separator())
    }

    private func addQuitItem(to menu: NSMenu) {
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let menu = buildMenu()
        if let button = statusItem?.button {
            menu.popUp(positioning: nil,
                       at: NSPoint(x: 0, y: button.bounds.height - 4),
                       in: button)
        }
    }

    @objc func toggleEnabled() {
        isEnabled.toggle()
        floatingManager?.toggleVisibility()
    }

    @objc private func toggleProtection() {
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

    @objc private func viewTerms() {
        if let url = URL(string: "https://mkdale.github.io/PGmarketingsite/terms.html") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func resetTerms() {
        UserDefaults.standard.set(false, forKey: "TermsOfServiceAccepted")
        UserDefaults.standard.set(Date(), forKey: "TermsOfServiceAcceptedDate")
    }

    func setAudioEngine(_ engine: AudioEngine) {
        self.audioEngine = engine
    }

    func setFloatingManager(_ manager: FloatingWindowManager) {
        self.floatingManager = manager
    }

    func installVirtualMic() {
        if let url = URL(string: "https://existential.audio/blackhole/") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func installVirtualMicFromMenu() {
        installVirtualMic()
    }

    private func updateMenu() {
        statusItem?.menu = buildMenu()
    }

}
