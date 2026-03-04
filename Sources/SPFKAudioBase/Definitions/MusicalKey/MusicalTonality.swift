// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-musical-analysis

import Foundation

public enum MusicalTonality: Sendable, Hashable, Equatable, CustomStringConvertible, CaseIterable {
    case major
    case minor
    case unknown

    public var description: String {
        switch self {
        case .major:
            "Major"
        case .minor:
            "Minor"
        case .unknown:
            ""
        }
    }

    /// Initializes a Tonality from a string matching its description.
    /// - Parameter string: The string to match (e.g., "Major" or "minor").
    public init?(string: String) {
        guard !string.isEmpty else {
            self = .unknown
            return
        }

        for item in Self.allCases {
            if item.description.caseInsensitiveCompare(string) == .orderedSame {
                self = item
                return
            }
        }

        return nil
    }
}
