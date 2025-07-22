//
//  PhantomGateApp.swift
//  PhantomGate
//
//  Created by Mariesa Lenz on 7/17/25.
//

import SwiftUI
import AppKit

// Separate class to handle our app's state
@MainActor
class AppState: ObservableObject {
    let audioEngine: AudioEngine
    let menuBarManager: MenuBarManager
    let floatingManager: FloatingWindowManager
    @Published var isInitialized = false
    
    init() {
        // Create instances
        audioEngine = AudioEngine()
        menuBarManager = MenuBarManager()
        floatingManager = FloatingWindowManager()
        
        // Set up environment
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing") ||
                         ProcessInfo.processInfo.environment["UI_TESTING"] == "1"
        
        if isUITesting {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
        
        // Register fonts
        FontManager.shared.registerFonts()
        
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
        MenuBarExtra {
            EmptyView()
        } label: {
            Image("PGicon")
                .resizable()
                .frame(width: 18, height: 18)
        }
        .menuBarExtraStyle(.window)
        
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
                .disabled(!appState.isInitialized)
            }
        }
    }
}
