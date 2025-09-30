# PhantomGate Setup Guide

This guide provides step-by-step instructions for properly configuring PhantomGate with Zoom and other video conferencing applications.

## Understanding the Audio Routing

PhantomGate works by:
1. **Capturing** your voice from your hardware microphone (MacBook Pro mic, external mic, etc.)
2. **Mixing** your voice with privacy protection audio (noise/disruption)
3. **Routing** the combined audio to BlackHole 2ch virtual microphone
4. **Applications** (like Zoom) pick up the combined audio from BlackHole 2ch

## Prerequisites

### 1. Install BlackHole

BlackHole is a virtual audio driver that allows PhantomGate to route audio to other applications.

1. Download BlackHole from [https://existential.audio/blackhole/](https://existential.audio/blackhole/)
2. Install the BlackHole 2ch package
3. Restart your Mac after installation
4. Verify installation:
   - Open **System Settings** → **Sound**
   - You should see "BlackHole 2ch" in the Input devices list

### 2. Configure macOS System Audio Settings

**IMPORTANT**: This is the critical step that determines whether your voice will be heard.

#### System Input (Microphone) Settings

1. Open **System Settings** → **Sound** → **Input**
2. Select your **hardware microphone** (NOT BlackHole):
   - "MacBook Pro Microphone" (for built-in mic)
   - Or your external microphone name
   - **DO NOT select "BlackHole 2ch" here** - this creates a feedback loop

#### System Output (Speaker) Settings

1. Open **System Settings** → **Sound** → **Output**  
2. Select your **headphones or speakers**:
   - Your headphones (recommended to prevent feedback)
   - Built-in speakers (if not using headphones)
   - **DO NOT select "BlackHole 2ch" here** - you won't hear anything

## Zoom Configuration

### Method 1: Standard Setup (Recommended)

This method provides the best balance of audio quality and protection.

1. **Start PhantomGate**:
   - Launch PhantomGate (appears as "PG" in menu bar)
   - Click "Start Protection" or press ⌘+B
   - Verify protection is active

2. **Configure Zoom Audio Settings**:
   - Open Zoom
   - Go to **Settings** → **Audio**
   - **Microphone**: Select "BlackHole 2ch"
   - **Speakers**: Select your headphones or speakers (NOT BlackHole)
   - Test audio to ensure you can hear others

3. **Join Meeting and Test**:
   - Join a Zoom meeting
   - Unmute yourself
   - Speak - others should hear your voice mixed with protection audio
   - If not working, see Troubleshooting section below

### Method 2: Using Multi-Output Device (Advanced)

**Note**: This method is typically NOT needed for PhantomGate. It's mentioned here because some users may have it configured, but it's not the recommended approach.

If you previously created a Multi-Output device:
1. Remove it from your system audio settings
2. Follow Method 1 (Standard Setup) instead
3. PhantomGate handles all audio routing automatically

## Other Video Conferencing Apps

### Microsoft Teams

1. Start PhantomGate protection (⌘+B)
2. Open Teams → **Settings** → **Devices**
3. **Microphone**: Select "BlackHole 2ch"
4. **Speakers**: Select your headphones/speakers
5. Test in a meeting

### Discord

1. Start PhantomGate protection (⌘+B)
2. Open Discord → **User Settings** → **Voice & Video**
3. **Input Device**: Select "BlackHole 2ch"
4. **Output Device**: Select your headphones/speakers
5. Test in a voice channel

### Google Meet

1. Start PhantomGate protection (⌘+B)
2. Join a Google Meet session
3. Click the three dots (⋮) → **Settings**
4. **Microphone**: Select "BlackHole 2ch"
5. **Speakers**: Select your headphones/speakers
6. Test audio

## Troubleshooting

### Problem: "Others cannot hear me in Zoom"

**Solution 1: Check System Audio Input**
1. Open **System Settings** → **Sound** → **Input**
2. Ensure your **hardware microphone** is selected (MacBook Pro Microphone, etc.)
3. **Do NOT have BlackHole selected** in system input
4. Restart PhantomGate protection

**Solution 2: Verify Zoom Microphone Setting**
1. Zoom → **Settings** → **Audio**
2. Microphone should be "BlackHole 2ch"
3. Click "Test Mic" to verify audio is being received
4. If no audio bars appear, restart PhantomGate

**Solution 3: Check PhantomGate is Running**
1. Verify "PG" icon is in menu bar
2. Click PG → verify "Stop Protection" is shown (protection is active)
3. If "Start Protection" is shown, click it to start
4. Return to Zoom and test again

**Solution 4: Restart Audio Chain**
1. Stop PhantomGate protection (⌘+B)
2. Leave Zoom meeting
3. Restart PhantomGate protection (⌘+B)
4. Rejoin Zoom meeting
5. Verify Zoom microphone is "BlackHole 2ch"

### Problem: "I hear echo or feedback"

**Solution:**
1. Ensure system output is NOT set to BlackHole
2. Use headphones instead of speakers
3. Check Zoom speaker settings are correct
4. Reduce microphone gain in PhantomGate settings (if available)

### Problem: "BlackHole 2ch not appearing in Zoom"

**Solution:**
1. Verify BlackHole is installed: System Settings → Sound → Input
2. If not visible, reinstall BlackHole
3. Restart your Mac
4. Restart Zoom
5. Check Zoom audio settings again

### Problem: "Audio quality is poor or distorted"

**Solution:**
1. Check system microphone input level isn't too high
2. Ensure sample rates match (44.1kHz recommended)
3. Try different protection types in PhantomGate
4. Reduce protection intensity if option is available
5. Check network connection quality

### Problem: "Protection not working against AI transcription"

**Solution:**
1. Verify Zoom is actually using BlackHole as microphone
2. Try different protection types (Pink Babble often most effective)
3. Ensure protection is active before joining meeting
4. Test with QuickTime recording to verify protection audio is present

## Best Practices

1. **Start protection BEFORE joining meetings** - Ensures audio routing is established
2. **Use headphones** - Prevents feedback and echo issues
3. **Test your setup** - Use Zoom's "Test Mic" feature before important meetings
4. **Keep system input on hardware mic** - Never set system input to BlackHole
5. **Monitor protection status** - Check PG menu bar icon regularly

## Common Configuration Mistakes

❌ **WRONG**: Setting system input to BlackHole 2ch
✅ **CORRECT**: System input should be your hardware microphone

❌ **WRONG**: Setting system output to BlackHole 2ch  
✅ **CORRECT**: System output should be your speakers/headphones

❌ **WRONG**: Starting Zoom before PhantomGate protection
✅ **CORRECT**: Start PhantomGate protection first, then join Zoom

❌ **WRONG**: Creating complex Multi-Output or Aggregate devices
✅ **CORRECT**: Use simple setup - let PhantomGate handle routing

## How It Works (Technical Overview)

For those interested in understanding the audio flow:

```
[Your Hardware Mic] 
       ↓
[PhantomGate AudioEngine]
       ↓
[Mix with Protection Audio]
       ↓
[Output to BlackHole 2ch]
       ↓
[Zoom/Teams/Discord picks up from BlackHole]
       ↓
[Transmitted to meeting participants]
```

PhantomGate automatically:
- Captures from your hardware microphone (system default input)
- Mixes your voice with privacy protection audio
- Routes ONLY the combined audio to BlackHole 2ch
- Keeps your system speakers silent (no protection noise in your ears)

## Support

If you continue to experience issues after following this guide:

1. Document your exact configuration:
   - macOS version
   - PhantomGate version  
   - System audio input device
   - System audio output device
   - Application microphone setting
   - Application speaker setting

2. Test with QuickTime recording to verify audio flow

3. Contact support with the above information

---

*Last updated: 2024*
