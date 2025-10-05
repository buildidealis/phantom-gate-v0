# Quick Setup Fix for Voice Transmission Issue

If you previously had issues being heard in Zoom/Teams when using PhantomGate, follow these steps:

## The Fix

**The problem was**: System audio input was incorrectly set to BlackHole instead of your hardware microphone.

**The solution is**: Keep your system input on your hardware microphone, and only set Zoom/Teams to use BlackHole.

## Step-by-Step Setup (5 minutes)

### 1. Configure macOS System Audio
```
Open System Settings → Sound

Input Tab:
  ✅ Select: "MacBook Pro Microphone" (or your external mic)
  ❌ Do NOT select: "BlackHole 2ch"

Output Tab:
  ✅ Select: Your headphones or speakers
  ❌ Do NOT select: "BlackHole 2ch"
```

### 2. Configure Zoom
```
Open Zoom → Settings → Audio

Microphone:
  ✅ Select: "BlackHole 2ch"
  
Speakers:
  ✅ Select: Your headphones or speakers
```

### 3. Start PhantomGate Protection
```
1. Launch PhantomGate (PG icon in menu bar)
2. Click "Start Protection" or press ⌘+B
3. Verify protection is running
```

### 4. Join Zoom Meeting
```
1. Join your Zoom meeting
2. Unmute yourself
3. Speak - others should now hear you!
```

## How to Verify It's Working

1. **Before joining a meeting**: Use Zoom's "Test Mic" feature
   - You should see audio bars moving when you speak
   - This confirms Zoom is receiving audio from BlackHole

2. **In a meeting**: Ask a colleague if they can hear you
   - They should hear your voice mixed with subtle protection audio
   - The protection audio helps prevent AI transcription

## What Changed in This Update

### New Features
- **Input Validation**: PhantomGate now detects when system input is misconfigured
- **Warning Messages**: Console logs show helpful warnings if setup is incorrect
- **Comprehensive Guide**: See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions

### How to Check for Warnings
If PhantomGate detects a misconfiguration, it will print warnings to the console:

1. Open Console.app (in Applications → Utilities)
2. Filter for "PhantomGate"
3. Look for warning messages starting with "⚠️"
4. Follow the guidance in the warning messages

## Common Mistakes to Avoid

❌ **Wrong**: Setting system input to BlackHole
✅ **Correct**: System input should be your hardware microphone

❌ **Wrong**: Setting system output to BlackHole
✅ **Correct**: System output should be your headphones/speakers

❌ **Wrong**: Creating Multi-Output or Aggregate devices
✅ **Correct**: Use simple setup as described above

## Troubleshooting

### "Still can't hear me"
1. Restart PhantomGate protection (⌘+B twice)
2. Leave and rejoin Zoom meeting
3. Verify system input is hardware microphone (NOT BlackHole)
4. Check [SETUP_GUIDE.md](SETUP_GUIDE.md) troubleshooting section

### "Hearing echo or feedback"
1. Use headphones instead of speakers
2. Ensure system output is NOT BlackHole
3. Lower microphone gain in system preferences

### "BlackHole not appearing in Zoom"
1. Verify BlackHole is installed: System Settings → Sound
2. Restart Zoom
3. If still missing, reinstall BlackHole from https://existential.audio/blackhole/

## For More Help

- **Detailed Guide**: [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **Technical Details**: [ISSUE_RESOLUTION.md](ISSUE_RESOLUTION.md)
- **Testing Procedures**: [TESTING.md](TESTING.md)

---

*This fix addresses the issue reported by Mariesa & Apurva where users couldn't be heard in Zoom when using PhantomGate.*
