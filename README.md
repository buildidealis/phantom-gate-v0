# PhantomGate

A minimalist macOS menu bar application designed for audio privacy and focus enhancement through broadband interference generation. PhantomGate provides different types of background noise to help mask conversations and create audio privacy in sensitive environments.

## Features

- **Menu Bar Integration**: Unobtrusive menu bar presence with quick access controls
- **Audio Protection System**: Requires BlackHole virtual audio driver for secure routing
- **Automatic Microphone Gain Control**: Auto-adjusts microphone levels for optimal audio (like Zoom)
- **Multiple Protection Types**: 
  - Green Noise: Even frequency distribution for general audio masking
  - Pink Noise: Balanced frequency response for ambient coverage
  - Pink Babble Noise: Combination of pink noise with subtle variations for enhanced privacy
  - Advanced Protection: Ultrasonic, chatter, and hybrid modes for sophisticated threats
- **Automatic Virtual Audio Routing**: All protection audio routes through BlackHole (system speakers stay silent)
- **Floating Control Window**: Optional floating interface for easy access to controls
- **Keyboard Shortcuts**: Quick protection toggle with ⌘+B
- **Real-time Audio Monitoring**: High-quality audio engine with frequency monitoring
- **Accessibility Support**: Full accessibility features for macOS

## System Requirements

- macOS 15.5 or later
- Swift 5.0+
- Xcode 15.0+ (for development)
- **BlackHole 2ch** (required for audio protection functionality)

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

## BlackHole Setup (Required for Audio Protection)

PhantomGate requires BlackHole, a modern macOS virtual audio driver, for its audio protection functionality. When protection is enabled, the app automatically routes all generated audio through BlackHole to other applications (like video conferencing software) while keeping your system speakers silent for privacy.

### Installing BlackHole

1. **Download BlackHole**:
   - Visit [https://existential.audio/blackhole/](https://existential.audio/blackhole/)
   - Download the latest BlackHole installer (free and open source)
   - Alternatively, use the "Install BlackHole for Protection…" option from PhantomGate's menu bar

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

**CRITICAL**: Proper audio configuration is essential for PhantomGate to work correctly.

#### System Audio Settings (Required)

1. **System Input (Microphone)**:
   - Open **System Settings** → **Sound** → **Input**
   - Select your **hardware microphone**:
     - "MacBook Pro Microphone" (built-in)
     - Or your external microphone
   - ⚠️ **DO NOT select "BlackHole 2ch"** - this will prevent your voice from being captured

2. **System Output (Speakers)**:
   - Open **System Settings** → **Sound** → **Output**
   - Select your headphones or speakers
   - ⚠️ **DO NOT select "BlackHole 2ch"** - you won't hear anything

For detailed setup instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md).

### Using Audio Protection Features

**Quick Start** (see [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions):

1. **Configure System Audio** (FIRST TIME ONLY):
   - System Settings → Sound → Input → Select your hardware microphone
   - System Settings → Sound → Output → Select your speakers/headphones
   - ⚠️ Never select BlackHole for system input or output

2. **Enable Audio Protection**:
   - With BlackHole installed, launch PhantomGate
   - Click "Start Protection" from the menu bar (⌘+B)
   - The app automatically routes all protection audio through BlackHole
   - Your system speakers remain silent for privacy

3. **Configure Target Applications**:
   - Open your video conferencing or recording software
   - Set microphone input to "BlackHole 2ch"
   - You should now hear PhantomGate's protection audio in the application

4. **Monitor and Control**:
   - Use PhantomGate's floating window to adjust protection types
   - Toggle protection on/off with ⌘+B shortcut
   - Protection automatically stops when you quit the application

### Troubleshooting Audio Protection

- **"Install BlackHole for Protection…" appears**: BlackHole is not detected. Install it and restart your Mac
- **"Protection Error" in menu**: BlackHole installation may be corrupted. Reinstall BlackHole
- **No audio in target app**: Check that "BlackHole 2ch" is selected as microphone input device
- **Others can't hear me in Zoom/Teams**: 
  - Verify your **system input is set to hardware microphone** (NOT BlackHole)
  - Check application microphone is set to "BlackHole 2ch"
  - Restart protection with ⌘+B
  - See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed troubleshooting
- **Audio quality issues**: Ensure sample rates match between PhantomGate (44.1kHz) and your applications
- **Protection won't start**: Ensure BlackHole is installed and PhantomGate has microphone permissions

For comprehensive troubleshooting, see [SETUP_GUIDE.md](SETUP_GUIDE.md).

## Usage

### Getting Started

1. **Install BlackHole**: Download and install BlackHole from the link in PhantomGate's menu
2. **Launch PhantomGate**: The app will appear in your menu bar as "PG"
3. **Enable the Interface**: Click "Show Main Window" to open the floating control window
4. **Start Protection**: Click "Start Protection" or use ⌘+B to begin audio protection
5. **Configure Apps**: Set your video conferencing software to use "BlackHole 2ch" as input

### Menu Options

- **Show/Hide Main Window**: Shows or hides the floating control window
- **Audio Protection** (requires BlackHole):
  - **Install BlackHole for Protection…**: Opens BlackHole download page (shown when BlackHole not detected)
  - **Start Protection**: Begins audio protection with automatic BlackHole routing (⌘+B)
  - **Stop Protection**: Stops audio protection (⌘+B)
- **Submit Feedback**: Opens email client to send feedback
- **Help**: Access help and support
- **Quit**: Exit the application (⌘+Q)

### Floating Control Window

When the main window is shown, PhantomGate displays a floating control window that allows you to:
- Select different audio protection types from a dropdown menu
- Start/stop audio protection with a dedicated button
- **Auto-Adjust Microphone**: Toggle automatic microphone level adjustment (enabled by default)
  - Automatically adjusts microphone gain to maintain optimal audio levels
  - Similar to Zoom's auto-adjust feature for consistent audio input
  - Requires microphone permissions to be granted to PhantomGate
  - Disable to manually control microphone gain with the slider
- Manually adjust microphone gain and noise volume levels
- Monitor real-time frequency information
- View animated waveform visualization
- Close the window while keeping protection running in the background

## Technical Architecture

PhantomGate is built using modern Swift and SwiftUI technologies:

- **Audio Engine**: Custom AVAudioEngine implementation for real-time broadband interference generation
- **Menu Bar Manager**: Native macOS menu bar integration
- **Floating Window Manager**: Custom window management for the floating interface
- **Font Management**: Integrated JetBrains Mono font for consistent typography

### Key Components

- `AudioEngine.swift`: Core audio processing and protection generation with integrated virtual mic routing
- `MenuBarManager.swift`: Menu bar interface and protection controls
- `FloatingWindowManager.swift`: Floating window controls and management
- `WaveformView.swift`: Real-time audio visualization
- `FontManager.swift`: Custom font loading and management
- `VirtualMicInjector.swift`: BlackHole audio routing and virtual microphone functionality
- `AudioEnhancer.swift`: Advanced protection features and audio enhancement

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
