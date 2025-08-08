# PhantomGate - macOS Audio Privacy Application

PhantomGate is a native macOS menu bar application built with Swift/SwiftUI that provides audio privacy through broadband interference generation. The application requires macOS 15.5+ and Xcode 15.0+ for development.

**CRITICAL: Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## System Requirements & Prerequisites

- **macOS 15.5 or later** - This application ONLY runs on macOS due to native API dependencies
- **Xcode 15.0 or later** - Required for building and development
- **Swift 5.0+** - Language version (configured in project)
- **Audio permissions** - App requires microphone access for audio processing

**IMPORTANT: This is a macOS-only application. Development must be done on macOS with Xcode installed. Linux/Windows environments cannot build or run this application.**

## Working Effectively

### Bootstrap and Build Process

1. **Verify Prerequisites**:
   ```bash
   # Verify Xcode is installed and up to date
   xcode-select --print-path
   xcodebuild -version  # Should show Xcode 15.0+
   ```

2. **Clone and Setup**:
   ```bash
   git clone https://github.com/buildidealis/phantom-gate-v0.git
   cd phantom-gate-v0
   ```

3. **Open Project**:
   ```bash
   open PhantomGate.xcodeproj
   ```

4. **Build the Application**:
   - **Xcode GUI**: Select "PhantomGate" scheme, then ⌘+R (Build and Run)
   - **Command Line**: `xcodebuild -scheme PhantomGate build`
   - **Build Time**: Clean build: 2-5 minutes, Incremental build: 30 seconds - 2 minutes
   - **NEVER CANCEL**: Swift builds may appear to hang during dependency resolution and compilation. Set timeout to 15+ minutes for clean builds.
   - **Expected Output**: Build succeeds with no errors, application launches in menu bar

### Testing

**Run All Tests**:
- **Xcode GUI**: ⌘+U (Build and Test)
- **Command Line**: `xcodebuild test -scheme PhantomGate`
- **Test Time**: Full test suite: 1-3 minutes, Individual test files: 10-30 seconds
- **NEVER CANCEL**: UI tests may take time to launch simulator and execute scenarios. Set timeout to 15+ minutes for full suite.
- **Expected Results**: All tests pass, no failures or crashes

**Test Structure**:
- **Unit Tests** (`PhantomGateTests/`): Core functionality, audio engine logic, font management
- **UI Tests** (`PhantomGateUITests/`): Application launch, menu bar integration, UI interactions

### Code Quality and Linting

**SwiftLint** (REQUIRED before committing):
```bash
# Install SwiftLint if not present (macOS only)
brew install swiftlint

# Run linting (configured via .swiftlint.yml)
swiftlint

# Auto-fix issues where possible
swiftlint --fix
```

**IMPORTANT**: SwiftLint requires macOS. The CI pipeline (.github/workflows/lint.yml) runs SwiftLint on Ubuntu using GitHub Actions.

**ALWAYS run SwiftLint before committing** - the CI pipeline will fail if linting errors exist.

### Running the Application

**Development Mode**:
1. Build and run from Xcode (⌘+R)
2. Application appears in menu bar as "PG"
3. **UI Testing Mode**: Run with `--ui-testing` argument for foreground mode (useful for debugging)

**Menu Bar Behavior**:
- Normal mode: Runs as accessory app (menu bar only)
- UI Testing mode: Runs as regular app (dock icon visible)

## Validation and Testing Scenarios

### CRITICAL Validation Requirements

**ALWAYS perform these validation steps after making changes:**

1. **Build Validation**:
   ```bash
   xcodebuild -scheme PhantomGate build
   # Verify successful build with no errors
   # NOTE: This command only works on macOS with Xcode installed
   ```

2. **Test Validation**:
   ```bash
   xcodebuild test -scheme PhantomGate
   # All tests must pass  
   # NOTE: This command only works on macOS with Xcode installed
   ```

3. **Lint Validation**:
   ```bash
   swiftlint
   # No warnings or errors allowed
   # NOTE: SwiftLint requires macOS or uses CI for validation
   ```

### Manual Application Testing

**ALWAYS test these user scenarios after significant changes:**

1. **Application Launch**:
   - Launch application from Xcode
   - Verify "PG" appears in macOS menu bar
   - Click menu bar item to verify menu appears

2. **Core Functionality**:
   - Enable application via "Show Main Window" menu item
   - Verify floating control window appears
   - Test noise type selection (Green, Pink, Pink Babble)
   - Test audio start/stop functionality
   - Verify waveform visualization displays

3. **Keyboard Shortcuts**:
   - Test ⌘+B shortcut for noise toggle
   - Verify shortcut works when app is in background

4. **Audio Engine**:
   - Start audio generation
   - Verify no audio artifacts or crashes
   - Test switching between noise types during playback
   - Stop audio and verify clean shutdown

5. **Window Management**:
   - Show/hide floating window
   - Test window positioning and behavior
   - Close window and verify app continues running

## Common Development Tasks

### Project Structure Reference

