//
//  VirtualMicState.swift
//  PhantomGate
//
//  Created by David Jensenius on 2025-08-22.
//


import Foundation

enum VirtualMicState: Equatable {
    case driverMissing
    case ready
    case streaming
    case error(String)
}
