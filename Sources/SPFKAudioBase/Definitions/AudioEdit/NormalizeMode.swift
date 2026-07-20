// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// Algorithm used during a normalization analysis pass.
public enum NormalizeMode: String, Codable, Sendable, CaseIterable {
    /// EBU R128 integrated loudness measurement.
    case lufs
    /// Sample peak measurement.
    case peak
}
