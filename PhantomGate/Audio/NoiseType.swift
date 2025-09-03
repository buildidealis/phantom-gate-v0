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
            }
        }
}
