# PhantomGate Testing Guide

This document provides comprehensive testing procedures for PhantomGate, a macOS audio privacy application. These tests help ensure the application works correctly across different scenarios and can effectively protect against various AI transcription systems.

## Prerequisites

### Required Hardware Setup

- **Headphones**: Always use headphones during testing to prevent audio feedback loops
- **macOS System**: macOS 15.5 or later
- **Audio Input Device**: Built-in microphone or external microphone
- **Internet Connection**: For testing against cloud-based AI transcription services

### Required Software Setup

1. **PhantomGate Application**: [Download from release page](https://github.com/buildidealis/phantom-gate-v0/releases)
2. **BlackHole Virtual Audio Driver**: Required for audio protection functionality
3. **QuickTime Player**: For audio recording tests
4. **Video Conferencing Applications**: Zoom, Microsoft Teams, Discord, Google Meet, etc.

## BlackHole Setup for Testing

### Installing BlackHole

1. **Download and Install**:
   ```bash
   # Option 1: Direct download
   # Visit https://existential.audio/blackhole/
   # Download BlackHole.2ch.pkg
   
   # Option 2: From PhantomGate menu
   # Click "PG" in menu bar → "Install BlackHole for Protection…"
   ```

2. **Verify Installation**:
   - Open **System Settings** → **Sound**
   - Confirm "BlackHole 2ch" appears in both Input and Output device lists
   - If not visible, restart macOS and check again

3. **Create Aggregate Device** (NOT RECOMMENDED - Only for advanced testing):
   - **Note**: This is typically NOT needed. PhantomGate handles audio routing automatically.
   - Open **Audio MIDI Setup** (`/Applications/Utilities/Audio MIDI Setup.app`)
   - Click "+" → "Create Aggregate Device"
   - Name it "Testing Aggregate"
   - Check both your built-in microphone and "BlackHole 2ch"
   - **Warning**: Using aggregate devices can complicate setup and is not the recommended approach

### Critical Audio Routing Configuration

**IMPORTANT**: For all tests, ensure proper audio routing to prevent feedback and ensure voice capture:

1. **Set System Audio Input to Hardware Microphone** (CRITICAL):
   - System Settings → Sound → Input
   - Select your hardware microphone: "MacBook Pro Microphone" or external mic
   - ⚠️ **NEVER select "BlackHole 2ch" as system input** - this prevents voice capture

2. **Set System Audio Output to Headphones/Speakers**:
   - System Settings → Sound → Output
   - Select your headphones or speakers (NOT BlackHole)

3. **Application-Specific Setup**:
   - Target applications (Zoom, Teams, etc.) should use "BlackHole 2ch" as microphone input
   - PhantomGate will route protection audio through BlackHole automatically
   - PhantomGate captures YOUR VOICE from the system's default input (hardware mic)

**Common Mistake**: Setting system input to BlackHole before starting PhantomGate. This creates a feedback loop and prevents your voice from being captured. Always keep system input on your hardware microphone.

For detailed setup instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md).

## Stress Testing Scenarios

### Application Crash Testing

#### 1. Rapid Menu Interactions
```bash
# Test rapid clicking of menu bar items
1. Launch PhantomGate
2. Rapidly click "PG" menu bar icon (10+ times per second for 30 seconds)
3. Rapidly toggle "Show/Hide Main Window" 
4. Rapidly toggle protection on/off with ⌘+B
5. Expected: No crashes, responsive UI
```

#### 2. Audio Engine Stress Tests
```bash
# Test audio engine under load
1. Start protection with Green noise
2. Rapidly switch between noise types (Green → Pink → Pink Babble → Advanced modes)
3. Switch noise types every 1-2 seconds for 5 minutes
4. Monitor for audio artifacts, memory leaks, or crashes
5. Test all advanced modes: Spectral Sweep, Temporal Jitter, Whisper Mask, etc.
```

#### 3. System Resource Exhaustion
```bash
# Test under high system load
1. Open 10+ applications simultaneously
2. Start multiple audio/video applications (QuickTime, GarageBand, etc.)
3. Enable PhantomGate protection
4. Run CPU-intensive tasks in background
5. Monitor for crashes or audio dropouts
```

#### 4. Virtual Audio Driver Manipulation
```bash
# Test BlackHole driver manipulation
1. Start PhantomGate protection
2. Manually remove BlackHole via System Settings (if possible)
3. Reinstall BlackHole while protection is running
4. Change system audio devices rapidly
5. Expected: Graceful error handling, no crashes
```

