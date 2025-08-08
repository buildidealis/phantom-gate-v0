# PhantomGate

A minimalist macOS menu bar application designed for audio privacy and focus enhancement through broadband interference generation. PhantomGate provides different types of background noise to help mask conversations and create audio privacy in sensitive environments.

## Features

- **Menu Bar Integration**: Unobtrusive menu bar presence with quick access controls
- **Broadband Interference Options**: 
  - Green Noise: Even frequency distribution for general audio masking
  - Pink Noise: Balanced frequency response for ambient coverage
  - Pink Babble Noise: Combination of pink noise with subtle variations for enhanced privacy
- **Audio Scrambling**: Start/stop audio interference with intuitive controls
- **Floating Control Window**: Optional floating interface for easy access to controls
- **Keyboard Shortcuts**: Quick toggle with ⌘+B
- **Real-time Audio Monitoring**: High-quality audio engine with frequency monitoring
- **Accessibility Support**: Full accessibility features for macOS

## System Requirements

- macOS 15.5 or later
- Swift 5.0+
- Xcode 15.0+ (for development)

## Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/buildidealis/phantom-gate-v0.git
cd phantom-gate-v0
```

2. Open the project in Xcode:
```bash
open PhantomGate.xcodeproj
```

3. Build and run the project in Xcode (⌘+R)

## Usage

### Getting Started

1. Launch PhantomGate - it will appear in your menu bar as "PG"
2. Click the menu bar icon to access controls
3. Select "Enable/Disable" to activate the application
4. Choose "Toggle Noise" to start/stop audio interference
5. Use ⌘+B keyboard shortcut for quick noise toggling

### Menu Options

- **Enable/Disable**: Activates/deactivates the application and shows/hides the floating window
- **Toggle Noise**: Starts or stops audio interference generation (⌘+B)
- **Submit Feedback**: Opens email client to send feedback
- **Help**: Access help and support
- **Quit**: Exit the application (⌘+Q)

### Floating Control Window

When enabled, PhantomGate displays a floating control window that allows you to:
- Select different broadband interference types from a dropdown menu
- Start/stop audio scrambling with a dedicated button
- Monitor real-time frequency information
- View animated waveform visualization
- Close the window without disabling the app

## Technical Architecture

PhantomGate is built using modern Swift and SwiftUI technologies:

- **Audio Engine**: Custom AVAudioEngine implementation for real-time broadband interference generation
- **Menu Bar Manager**: Native macOS menu bar integration
- **Floating Window Manager**: Custom window management for the floating interface
- **Font Management**: Integrated JetBrains Mono font for consistent typography

### Key Components

- `AudioEngine.swift`: Core audio processing and interference generation
- `MenuBarManager.swift`: Menu bar interface and user interactions
- `FloatingWindowManager.swift`: Floating window controls and management
- `WaveformView.swift`: Real-time audio visualization
- `FontManager.swift`: Custom font loading and management

## Development

### Building from Source

1. Ensure you have Xcode 15.0+ installed
2. Clone the repository
3. Open `PhantomGate.xcodeproj` in Xcode
4. Select the PhantomGate scheme
5. Build and run (⌘+R)

### Testing

The project includes comprehensive test suites:

- **Unit Tests**: Core functionality testing in `PhantomGateTests/`
- **UI Tests**: Interface and interaction testing in `PhantomGateUITests/`

Run tests in Xcode with ⌘+U or from the command line:
```bash
xcodebuild test -scheme PhantomGate
```

### Project Structure

```
PhantomGate/
├── Audio/              # Audio engine and processing
├── UI/                 # User interface components
├── Utils/              # Utility classes and helpers
├── Resources/          # Fonts and assets
├── Assets.xcassets     # App icons and images
└── PhantomGateApp.swift # Main application entry point
```

## Support & Feedback

For support, bug reports, or feature requests, please contact:
- Email: lenzmariesa@gmail.com

---

*PhantomGate - Your gateway to audio privacy and focused productivity.*
