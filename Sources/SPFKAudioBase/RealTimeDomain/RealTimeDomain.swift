// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

public struct RealTimeDomain {
    public private(set) var masterSeconds: TimeInterval = 0.0

    public init() {}

    public mutating func update(seconds: TimeInterval) {
        masterSeconds = seconds
    }
}

// MARK: - Public Methods

extension RealTimeDomain {
    /// Generates a formatted string based on the current `masterSeconds` value.
    public func string(
        showHours: HoursFormat = .auto,
        showMilliseconds: Bool = true,
        offset: TimeInterval = 0.0
    ) -> String {
        Self.string(
            seconds: masterSeconds + offset,
            showHours: showHours,
            showMilliseconds: showMilliseconds
        )
    }
}
