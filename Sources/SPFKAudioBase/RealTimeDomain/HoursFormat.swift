// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

extension RealTimeDomain {
    /// Represents hours display behavior in string time formatting.
    public enum HoursFormat {
        /// Forces hours to display
        case enable

        /// Hides hours and allows minutes to be >60
        case disable

        /// Automatically shows hours if minutes are >60
        case auto
    }
}
