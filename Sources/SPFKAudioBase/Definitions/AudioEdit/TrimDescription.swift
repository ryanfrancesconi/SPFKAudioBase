// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// Describes an in/out trim window applied to an audio file or region.
/// Both values default to 0, meaning no trim is applied on that side.
///
/// Invariants: both values must be >= 0; when both are non-zero, inPoint < outPoint.
public struct TrimDescription: Equatable, Sendable {
    /// Start of the playback/render window in seconds. 0 means start from the beginning.
    public var inPoint: TimeInterval = 0 {
        didSet { inPoint = max(0, inPoint) }
    }

    /// End of the playback/render window in seconds. 0 means play to the end of the file.
    public var outPoint: TimeInterval = 0 {
        didSet { outPoint = max(0, outPoint) }
    }

    /// True when no trim is configured.
    public var isEmpty: Bool { inPoint == 0 && outPoint == 0 }

    public init(inPoint: TimeInterval = 0, outPoint: TimeInterval = 0) {
        precondition(inPoint >= 0, "TrimDescription: inPoint (\(inPoint)) must be >= 0")
        precondition(outPoint >= 0, "TrimDescription: outPoint (\(outPoint)) must be >= 0")
        precondition(
            !(inPoint > 0 && outPoint > 0 && inPoint >= outPoint),
            "TrimDescription: inPoint (\(inPoint)) must be < outPoint (\(outPoint)) when both are set"
        )
        self.inPoint = inPoint
        self.outPoint = outPoint
    }
}

// MARK: - Codable

extension TrimDescription: Codable {
    private enum CodingKeys: String, CodingKey {
        case inPoint, outPoint
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let decodedIn = try c.decodeIfPresent(TimeInterval.self, forKey: .inPoint) ?? 0
        let decodedOut = try c.decodeIfPresent(TimeInterval.self, forKey: .outPoint) ?? 0

        guard decodedIn >= 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .inPoint, in: c,
                debugDescription: "inPoint (\(decodedIn)) must be >= 0"
            )
        }
        guard decodedOut >= 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .outPoint, in: c,
                debugDescription: "outPoint (\(decodedOut)) must be >= 0"
            )
        }
        guard !(decodedIn > 0 && decodedOut > 0 && decodedIn >= decodedOut) else {
            throw DecodingError.dataCorruptedError(
                forKey: .outPoint, in: c,
                debugDescription: "inPoint (\(decodedIn)) must be < outPoint (\(decodedOut)) when both are set"
            )
        }

        inPoint = decodedIn
        outPoint = decodedOut
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(inPoint, forKey: .inPoint)
        try c.encode(outPoint, forKey: .outPoint)
    }
}
