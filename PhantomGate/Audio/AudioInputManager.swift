//
//  AudioInputManager.swift
//  PhantomGate
//
//  Created by Copilot on 2024-09-30.
//

import AVFoundation
import CoreAudio

/// Manages audio input device selection and validation
class AudioInputManager {

    /// Get all available audio input devices
    static func getInputDevices() -> [(id: AudioDeviceID, name: String)] {
        var devices: [(id: AudioDeviceID, name: String)] = []

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        )

        guard status == noErr else { return devices }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )

        guard status == noErr else { return devices }

        for deviceID in deviceIDs {
            // Check if device has input streams
            if hasInputStreams(deviceID) {
                if let name = getDeviceName(deviceID) {
                    devices.append((id: deviceID, name: name))
                }
            }
        }

        return devices
    }

    /// Check if device has input streams
    private static func hasInputStreams(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &address,
            0,
            nil,
            &dataSize
        )

        guard status == noErr else { return false }

        let bufferListSize = Int(dataSize)
        let bufferListPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferListSize)
        defer { bufferListPointer.deallocate() }

        let getDataStatus = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &dataSize,
            bufferListPointer
        )

        guard getDataStatus == noErr else { return false }

        let bufferList = UnsafeMutableAudioBufferListPointer(
            UnsafeMutablePointer<AudioBufferList>(
                OpaquePointer(bufferListPointer)
            )
        )

        return bufferList.count > 0
    }

    /// Get device name
    private static func getDeviceName(_ deviceID: AudioDeviceID) -> String? {
        var nameAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceNameRef: CFString?
        var nameSize = UInt32(MemoryLayout<CFString?>.size)

        let status = withUnsafeMutablePointer(to: &deviceNameRef) { ptr in
            AudioObjectGetPropertyData(
                deviceID,
                &nameAddress,
                0,
                nil,
                &nameSize,
                UnsafeMutableRawPointer(ptr)
            )
        }

        if status == noErr, let deviceName = deviceNameRef as String? {
            return deviceName
        }

        return nil
    }

    /// Get the default input device ID
    static func getDefaultInputDeviceID() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = kAudioObjectUnknown
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceID
        )

        return status == noErr && deviceID != kAudioObjectUnknown ? deviceID : nil
    }

    /// Find first hardware microphone (excludes virtual devices like BlackHole)
    static func findHardwareMicrophone() -> (id: AudioDeviceID, name: String)? {
        let devices = getInputDevices()

        // Filter out known virtual audio drivers
        let virtualDriverNames = [
            "blackhole",
            "loopback",
            "soundflower",
            "virtual"
        ]

        for device in devices {
            let lowercaseName = device.name.lowercased()
            let isVirtual = virtualDriverNames.contains { lowercaseName.contains($0) }

            if !isVirtual {
                return device
            }
        }

        return nil
    }

    /// Check if current default input is BlackHole or another virtual device
    static func isDefaultInputVirtual() -> Bool {
        guard let deviceID = getDefaultInputDeviceID(),
              let name = getDeviceName(deviceID) else {
            return false
        }

        let lowercaseName = name.lowercased()
        let virtualDriverNames = ["blackhole", "loopback", "soundflower", "virtual"]

        return virtualDriverNames.contains { lowercaseName.contains($0) }
    }

    /// Get a human-readable description of the current input device
    static func getCurrentInputDescription() -> String {
        guard let deviceID = getDefaultInputDeviceID(),
              let name = getDeviceName(deviceID) else {
            return "Unknown"
        }
        return name
    }
}
