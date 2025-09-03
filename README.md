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

## BlackHole Setup (Required for Virtual Mic Functionality)

PhantomGate includes advanced virtual microphone capabilities that require BlackHole, a modern macOS virtual audio driver. This allows the app to route generated noise directly to other applications (like video conferencing software) as if it were coming from a real microphone.

### Installing BlackHole

1. **Download BlackHole**:
   - Visit [https://existential.audio/blackhole/](https://existential.audio/blackhole/)
   - Download the latest BlackHole installer (free and open source)
   - Alternatively, use the "Install Virtual Mic..." option from PhantomGate's menu bar

2. **Install BlackHole**:
   - Open the downloaded `.pkg` file
   - Follow the installation wizard
   - You may need to restart your Mac after installation
   - **Note**: BlackHole creates virtual audio devices; it doesn't install any background processes

3. **Verify Installation**:
   - Open **System Settings** → **Sound**
   - Look for "BlackHole 2ch" in both Input and Output device lists
   - If you don't see it, restart your Mac and check again

### Configuring macOS Audio Settings

1. **Set up Audio Routing**:
   - Launch PhantomGate (appears as "PG" in menu bar)
   - Click the PG icon and look for virtual mic options:
     - "Install Virtual Mic..." (if BlackHole not detected)
     - "Start Virtual Mic" (if BlackHole is ready)
     - "Stop Virtual Mic" (when streaming is active)

2. **Configure Applications**:
   - In video conferencing apps (Zoom, Teams, Discord, etc.)
   - Go to audio settings
   - Select "BlackHole 2ch" as your microphone input
   - This routes PhantomGate's noise generation directly to the application

3. **Optional: Create Aggregate Device** (Advanced):
   - Open **Audio MIDI Setup** (`/Applications/Utilities/`)
   - Click the "+" button → "Create Aggregate Device"
   - Check both your built-in microphone and "BlackHole 2ch"
   - This allows mixing your voice with PhantomGate's noise

### Using Virtual Mic Features

1. **Start Virtual Mic Streaming**:
   - With BlackHole installed, launch PhantomGate
   - Click "Start Virtual Mic" from the menu bar
   - Enable noise generation if not already running
   - The app will route audio to BlackHole device

2. **Configure Target Applications**:
   - Open your video conferencing or recording software
   - Set microphone input to "BlackHole 2ch"
   - You should now hear PhantomGate's noise in the application

3. **Monitor and Control**:
   - Use PhantomGate's floating window to adjust noise types
   - Toggle noise on/off with ⌘+B shortcut
   - Stop virtual mic streaming when not needed

### Troubleshooting BlackHole

- **BlackHole not detected**: Restart your Mac after installation
- **No audio in target app**: Check that "BlackHole 2ch" is selected as input device
- **Can't hear your own voice**: Use an Aggregate Device to combine built-in mic + BlackHole
- **Audio quality issues**: Ensure sample rates match between PhantomGate (44.1kHz) and your applications

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
- **Virtual Mic Options** (when BlackHole is installed):
  - **Install Virtual Mic...**: Opens BlackHole download page (shown when BlackHole not detected)
  - **Start Virtual Mic**: Begins streaming audio to BlackHole virtual device
  - **Stop Virtual Mic**: Stops streaming to virtual device
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

### Code Quality with SwiftLint (Optional)

This project uses SwiftLint to maintain consistent Swift code style and catch potential issues.

#### Installing SwiftLint

**Option 1: Homebrew (Recommended)**
```bash
brew install swiftlint
```

**Option 2: Download from GitHub**
- Visit [https://github.com/realm/SwiftLint/releases](https://github.com/realm/SwiftLint/releases)
- Download the latest SwiftLint.pkg
- Run the installer

#### Using SwiftLint

**Run linting:**
```bash
swiftlint
```

**Auto-fix issues (where possible):**
```bash
swiftlint --fix
```

**Configuration:**
The project includes a `.swiftlint.yml` configuration file with custom rules:
- File length warnings at 1700 lines, errors at 1800 lines
- Type body length warnings at 500 lines, errors at 800 lines
- Excludes the `Packages` directory from linting

**Integration with Xcode:**
SwiftLint can be integrated as a Build Phase in Xcode for automatic linting during builds. This is optional for local development but recommended for maintaining code quality.

## Support & Feedback

For support, bug reports, or feature requests, please contact:
- Email: lenzmariesa@gmail.com

---

*PhantomGate - Your gateway to audio privacy and focused productivity.*
