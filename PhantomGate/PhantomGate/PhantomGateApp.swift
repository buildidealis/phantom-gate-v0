//
//  PhantomGateApp.swift
//  PhantomGate
//
//  Created by Mariesa Lenz on 7/14/25.
//

import SwiftUI

@main
struct PhantomGateApp: App {
    @StateObject private var menuBarManager = MenuBarManager()
    @StateObject private var floatingManager = FloatingWindowManager()
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Enable/Disable") {
                    menuBarManager.toggleEnabled()
                    floatingManager.toggleVisibility()
                }
                .keyboardShortcut("m", modifiers: .command)
            }
        }
    }
    
    init() {
        // Register custom fonts
        FontManager.shared.registerFonts()
    }
}
