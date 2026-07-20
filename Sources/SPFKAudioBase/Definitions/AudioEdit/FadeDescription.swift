// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// Describes a fade-in and fade-out applied to an audio file or region,
/// with independent taper curves for each direction.
public struct FadeDescription: Equatable, Sendable {
    /// Fade-in duration in seconds.
    public var inTime: TimeInterval = 0

    /// Fade-out duration in seconds.
    public var outTime: TimeInterval = 0

    /// Taper curve applied to the fade-in.
    public var inTaper: AudioTaper = .default

    /// Taper curve applied to the fade-out.
    public var outTaper: AudioTaper = .default

    /// True when no fade is configured.
    public var isEmpty: Bool { inTime == 0 && outTime == 0 }

    public init(
        inTime: TimeInterval = 0,
        outTime: TimeInterval = 0,
        inTaper: AudioTaper = .default,
        outTaper: AudioTaper = .default
    ) {
        self.inTime = inTime
        self.outTime = outTime
        self.inTaper = inTaper
        self.outTaper = outTaper
    }
}

// MARK: - Codable

extension FadeDescription: Codable {
    private enum CodingKeys: String, CodingKey {
        case inTime, outTime, inTaper, outTaper
        // Legacy key — present in JSON written before inTaper/outTaper were split.
        case taper
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        inTime = try c.decodeIfPresent(TimeInterval.self, forKey: .inTime) ?? 0
        outTime = try c.decodeIfPresent(TimeInterval.self, forKey: .outTime) ?? 0
        inTaper = try c.decodeIfPresent(AudioTaper.self, forKey: .inTaper) ?? .default
        outTaper = try c.decodeIfPresent(AudioTaper.self, forKey: .outTaper) ?? .default
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(inTime, forKey: .inTime)
        try c.encode(outTime, forKey: .outTime)
        try c.encode(inTaper, forKey: .inTaper)
        try c.encode(outTaper, forKey: .outTaper)
    }
}