#### 5. Memory and Performance Testing
```bash
# Long-running stability test
1. Enable protection and leave running for 24+ hours
2. Monitor Activity Monitor for memory leaks
3. Test with different noise types periodically
4. Check CPU usage stays reasonable (<5% idle, <20% active)
```

#### 6. Edge Case Scenarios
```bash
# Test unusual system states
1. Start protection, then put Mac to sleep
2. Wake from sleep and verify protection continues
3. Test during macOS user switching
4. Test with external audio interfaces connected/disconnected
5. Test with Bluetooth headphones connecting/disconnecting
```

## AI Transcription Testing

### Overview

Test PhantomGate's effectiveness against popular AI transcription services. The goal is to verify that protection audio prevents accurate speech recognition while allowing normal conversation for human listeners.

### Test Setup for AI Services

1. **Audio Configuration**:
   - Set system audio output to headphones
   - Set target application input to "BlackHole 2ch"
   - Start PhantomGate protection before testing

2. **Test Script Preparation**:
   Create a standard test phrase to use consistently:
   ```
   "This is a test of PhantomGate audio protection. 
   I am speaking clearly and loudly. 
   The current time is [current time].
   My name is [test name] and I am testing transcription accuracy.
   Please transcribe this message if you can hear it clearly."
   ```

### Zoom Testing

#### Setup
1. **Install Zoom** (if not already installed)
2. **Configure Audio**:
   - Zoom Settings → Audio → Microphone: "BlackHole 2ch"
   - Zoom Settings → Audio → Speaker: Your headphones
3. **Enable Transcription**:
   - Start a test meeting (can be solo)
   - Enable "Live Transcript" or "Record Meeting with Transcript"

#### Test Procedure
```bash
# Baseline Test (without protection)
1. Start Zoom meeting
2. Speak test script clearly
3. Verify transcription accuracy (should be >90% accurate)
4. Save transcript for comparison

# Protection Tests
1. Start PhantomGate protection (Green noise)
2. Speak same test script
3. Check transcription accuracy (should be significantly degraded)
4. Repeat with Pink noise, Pink Babble, and Advanced modes
5. Test different intensity levels if available
6. Document which mode provides best protection
```

### Microsoft Teams Testing

#### Setup
1. **Configure Teams Audio**:
   - Teams Settings → Devices → Microphone: "BlackHole 2ch"
   - Teams Settings → Devices → Speaker: Your headphones
2. **Enable Live Captions**:
   - Start test meeting
   - Enable "Turn on live captions"

#### Test Procedure
```bash
# Follow same procedure as Zoom testing
1. Baseline without protection
2. Test each protection mode
3. Monitor live captions for transcription quality
4. Compare effectiveness across different noise types
```

### Discord Testing

#### Setup
1. **Configure Discord Audio**:
   - Discord Settings → Voice & Video → Input Device: "BlackHole 2ch"
   - Discord Settings → Voice & Video → Output Device: Your headphones
2. **Use Voice Channel with Bot Transcription** (if available)

#### Test Procedure
```bash
# Test in voice channel
1. Join voice channel
2. Test baseline speech recognition (if bots present)
3. Enable PhantomGate protection
4. Test transcription degradation
5. Verify other users can still understand you (if testing with real people)
```

### Google Meet Testing

#### Setup
1. **Browser Audio Settings**:
   - Chrome/Safari microphone permission: "BlackHole 2ch"
   - System audio output: Your headphones
2. **Enable Google Meet Captions**:
   - Start meeting → "Turn on captions"

#### Test Procedure
```bash
# Similar to other platforms
1. Test baseline transcription accuracy
2. Enable protection and test degradation
3. Test different protection modes
4. Document most effective settings
```

### QuickTime Audio Recording Tests

#### Purpose
Use QuickTime to record and analyze protection effectiveness offline.

#### Setup
1. **Configure QuickTime**:
   - QuickTime Player → File → New Audio Recording
   - Click dropdown next to record button
   - Select "BlackHole 2ch" as input source

#### Test Procedure
```bash
# Record protection samples
1. Start QuickTime audio recording
2. Enable different PhantomGate protection modes
3. Speak test script for each mode
4. Record 30-60 seconds per protection type
5. Save recordings with descriptive names:
   - "baseline_no_protection.m4a"
   - "green_noise_protection.m4a"
   - "pink_babble_protection.m4a"
   - "advanced_spectral_protection.m4a"

# Analysis
1. Play back recordings with headphones
2. Verify human intelligibility
3. Test recordings with external transcription services:
   - Upload to Rev.com, Otter.ai, or similar
   - Compare transcription accuracy
   - Document which modes provide best protection
```

