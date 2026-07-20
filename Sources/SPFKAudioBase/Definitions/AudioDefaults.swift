// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import SPFKBase

public actor AudioDefaults {
    static let defaultFormat: AVAudioFormat = .init(
        standardFormatWithSampleRate: 48000,
        channels: 2,
    ) ?? AVAudioFormat()

    public static let shared = AudioDefaults()
    private init() {}

    public private(set) var minimumSampleRateSupported: Double = 44100
    public private(set) var enforceMinimumSampleRate = false

    public private(set) lazy var systemFormat: AVAudioFormat = AudioDefaults.defaultFormat

    /// Snapshot intended for nonisolated reads; bypasses actor isolation.
    public private(set) nonisolated(unsafe) var unsafeSystemFormat: AVAudioFormat = AudioDefaults.defaultFormat

    public var sampleRate: Double {
        systemFormat.sampleRate
    }

    /// Update to sync to the current device
    public func update(systemFormat newValue: AVAudioFormat) {
        guard !enforceMinimumSampleRate || newValue.sampleRate >= minimumSampleRateSupported else {
            Log.debug(newValue.sampleRate, "isn't a supported sample rate, so ignoring this setting")
            return
        }

        systemFormat = newValue

        unsafeSystemFormat = newValue
    }

    public func isSupported(sampleRate: Double) -> Bool {
        guard enforceMinimumSampleRate else {
            return sampleRate > 0
        }

        return sampleRate >= minimumSampleRateSupported
    }

    public func update(minimumSampleRateSupported: Double) {
        guard minimumSampleRateSupported > 0 else { return }

        self.minimumSampleRateSupported = minimumSampleRateSupported
    }

    public func update(enforceMinimumSampleRate: Bool) {
        self.enforceMinimumSampleRate = enforceMinimumSampleRate
    }
}
