//
//  AudioEngineError.swift
//  PhantomGate
//
//  Created by David Jensenius on 2025-08-22.
//

enum AudioEngineError: Error {
    case formatCreationFailed
    case engineStartFailed(Error)
    case noAudioFormat
}
