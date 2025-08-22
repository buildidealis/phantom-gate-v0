import AVFoundation
import CoreAudio

final class AudioBufferQueue {
    private var buffers: [AVAudioPCMBuffer] = []
    private let lock = NSLock()

    func enqueue(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        buffers.append(buffer)
        lock.unlock()
    }

    func dequeue(into target: UnsafeMutablePointer<Float>, frameCount: Int) -> Int {
        lock.lock()
        defer { lock.unlock() }
        var framesWritten = 0
        while framesWritten < frameCount, !buffers.isEmpty {
            guard let buffer = buffers.first else { break }
            let availableFrames = Int(buffer.frameLength)
            let framesToCopy = min(availableFrames, frameCount - framesWritten)
            guard let channelData = buffer.floatChannelData, buffer.format.channelCount > 0 else {
                buffers.removeFirst()
                continue
            }
            let src = channelData[0]
            target.advanced(by: framesWritten).assign(from: src, count: framesToCopy)
            if framesToCopy == availableFrames {
                buffers.removeFirst()
            } else {
                let remainder = availableFrames - framesToCopy
                let format = buffer.format
                if let newBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(remainder)) {
                    newBuffer.frameLength = AVAudioFrameCount(remainder)
                    if let newChannelData = newBuffer.floatChannelData, format.channelCount > 0 {
                        newChannelData[0].assign(from: src.advanced(by: framesToCopy), count: remainder)
                    }
                    buffers[0] = newBuffer
                } else {
                    buffers.removeFirst()
                }
            }
            framesWritten += framesToCopy
        }
        return framesWritten
    }

    deinit {
        print("AudioBufferQueue deinit")
    }
}

final class VirtualMicInjector {
    enum InjectorError: Error {
        case deviceNotFound
        case audioUnit(OSStatus)
        case notStarted
    }

    private var audioUnit: AudioUnit?
    private let bufferQueue = AudioBufferQueue()
    private let sampleRate: Double
    private let channels: UInt32
    private(set) var isRunning = false
    private var deviceID: AudioDeviceID = kAudioObjectUnknown

    init(sampleRate: Double = 44100, channels: UInt32 = 1) {
        self.sampleRate = sampleRate
        self.channels = channels
    }

    func push(_ buffer: AVAudioPCMBuffer) {
        bufferQueue.enqueue(buffer)
    }

    func start(deviceName: String) throws {
        guard !isRunning else { return }
        deviceID = try findDevice(named: deviceName)
        try instantiateHAL()
        guard let unit = audioUnit else { throw InjectorError.notStarted }
        try check(AudioOutputUnitStart(unit))
        isRunning = true
    }

    func stop() {
        guard isRunning, let unit = audioUnit else { return }
        AudioOutputUnitStop(unit)
        AudioUnitUninitialize(unit)
        audioUnit = nil
        isRunning = false
    }

    deinit {
        print("VirtualMicInjector deinit")
        stop() // Defensive: ensures audio unit is always stopped before deallocation
    }

    private func instantiateHAL() throws {
        var desc = AudioComponentDescription(componentType: kAudioUnitType_Output,
                                             componentSubType: kAudioUnitSubType_HALOutput,
                                             componentManufacturer: kAudioUnitManufacturer_Apple,
                                             componentFlags: 0,
                                             componentFlagsMask: 0)

        guard let comp = AudioComponentFindNext(nil, &desc) else {
            throw InjectorError.audioUnit(-1)
        }

        var unit: AudioUnit?
        try check(AudioComponentInstanceNew(comp, &unit))
        guard let au = unit else { throw InjectorError.audioUnit(-1) }

        // Enable output scope
        var enable: UInt32 = 1
        try check(AudioUnitSetProperty(au,
                                       kAudioOutputUnitProperty_EnableIO,
                                       kAudioUnitScope_Output,
                                       0,
                                       &enable,
                                       UInt32(MemoryLayout.size(ofValue: enable))))

        // Set device
        var dev = deviceID
        try check(AudioUnitSetProperty(au,
                                       kAudioOutputUnitProperty_CurrentDevice,
                                       kAudioUnitScope_Global,
                                       0,
                                       &dev,
                                       UInt32(MemoryLayout.size(ofValue: dev))))

        // Stream format
        var asbd = AudioStreamBasicDescription(mSampleRate: sampleRate,
                                               mFormatID: kAudioFormatLinearPCM,
                                               mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
                                               mBytesPerPacket: 4 * channels,
                                               mFramesPerPacket: 1,
                                               mBytesPerFrame: 4 * channels,
                                               mChannelsPerFrame: channels,
                                               mBitsPerChannel: 32,
                                               mReserved: 0)
        try check(AudioUnitSetProperty(au,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Input,
                                       0,
                                       &asbd,
                                       UInt32(MemoryLayout.size(ofValue: asbd))))

        // Render callback
        var cb = AURenderCallbackStruct(inputProc: { refCon, _, _, _, frameCount, ioDataPointer in
            let queue = Unmanaged<AudioBufferQueue>
                .fromOpaque(refCon).takeUnretainedValue()
            guard let ioDataPointer else { return noErr }

            let bufferList = UnsafeMutableAudioBufferListPointer(ioDataPointer)
            for bufferIndex in bufferList.indices {
                guard let dataPointer = bufferList[bufferIndex].mData, frameCount > 0 else { continue }
                let floatPointer = dataPointer.assumingMemoryBound(to: Float.self)
                let framesWritten = queue.dequeue(into: floatPointer, frameCount: Int(frameCount))
                if framesWritten < Int(frameCount) {
                    memset(floatPointer.advanced(by: framesWritten), 0, Int(frameCount - UInt32(framesWritten)) * MemoryLayout<Float>.size)
                }
                bufferList[bufferIndex].mDataByteSize = UInt32(frameCount * 4)
            }
            return noErr
        }, inputProcRefCon: Unmanaged.passUnretained(bufferQueue).toOpaque())

        try check(AudioUnitSetProperty(au,
                                       kAudioUnitProperty_SetRenderCallback,
                                       kAudioUnitScope_Global,
                                       0,
                                       &cb,
                                       UInt32(MemoryLayout.size(ofValue: cb))))

        try check(AudioUnitInitialize(au))
        audioUnit = au
    }

    private func findDevice(named target: String) throws -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject),
                                                    &address,
                                                    0,
                                                    nil,
                                                    &dataSize)
        guard status == noErr else { throw InjectorError.audioUnit(status) }
        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                            &address,
                                            0,
                                            nil,
                                            &dataSize,
                                            &deviceIDs)
        guard status == noErr else { throw InjectorError.audioUnit(status) }

        for deviceID in deviceIDs {
            var nameAddress = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName,
                                                         mScope: kAudioObjectPropertyScopeGlobal,
                                                         mElement: kAudioObjectPropertyElementMain)
            var deviceName: CFString = "" as CFString
            var nameSize = UInt32(MemoryLayout<CFString>.size)
            if AudioObjectGetPropertyData(deviceID, &nameAddress, 0, nil, &nameSize, &deviceName) == noErr {
                if (deviceName as String).caseInsensitiveCompare(target) == .orderedSame {
                    return deviceID
                }
            }
        }
        throw InjectorError.deviceNotFound
    }

    private func check(_ status: OSStatus) throws {
        guard status == noErr else { throw InjectorError.audioUnit(status) }
    }
}
