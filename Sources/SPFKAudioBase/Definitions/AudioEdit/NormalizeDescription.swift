// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import Foundation

/// Describes the result of a normalization analysis pass.
///
/// Stored on `PlaylistElement.audioEditDescription.normalize` and applied
/// via `RegionFadeDescription.maximumGain` during real-time playback.
/// The `gain` field is the only value needed at playback time; measurement
/// fields are stored for display purposes (e.g. playlist columns).
/// Measurement fields are `nil` when the analysis mode didn't produce them.
public struct NormalizeDescription: Equatable, Sendable {
    /// Measured integrated loudness in LUFS from the analysis pass. `nil` when
    /// analysis was run in Peak mode or has not been performed.
    public var measuredLUFS: Float? = nil

    /// True peak value in dBTP measured during analysis. `nil` when analysis
    /// was run in Peak mode or the analyzer did not report a true peak.
    public var truePeakdBTP: Float? = nil

    /// Measured sample peak in dBFS from the analysis pass. `nil` when analysis
    /// was run in LUFS mode or has not been performed.
    public var measuredPeakdBFS: Float? = nil

    /// Computed linear gain multiplier — the result of the gain clamp calculation.
    /// Handed to `RegionFadeDescription.maximumGain` so fade curves ramp to the
    /// normalized level, and set directly on the fader when no fade is active.
    public var gain: AUValue = 1

    /// True when gain is effectively unity — no normalization stored or needed.
    public var isEmpty: Bool { abs(gain - 1) < 0.001 }

    public init(
        measuredLUFS: Float? = nil,
        truePeakdBTP: Float? = nil,
        measuredPeakdBFS: Float? = nil,
        gain: AUValue = 1
    ) {
        self.measuredLUFS = measuredLUFS
        self.truePeakdBTP = truePeakdBTP
        self.measuredPeakdBFS = measuredPeakdBFS
        self.gain = gain
    }
}

// MARK: - Codable

extension NormalizeDescription: Codable {
    private enum CodingKeys: String, CodingKey {
        case measuredLUFS, truePeakdBTP, measuredPeakdBFS, gain
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        measuredLUFS = try c.decodeIfPresent(Float.self, forKey: .measuredLUFS)
        truePeakdBTP = try c.decodeIfPresent(Float.self, forKey: .truePeakdBTP)
        measuredPeakdBFS = try c.decodeIfPresent(Float.self, forKey: .measuredPeakdBFS)
        gain = try c.decodeIfPresent(AUValue.self, forKey: .gain) ?? 1
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(measuredLUFS, forKey: .measuredLUFS)
        try c.encodeIfPresent(truePeakdBTP, forKey: .truePeakdBTP)
        try c.encodeIfPresent(measuredPeakdBFS, forKey: .measuredPeakdBFS)
        try c.encode(gain, forKey: .gain)
    }
}
