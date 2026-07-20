// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
//import SwiftExtensions

extension RealTimeDomain {
    /// Used to generate and store different real-time duration strings for use in dynamic UI display such as Library browser tree duration label and search results table Duration column.
    public struct DisplayString: Hashable, Codable {
        /// MM:SS
        /// seconds will always round-up, unless seconds == 0.0
        public let compact: String

        /// MM:SS.mmm, or H:MM:SS.mmm if minutes >=60
        public let full: String

        public init(compact: String, full: String) {
            self.compact = compact
            self.full = full
        }

        /// Used to generate and store different real-time duration strings for use in dynamic UI display such as Library browser tree duration label and search results table Duration column.
        public init(seconds: TimeInterval) {
            // always round compact duration up to next second (which is an acceptable convention) and helps ensure sounds that are <1 second don't display as "00:00"
            let durationCompact = seconds == 0.0 ? 0.0 : seconds.rounded(.up)

            compact = RealTimeDomain.string(seconds: durationCompact,
                                            showHours: .auto,
                                            showMilliseconds: false)

            // do not modify/round the full string, of course
            full = RealTimeDomain.string(seconds: seconds,
                                         showHours: .auto,
                                         showMilliseconds: true)
        }

        /// Returns the `.compact` string if `forWidth < widthThreshold`.
        /// Otherwise returns the `.full` string.
        public func string(forWidth width: CGFloat,
                           widthThreshold: CGFloat) -> String
        {
            width < widthThreshold ? compact : full
        }
    }
}