```
PhantomGate/
├── Audio/
│   └── AudioEngine.swift          # Core audio processing and noise generation
├── UI/
│   ├── MenuBarManager.swift       # Menu bar integration and controls
│   ├── FloatingWindowManager.swift # Floating window management
│   └── WaveformView.swift         # Real-time audio visualization
├── Utils/
│   └── FontManager.swift          # Custom font loading (JetBrains Mono)
├── Resources/
│   └── Fonts/                     # JetBrains Mono font files (.ttf)
├── Assets.xcassets                # App icons and color assets
├── Info.plist                     # App configuration
├── PhantomGate.entitlements       # Sandbox and audio permissions
└── PhantomGateApp.swift          # Main application entry point

PhantomGateTests/               # Unit tests
PhantomGateUITests/            # UI automation tests
```

### Key Components and Files

**Main Application Components**:
- `PhantomGateApp.swift`: Application lifecycle and dependency injection
- `AudioEngine.swift`: AVAudioEngine wrapper for noise generation
- `MenuBarManager.swift`: NSStatusItem management and menu creation
- `FloatingWindowManager.swift`: Floating control window implementation
- `FontManager.swift`: JetBrains Mono font registration

**Testing Components**:
- `PhantomGateTests.swift`: Basic smoke tests
- `AudioEngineTests.swift`: Audio engine functionality
- `FontManagerTests.swift`: Font management testing
- `UIComponentTests.swift`: UI component logic testing
- `AsyncTests.swift`: Async operation testing
- `IntegrationTests.swift`: Component integration testing

### Configuration Files

- `.swiftlint.yml`: SwiftLint configuration (excludes Packages directory)
- `PhantomGate.entitlements`: Sandbox permissions for audio input and network access
- `Info.plist`: Application metadata and configuration
- `.github/workflows/lint.yml`: CI pipeline for code quality

### Common Command Reference

```bash
# Project root contents
ls -la
# .github/ .swiftlint.yml PhantomGate/ PhantomGate.xcodeproj/ PhantomGateTests/ PhantomGateUITests/ README.md

# Build and test commands
xcodebuild -scheme PhantomGate build              # Build only
xcodebuild -scheme PhantomGate test               # Build and test
xcodebuild -scheme PhantomGate clean              # Clean build artifacts

# Development workflow
swiftlint                                         # Check code style
swiftlint --fix                                   # Auto-fix style issues
open PhantomGate.xcodeproj                        # Open in Xcode
```

### Audio Permissions and Entitlements

The application requires specific entitlements for proper operation:
- `com.apple.security.device.audio-input`: Audio input access for processing
- `com.apple.security.app-sandbox`: App sandbox compliance
- `com.apple.security.network.client`: Network access for feedback submission

### Development Workflows

**Adding New Features**:
1. Always update relevant tests first
2. Implement feature in appropriate component
3. Run full test suite to verify no regressions
4. Test manually using validation scenarios above
5. Run SwiftLint and fix any issues
6. Test keyboard shortcuts and menu bar integration

**Audio Engine Changes**:
1. Modify `AudioEngine.swift` for core audio logic
2. Update `MenuBarManager.swift` for menu integration
3. Update `FloatingWindowManager.swift` for UI controls
4. Test all noise types and audio transitions
5. Verify no audio artifacts or memory leaks

**UI Changes**:
1. Update SwiftUI views in `UI/` directory
2. Test floating window behavior and positioning
3. Verify menu bar integration remains functional
4. Test accessibility features and keyboard navigation
5. Update UI tests if interface changes significantly

## Important Notes

- **Menu Bar Application**: This is NOT a traditional windowed app - it lives in the menu bar
- **Audio Permissions**: First launch requires user to grant microphone permissions
- **Sandbox Environment**: App runs in macOS App Sandbox with restricted permissions
- **Font Dependencies**: Application uses custom JetBrains Mono fonts (included in Resources/)
- **macOS Version**: Minimum deployment target is macOS 15.5 (Sequoia)
- **Development Platform**: All build and test commands require macOS with Xcode - cannot be run on Linux/Windows

## Platform Limitations

**Commands that work ONLY on macOS**:
- `xcodebuild` (building and testing)
- `open PhantomGate.xcodeproj` (opening Xcode project)
- `swiftlint` (unless using CI)
- Actual application execution and UI testing

**Commands that are validated in CI**:
- SwiftLint checks (via GitHub Actions on Ubuntu)
- Code quality validation
- Git operations and file validation

## Troubleshooting

**Build Issues**:
- Verify Xcode 15.0+ is installed and selected: `xcode-select --print-path`
- Clean build folder: Product → Clean Build Folder in Xcode
- Reset simulator if UI tests fail: Device → Erase All Content and Settings

**Audio Issues**:
- Check system audio permissions in System Settings → Privacy & Security → Microphone
- Verify no other audio applications are blocking AVAudioEngine
- Test with different noise types to isolate issues

**UI Testing Issues**:
- Ensure `--ui-testing` launch argument is set for UI tests
- Reset simulator state between test runs
- Menu bar testing has limitations - focus on core UI functionality

Always perform complete validation testing after any changes to ensure the application functions correctly as a macOS menu bar application.