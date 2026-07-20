// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// Controls whether the converter may increase the bit depth beyond the source.
public enum BitDepthRule: String, Sendable, Codable {
    /// Clamp the output bit depth to the source value (e.g. 16-bit source stays 16-bit).
    case lessThanOrEqual

    /// Allow any bit depth conversion, including upsampling.
    case any
}