### Additional AI Services Testing

#### Otter.ai
```bash
1. Use Otter mobile app or web interface
2. Configure to use BlackHole audio input (may require virtual audio setup)
3. Test real-time transcription with different protection modes
```

#### Apple's Built-in Dictation
```bash
1. Enable dictation in System Settings → Keyboard → Dictation
2. Set input to BlackHole or aggregate device
3. Test dictation accuracy with protection enabled
4. Use TextEdit or other apps to test dictation
```

#### Rev.com and Other Services
```bash
1. Record audio samples with QuickTime as described above
2. Upload recordings to transcription services
3. Compare accuracy across different protection modes
4. Document cost-effectiveness vs. protection quality
```

## Advanced Testing Scenarios

### Multi-Application Testing
```bash
# Test protection while multiple apps access audio
1. Start Zoom meeting with BlackHole input
2. Simultaneously start Discord voice chat
3. Open QuickTime recording
4. Enable PhantomGate protection
5. Verify all applications receive protection audio
6. Monitor for conflicts or audio routing issues
```

### Network and Latency Testing
```bash
# Test with various network conditions
1. Test on high-speed, low-latency network
2. Test on mobile hotspot with higher latency
3. Test with network interruptions
4. Verify protection remains effective during network issues
```

### Performance Impact Testing
```bash
# Measure system impact
1. Baseline system performance (Activity Monitor)
2. Enable protection and measure resource usage
3. Test impact on:
   - CPU usage
   - Memory consumption
   - Audio latency
   - Battery life (on laptops)
4. Compare across different protection modes
```

## Expected Results and Troubleshooting

### Successful Protection Indicators

1. **Transcription Degradation**: AI services should show significantly reduced accuracy (target: <30% vs >90% baseline)
2. **Human Intelligibility**: Your voice should still be understandable to human listeners
3. **System Stability**: No crashes, audio dropouts, or performance issues
4. **Consistent Performance**: Protection effectiveness should be consistent across sessions

### Common Issues and Solutions

#### "No Audio in Target Application"
```bash
# Solution steps:
1. Verify BlackHole is selected as microphone in target app
2. Check System Settings → Sound → Input shows BlackHole
3. Restart target application
4. Restart PhantomGate
5. Verify BlackHole installation with Audio MIDI Setup
```

#### "Protection Not Effective"
```bash
# Troubleshooting:
1. Increase protection intensity if available
2. Try different noise types (Pink Babble often most effective)
3. Verify audio is actually routing through BlackHole
4. Test with QuickTime recording to confirm protection audio presence
5. Check microphone gain levels
```

#### "Audio Feedback or Echo"
```bash
# Solution:
1. Confirm system audio output is set to headphones (NOT BlackHole)
2. Check target application speaker settings
3. Verify no aggregate device includes BlackHole as output
4. Reduce microphone gain if necessary
```

#### "App Crashes During Testing"
```bash
# Data collection:
1. Note exact steps that trigger crash
2. Check Console.app for crash logs
3. Document system configuration
4. Report with crash logs and reproduction steps
```

### Test Result Documentation

Create a testing log with the following format:

```
Date: [Date]
PhantomGate Version: [Version]
macOS Version: [Version]
Test Scenario: [Scenario Name]
Protection Mode: [Mode Used]
Target Application: [App Name/Version]
Result: [Pass/Fail/Partial]
Transcription Accuracy: [Baseline %] → [Protected %]
Notes: [Additional observations]
Issues Found: [Any problems encountered]
```

## Automated Testing Integration

For continuous integration, consider these automated tests:

```bash
# Basic functionality tests
1. Launch app and verify menu bar presence
2. Test protection enable/disable programmatically
3. Verify BlackHole detection logic
4. Test audio engine initialization
5. Monitor for memory leaks during automated runs
```

## Security and Privacy Considerations

### Testing Data Handling
- Use non-sensitive test phrases only
- Avoid real personal information in test scripts
- Consider using test accounts for cloud services
- Document any data uploaded to transcription services

### Protection Validation
- Regularly test against new AI transcription updates
- Verify protection remains effective as AI models improve
- Test against different languages if applicable
- Consider testing with different accent and speech patterns

## Conclusion

This testing guide provides comprehensive coverage for validating PhantomGate's functionality and effectiveness. Regular testing ensures the application continues to provide reliable audio privacy protection across different scenarios and against evolving AI transcription technologies.

For questions about testing procedures or to report issues discovered during testing, contact the development team through the application's feedback mechanism.
