// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase
import SwiftExtensions

/// The five EBU R128 loudness metrics for an audio file.
///
/// All properties are optional — a `nil` value means the metric was not measured
/// or fell outside the representable range (±99.99). Use ``isValid`` to check
/// whether at least one meaningful metric is present, and ``validated()`` to
/// clear any out-of-range values.
///
/// Conforms to `Codable` for serialization, `Comparable` (ordered by integrated
/// loudness), and `Hashable`.
public struct LoudnessDescription: Comparable, Hashable, Sendable, Codable {
    /// Orders two descriptions by integrated loudness.
    ///
    /// Returns `false` if either value is `nil`.
    public static func < (lhs: LoudnessDescription, rhs: LoudnessDescription) -> Bool {
        guard let lhs = lhs.loudnessIntegrated,
              let rhs = rhs.loudnessIntegrated else { return false }

        return lhs < rhs
    }

    /// Integrated loudness (LUFS) — the gated, overall program loudness per ITU-R BS.1770-4.
    public var loudnessIntegrated: Float64?

    /// Loudness range (LU) — the statistical distribution of loudness per EBU Tech 3342.
    public var loudnessRange: Float64?

    /// Maximum true peak level (dBTP) — the highest inter-sample peak across all channels.
    public var maxTruePeakLevel: Float32?

    /// Maximum momentary loudness (LUFS) — the highest value from sliding 400 ms windows.
    public var maxMomentaryLoudness: Float64?

    /// Maximum short-term loudness (LUFS) — the highest value from sliding 3 s windows.
    public var maxShortTermLoudness: Float64?

    /// A formatted summary of all metrics, e.g. `"I -24.1 LUFS, TP -0.1 dB, LRA 1.4 LU, M -19.5 LU, S -23.0 LU"`.
    ///
    /// Metrics that are `nil` display as `"N/A"`. Momentary and short-term values are
    /// omitted entirely when `nil`.
    public var stringValue: String {
        var out = ""

        let lufsString = loudnessIntegrated?.string(decimalPlaces: 1) ?? "N/A"
        out += "I \(lufsString) LUFS, "

        let truePeakString = maxTruePeakLevel?.string(decimalPlaces: 1) ?? "N/A"
        out += "TP \(truePeakString) dB, "

        let loudnessRangeString = loudnessRange?.string(decimalPlaces: 1) ?? "N/A"
        out += "LRA \(loudnessRangeString) LU"

        if let value = maxMomentaryLoudness?.string(decimalPlaces: 1) {
            out += ", M \(value) LU"
        }

        if let value = maxShortTermLoudness?.string(decimalPlaces: 1) {
            out += ", S \(value) LU"
        }

        return out
    }

    /// Creates a loudness description with the given metric values.
    ///
    /// All parameters default to `nil`, allowing partial construction when only
    /// some metrics are available.
    public init(
        loudnessIntegrated: Float64? = nil,
        loudnessRange: Float64? = nil,
        maxTruePeakLevel: Float32? = nil,
        maxMomentaryLoudness: Float64? = nil,
        maxShortTermLoudness: Float64? = nil
    ) {
        self.loudnessIntegrated = loudnessIntegrated
        self.loudnessRange = loudnessRange
        self.maxTruePeakLevel = maxTruePeakLevel
        self.maxMomentaryLoudness = maxMomentaryLoudness
        self.maxShortTermLoudness = maxShortTermLoudness
    }

    /// Returns `true` if the value falls within the representable EBU R128 range of ±99.99.
    ///
    /// Values outside this range (e.g. `0x7FFF / 100 = 327.67`, a common sentinel)
    /// are considered invalid.
    static func isValid(value: some BinaryFloatingPoint & Comparable) -> Bool {
        (-99.99 ... 99.99).contains(value)
    }

    /// Returns a copy with any out-of-range metrics set to `nil`.
    ///
    /// Each property is checked against the ±99.99 range. Values that fall outside
    /// (including common sentinel values like `0x7FFF / 100`) are cleared.
    public func validated() -> LoudnessDescription {
        var desc = self

        if let value = loudnessIntegrated, !Self.isValid(value: value) {
            desc.loudnessIntegrated = nil
        }

        if let value = loudnessRange, !Self.isValid(value: value) {
            desc.loudnessRange = nil
        }

        if let value = maxTruePeakLevel, !Self.isValid(value: value) {
            desc.maxTruePeakLevel = nil
        }

        if let value = maxMomentaryLoudness, !Self.isValid(value: value) {
            desc.maxMomentaryLoudness = nil
        }

        if let value = maxShortTermLoudness, !Self.isValid(value: value) {
            desc.maxShortTermLoudness = nil
        }

        return desc
    }

    /// Whether this description contains at least one usable metric.
    ///
    /// Returns `true` if any of ``loudnessIntegrated``, ``maxTruePeakLevel``,
    /// ``maxMomentaryLoudness``, or ``maxShortTermLoudness`` is non-nil.
    /// ``loudnessRange`` is excluded because a value of zero is valid.
    public var isValid: Bool {
        loudnessIntegrated != nil ||
            maxTruePeakLevel != nil ||
            maxMomentaryLoudness != nil ||
            maxShortTermLoudness != nil
    }
}

extension [LoudnessDescription] {
    /// The arithmetic mean of each metric across all valid descriptions.
    ///
    /// Invalid descriptions (per ``LoudnessDescription/isValid``) are filtered out
    /// before averaging. Each metric is averaged independently — if a metric is `nil`
    /// in some descriptions, only the non-nil values contribute to its mean.
    /// Returns an empty (invalid) description if the array contains no valid entries.
    public var average: LoudnessDescription {
        var out = LoudnessDescription()

        let values = self.map { $0.validated() }.filter(\.isValid)

        guard values.isNotEmpty else {
            return out
        }

        let loudnessValue = values.compactMap(\.loudnessIntegrated)
        if loudnessValue.count > 0 {
            out.loudnessIntegrated = loudnessValue.reduce(0, +) / Float64(loudnessValue.count)
        }

        let loudnessRange = values.compactMap(\.loudnessRange)
        if loudnessRange.count > 0 {
            out.loudnessRange = loudnessRange.reduce(0, +) / Float64(loudnessRange.count)
        }

        let truePeak = values.compactMap(\.maxTruePeakLevel)
        if truePeak.count > 0 {
            out.maxTruePeakLevel = truePeak.reduce(0, +) / Float32(truePeak.count)
        }

        let maxMomentaryLoudness = values.compactMap(\.maxMomentaryLoudness)
        if maxMomentaryLoudness.count > 0 {
            out.maxMomentaryLoudness = maxMomentaryLoudness.reduce(0, +) / Float64(maxMomentaryLoudness.count)
        }

        let maxShortTermLoudness = values.compactMap(\.maxShortTermLoudness)
        if maxShortTermLoudness.count > 0 {
            out.maxShortTermLoudness = maxShortTermLoudness.reduce(0, +) / Float64(maxShortTermLoudness.count)
        }

        return out
    }
}
