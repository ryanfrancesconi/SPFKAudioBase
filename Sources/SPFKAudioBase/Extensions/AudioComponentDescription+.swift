// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/SPFKAudio

import AudioToolbox

extension AudioComponentDescription {
    /// Wildcard definition for AudioComponentCount lookup for any
    /// audio component
    public static var wildcard: AudioComponentDescription {
        AudioComponentDescription(
            componentType: 0,
            componentSubType: 0,
            componentManufacturer: 0,
            componentFlags: 0,
            componentFlagsMask: 0,
        )
    }

    // due to lack of Equatable
    public func matches(_ other: AudioComponentDescription) -> Bool {
        componentType == other.componentType &&
            componentSubType == other.componentSubType &&
            componentManufacturer == other.componentManufacturer
    }

    public var supportsIO: Bool {
        isEffect || isFormatConverter
    }

    public var isEffect: Bool {
        componentType == kAudioUnitType_Effect ||
            componentType == kAudioUnitType_MusicEffect
    }

    public var isFormatConverter: Bool {
        componentType == kAudioUnitType_FormatConverter
    }

    public var isMusicDevice: Bool {
        componentType == kAudioUnitType_MusicDevice
    }

    public var isGenerator: Bool {
        componentType == kAudioUnitType_Generator
    }

    public var validationCommand: String {
        "auval -v \(componentType.fourCC) \(componentSubType.fourCC) \(componentManufacturer.fourCC)"
    }
}
