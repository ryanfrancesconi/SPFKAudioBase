import Foundation
import SPFKBase
import SwiftExtensions

public struct LoudnessDescription: Comparable, Hashable, Sendable {
    public static func < (lhs: LoudnessDescription, rhs: LoudnessDescription) -> Bool {
        guard let lhs = lhs.loudnessValue,
              let rhs = rhs.loudnessValue else { return false }

        return lhs < rhs
    }

    /// Integrated Loudness Value of the file in LUFS dB. (Note: Added in version 2.)
    public var loudnessValue: Float64?

    /// Loudness Range of the file in LU. (Note: Added in version 2.)
    public var loudnessRange: Float64?

    /// Maximum True Peak Value of the file (dBTP). (Note: Added in version 2.)
    public var maxTruePeakLevel: Float32?

    /// highest value of the Momentary Loudness Level of the file in LUFS dB. (Note: Added in version 2.)
    public var maxMomentaryLoudness: Float64?

    /// highest value of the Short-term Loudness Level of the file in LUFS dB. (Note: Added in version 2.)
    public var maxShortTermLoudness: Float64?

    /// A summary suitable for displaying in a UI
    public var shortDescription: String {
        var out = ""

        let lufsString = loudnessValue?.string(decimalPlaces: 1) ?? "N/A"
        out += "\(lufsString) LUFS, "

        let truePeakString = maxTruePeakLevel?.string(decimalPlaces: 1) ?? "N/A"
        out += "\(truePeakString) dBTP, "

        let loudnessRangeValue: Float64? = loudnessRange == 0 ? nil : loudnessRange
        let loudnessRangeString = loudnessRangeValue?.string(decimalPlaces: 1) ?? "N/A"
        out += "\(loudnessRangeString) LRA"

        return out
    }

    public init(
        loudnessValue: Float64? = nil,
        loudnessRange: Float64? = nil,
        maxTruePeakLevel: Float32? = nil,
        maxMomentaryLoudness: Float64? = nil,
        maxShortTermLoudness: Float64? = nil
    ) {
        self.loudnessValue = loudnessValue
        self.loudnessRange = loudnessRange
        self.maxTruePeakLevel = maxTruePeakLevel
        self.maxMomentaryLoudness = maxMomentaryLoudness
        self.maxShortTermLoudness = maxShortTermLoudness
    }
}

extension LoudnessDescription: Codable {
    enum CodingKeys: String, CodingKey {
        case loudnessRange
        case loudnessValue
        case maxMomentaryLoudness
        case maxShortTermLoudness
        case maxTruePeakLevel
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        loudnessValue = try? container.decodeIfPresent(Float64.self, forKey: .loudnessValue)
        loudnessRange = try? container.decodeIfPresent(Float64.self, forKey: .loudnessRange)
        maxTruePeakLevel = try? container.decodeIfPresent(Float32.self, forKey: .maxTruePeakLevel)
        maxMomentaryLoudness = try? container.decodeIfPresent(Float64.self, forKey: .maxMomentaryLoudness)
        maxShortTermLoudness = try? container.decodeIfPresent(Float64.self, forKey: .maxShortTermLoudness)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try? container.encodeIfPresent(loudnessValue, forKey: .loudnessValue)
        try? container.encodeIfPresent(loudnessRange, forKey: .loudnessRange)
        try? container.encodeIfPresent(maxTruePeakLevel, forKey: .maxTruePeakLevel)
        try? container.encodeIfPresent(maxMomentaryLoudness, forKey: .maxMomentaryLoudness)
        try? container.encodeIfPresent(maxShortTermLoudness, forKey: .maxShortTermLoudness)
    }
}

extension LoudnessDescription {
    public static func averageLoudness(from array: [LoudnessDescription]) -> LoudnessDescription {
        var out = LoudnessDescription()

        guard array.isNotEmpty else {
            return out
        }

        let loudnessValue = array.compactMap(\.loudnessValue).filter { !$0.isInfinite }
        if loudnessValue.count > 0 {
            out.loudnessValue = loudnessValue.reduce(0, +) / Float64(loudnessValue.count)
        }

        let loudnessRange = array.compactMap(\.loudnessRange)
        if loudnessRange.count > 0 {
            out.loudnessRange = loudnessRange.reduce(0, +) / Float64(loudnessRange.count)
        }

        let truePeak = array.compactMap(\.maxTruePeakLevel)
        if truePeak.count > 0 {
            out.maxTruePeakLevel = truePeak.reduce(0, +) / Float32(truePeak.count)
        }

        let maxMomentaryLoudness = array.compactMap(\.maxMomentaryLoudness)
        if maxMomentaryLoudness.count > 0 {
            out.maxMomentaryLoudness = maxMomentaryLoudness.reduce(0, +) / Float64(maxMomentaryLoudness.count)
        }

        let maxShortTermLoudness = array.compactMap(\.maxShortTermLoudness)
        if maxShortTermLoudness.count > 0 {
            out.maxShortTermLoudness = maxShortTermLoudness.reduce(0, +) / Float64(maxShortTermLoudness.count)
        }

        return out
    }
}
