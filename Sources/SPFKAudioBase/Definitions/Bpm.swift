// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase

/// A tempo value in beats per minute.
///
/// `Bpm` is a value type that wraps a positive `Double` and provides
/// musical tempo utilities such as quarter-note duration, tempo multiples
/// (1/8x through 8x), and multiple-aware comparison for octave-equivalent
/// matching (e.g. 60 BPM matches 120, 240, etc.).
///
/// Returns `nil` from the failable initializer if the value is not positive.
public struct Bpm: Equatable, Sendable, Comparable, Hashable, Codable {
    /// The valid range of representable tempo values (1–1024 BPM).
    public static let tempoRange: ClosedRange<Bpm> = Bpm(1)! ... Bpm(1024)!

    /// 60 BPM — one beat per second.
    public static let bpm60 = Bpm(60)!

    /// 120 BPM — a common default tempo.
    public static let bpm120 = Bpm(120)!

    /// Orders two `Bpm` values by their raw tempo.
    public static func < (lhs: Bpm, rhs: Bpm) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// The tempo value in beats per minute.
    public let rawValue: Double

    /// A display string: integer when whole, decimal otherwise.
    public var stringValue: String {
        if isWholeNumber {
            return "\(Int(rawValue))"
        }

        return "\(rawValue)"
    }

    /// The duration of one quarter note at this tempo, in seconds.
    public var quarterNoteDuration: TimeInterval {
        60.0 / rawValue
    }

    /// The tempo at 1/8x, 1/4x, 1/2x, 1x, 2x, 4x, and 8x multiples.
    ///
    /// Used by ``isMultiple(of:tolerance:)-1o201`` for octave-equivalent matching.
    public let multiples: [Double]

    /// Whether the raw value has no fractional component.
    public var isWholeNumber: Bool {
        rawValue.truncatingRemainder(dividingBy: 1) == 0
    }

    /// Creates a `Bpm` from its string representation, returning `nil` if the string is not
    /// parseable as a positive number.
    public init?(parsing string: String) {
        guard let double = Double(string) else { return nil }
        self.init(double)
    }

    /// Creates a `Bpm` value, returning `nil` if `rawValue` is not positive.
    public init?(_ rawValue: Double) {
        guard rawValue > 0 else {
            Log.error("Bpm must be a positive value > 0")
            return nil
        }

        self.rawValue = rawValue

        multiples = [0.125, 0.25, 0.5, 1, 2, 4, 8].map {
            rawValue * $0
        }
    }

    /// Returns whether this tempo is an octave-equivalent multiple of `rhs`.
    ///
    /// Checks 1/8x through 8x multiples. For example, 80 BPM is a multiple
    /// of 160 BPM (at 1/2x). When `tolerance` is greater than zero, matches
    /// within that BPM range are accepted.
    public func isMultiple(of rhs: Double, tolerance: Double = 0) -> Bool {
        guard let testValue = Bpm(rhs) else { return false }

        return isMultiple(of: testValue, tolerance: tolerance)
    }

    /// Returns a new `Bpm` octave-shifted by multiplying or dividing by 2 until
    /// it falls within `range`. Returns `nil` if it cannot be brought into range.
    public func clamped(to range: ClosedRange<Float>) -> Bpm? {
        var value = rawValue
        let lo = Double(range.lowerBound)
        let hi = Double(range.upperBound)

        while value < lo {
            value *= 2
            if value > hi { return nil }
        }

        while value > hi {
            value /= 2
            if value < lo { return nil }
        }

        return Bpm(value)
    }

    /// Returns a new `Bpm` rounded to `decimalPlaces` decimal places.
    ///
    /// Use `decimalPlaces: 0` for integer rounding, 1–3 for fractional.
    public func rounded(to decimalPlaces: Int) -> Bpm? {
        guard decimalPlaces > 0 else {
            return Bpm(rawValue.rounded(.toNearestOrAwayFromZero))
        }
        let factor = pow(10.0, Double(decimalPlaces))
        let rounded = (rawValue * factor).rounded(.toNearestOrAwayFromZero) / factor
        return Bpm(rounded)
    }

    /// Returns whether this tempo is an octave-equivalent multiple of `rhs`.
    ///
    /// Checks 1/8x through 8x multiples. When `tolerance` is greater than zero,
    /// matches within that BPM range are accepted.
    public func isMultiple(of rhs: Bpm, tolerance: Double = 0) -> Bool {
        if tolerance <= 0 {
            return multiples.contains(rhs.rawValue)
        }
        return multiples.contains { abs($0 - rhs.rawValue) <= tolerance }
    }
}

extension Bpm {
    /// Returns a validated `Bpm` for `value` using ``clamped(to:)`` for octave-folding.
    ///
    /// Non-positive values are raised to the lower bound of ``tempoRange`` before folding.
    /// Out-of-range values are folded by halving or doubling (e.g. 2048 → 1024).
    /// Returns `nil` only if octave-folding cannot bring the value into range.
    public static func validate(_ value: Double) -> Bpm? {
        let range = Float(tempoRange.lowerBound.rawValue) ... Float(tempoRange.upperBound.rawValue)
        let positiveValue = max(tempoRange.lowerBound.rawValue, value)
        guard let bpm = Bpm(positiveValue) else { return nil }
        return bpm.clamped(to: range)
    }
}

extension Bpm: CustomStringConvertible {
    public var description: String {
        "Bpm(\(stringValue))"
    }
}

extension [Bpm] {
    /// The arithmetic mean of all BPM values, rounded to the nearest integer.
    public var average: Bpm? {
        let value = map(\.rawValue).averaged.rounded(.toNearestOrEven)
        return Bpm(value)
    }
}
