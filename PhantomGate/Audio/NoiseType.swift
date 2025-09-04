//
//  NoiseType.swift
//  PhantomGate
//
//  Created by David Jensenius on 2025-08-22.
//

enum NoiseType: String, CaseIterable {
    case green = "Green Noise"
    case pink = "Pink Noise"
    case pinkBabble = "Pink Babble"
    case ultrasonic = "Ultrasonic"
    case chatter = "Sine Waves"
    case hybrid = "Rotating Protection"
    
    // Advanced Disruptive Modes
    case spectralSweep = "Spectral Sweep"
    case temporalJitter = "Temporal Jitter"
    case whisperMask = "Whisper Mask"
    case pitchFormantDrift = "Pitch/Formant Drift"
    case phaseScramble = "Phase Scramble"
    case quantizePulse = "Quantize Pulse"
    case rotationCycle = "Rotation Cycle"

    var description: String {
        switch self {
        case .green:
            return "Traditional green noise masking"
        case .pink:
            return "Pink noise for speech masking"
        case .pinkBabble:
            return "Pink noise with babble overlay"
        case .ultrasonic:
            return "Silent ultrasonic/infrasonic frequencies only"
        case .chatter:
            return "Sine waves sweeping frequencies"
        case .hybrid:
            return "Alternates between protection methods"
        case .spectralSweep:
            return "Dynamic bandstop sweeps through vocal formants"
        case .temporalJitter:
            return "Micro time-jitter disrupts ASR alignment models"
        case .whisperMask:
            return "Band-limited whisperization with turbulent noise"
        case .pitchFormantDrift:
            return "Controlled pitch & formant divergence over time"
        case .phaseScramble:
            return "Randomizes phase while preserving magnitudes"
        case .quantizePulse:
            return "Alternating quantization with noise-shaped dither"
        case .rotationCycle:
            return "Cycles through spectral manipulation modes"
        }
    }
}
