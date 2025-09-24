//
//  PhantomGateApp.swift
//  PhantomGate
//
//  Created by David Jensenius on 2025-08-07.
//

import SwiftUI
import AppKit

@MainActor
class AppState: ObservableObject {
    let audioEngine: AudioEngine
    let menuBarManager: MenuBarManager
    let floatingManager: FloatingWindowManager
    let termsOfServiceManager: TermsOfServiceManager
    @Published var isInitialized = false
    @Published var termsAccepted = false

    init() {
        // Create instances
        audioEngine = AudioEngine()
        menuBarManager = MenuBarManager()
        floatingManager = FloatingWindowManager(menuBarManager: menuBarManager)
        termsOfServiceManager = TermsOfServiceManager()

        // Check if Terms of Service have been accepted
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing") ||
                         ProcessInfo.processInfo.environment["UI_TESTING"] == "1"
        
        // Skip ToS for UI testing unless specifically testing ToS functionality
        if isUITesting && !ProcessInfo.processInfo.arguments.contains("--test-terms") {
            termsAccepted = true
        } else {
            termsAccepted = TermsOfServiceManager.hasAcceptedTerms()
        }

        // Set up environment
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing") ||
                         ProcessInfo.processInfo.environment["UI_TESTING"] == "1"

        if isUITesting {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }

        FontManager.shared.registerFonts()

        // Initialize the app after Terms of Service are handled
        initializeApp()
    }
    
    private func initializeApp() {
        if termsAccepted {
            setupDependencies()
        } else {
            // Defer showing Terms of Service modal until app is fully loaded
            DispatchQueue.main.async { [weak self] in
                self?.termsOfServiceManager.showTermsModal {
                    DispatchQueue.main.async {
                        self?.termsAccepted = true
                        self?.setupDependencies()
                    }
                }
            }
        }
    }
    
    private func setupDependencies() {
        // Set up dependencies
        menuBarManager.setAudioEngine(audioEngine)
        menuBarManager.setFloatingManager(floatingManager)
        floatingManager.setAudioEngine(audioEngine)
        isInitialized = true
    }
}

@main
struct PhantomGateApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Toggle Noise") {
                    Task {
                        do {
                            if appState.audioEngine.isPlaying {
                                try await appState.audioEngine.stopPlayback()
                            } else {
                                try await appState.audioEngine.startPlayback()
                            }
                        } catch {
                            print("Audio engine error: \(error)")
                        }
                    }
                }
                .keyboardShortcut("b", modifiers: .command)
                .disabled(!appState.isInitialized || !appState.termsAccepted)
            }
        }
    }
}
