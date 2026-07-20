// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

extension Bpm {
    /// Creates a `Bpm` by parsing a string that contains a recognizable tempo pattern.
    ///
    /// Recognized patterns (case-insensitive):
    /// - `Tempo: 120` / `Tempo 120`
    /// - `BPM 120` / `BPM120`
    /// - `120 BPM` / `120bpm`
    ///
    /// Returns `nil` if no pattern matches or the extracted value is not a valid tempo.
    public init?(tempoString: String) {
        guard let rawValue = Self.extractTempoValue(from: tempoString),
              let bpm = Bpm(rawValue) else { return nil }
        self = bpm
    }

    private static func extractTempoValue(from string: String) -> Double? {
        // "Tempo: 120", "Tempo 120", "BPM 120", "BPM120"
        if let match = string.firstMatch(of: /(?i)(?:tempo[: ]+|bpm[ ]*)(\d+(?:\.\d+)?)/) {
            return Double(String(match.output.1))
        }

        // "120 BPM", "120bpm"
        if let match = string.firstMatch(of: /(?i)(\d+(?:\.\d+)?)[ ]*bpm/) {
            return Double(String(match.output.1))
        }

        return nil
    }
}
