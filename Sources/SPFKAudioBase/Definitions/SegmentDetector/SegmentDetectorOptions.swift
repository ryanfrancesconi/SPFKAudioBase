// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// Configuration for non-silent region detection in an audio file.
/// Used by ``SegmentDetector`` to control threshold, gap bridging,
/// minimum region length, and boundary padding.
public struct SegmentDetectorOptions: Equatable, Sendable, Codable {
    /// Silence threshold in dBFS. Samples at or below this level are treated as silence.
    /// Range: -96...0. Default: -60 dB.
    public var silenceThreshold: Float = -60

    /// A silence gap shorter than this is bridged and not treated as a segment boundary.
    /// Prevents a quiet moment within a sound from splitting one segment into two.
    /// Default: 0.1 s (100 ms).
    public var minimumSilenceDuration: TimeInterval = 0.1

    /// Segments shorter than this are discarded after detection.
    /// Useful for ignoring noise bursts shorter than any real content.
    /// Default: 0.5 s (500 ms).
    public var minimumSegmentDuration: TimeInterval = 0.5

    /// Padding subtracted from each detected segment's start time (clamped to 0).
    /// Captures the attack transient that begins just before the threshold crossing.
    /// Default: 0.005 s (5 ms).
    public var preRollPadding: TimeInterval = 0.005

    /// Padding added to each detected segment's end time (clamped to file duration).
    /// Captures natural decay that tails off below the threshold.
    /// Default: 0.005 s (5 ms).
    public var postRollPadding: TimeInterval = 0.005

    /// Silence threshold converted to linear amplitude for use with ``AudioSilenceScanner``.
    public var linearThreshold: Float {
        Float(pow(10.0, Double(silenceThreshold) / 20.0))
    }

    public init(
        silenceThreshold: Float = -60,
        minimumSilenceDuration: TimeInterval = 0.1,
        minimumSegmentDuration: TimeInterval = 0.5,
        preRollPadding: TimeInterval = 0.005,
        postRollPadding: TimeInterval = 0.005
    ) {
        self.silenceThreshold = silenceThreshold
        self.minimumSilenceDuration = minimumSilenceDuration
        self.minimumSegmentDuration = minimumSegmentDuration
        self.preRollPadding = preRollPadding
        self.postRollPadding = postRollPadding
    }

    // Forward-compatible decode: fields added in future versions fall back to their defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        silenceThreshold = try c.decodeIfPresent(Float.self, forKey: .silenceThreshold) ?? -60
        minimumSilenceDuration = try c.decodeIfPresent(TimeInterval.self, forKey: .minimumSilenceDuration) ?? 0.1
        minimumSegmentDuration = try c.decodeIfPresent(TimeInterval.self, forKey: .minimumSegmentDuration) ?? 0.5
        preRollPadding = try c.decodeIfPresent(TimeInterval.self, forKey: .preRollPadding) ?? 0.005
        postRollPadding = try c.decodeIfPresent(TimeInterval.self, forKey: .postRollPadding) ?? 0.005
    }
}
