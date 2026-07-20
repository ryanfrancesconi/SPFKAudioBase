// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SwiftExtensions

extension RealTimeDomain {
    /// Converts seconds into a time string (real time, not timecode).
    /// Milliseconds are truncated, not rounded.
    ///
    /// - Parameters:
    ///   - seconds: source seconds as a `TimeInterval`
    ///   - showHours: `enable` forces hours to display, `disable` hides hours and allows minutes to be >60, `nil` automatically shows hours if minutes are >60
    ///   - showMilliseconds: enables milliseconds display
    /// - Returns: resulting time format string
    public static func string(
        seconds: TimeInterval,
        showHours: HoursFormat,
        showMilliseconds: Bool = false
    ) -> String {
        let sign = seconds < 0.0 ? "-" : ""
        let absSeconds = seconds < 0.0 ? abs(seconds) : seconds

        let seconds = Int(absSeconds % 60)
        var minutes = Int(absSeconds / 60.0)

        var strHours: String = ""

        let enableHours = {
            strHours = String(minutes / 60) + ":"
            minutes = minutes % 60
        }

        switch showHours {
        case .auto:
            if minutes >= 60 { enableHours() }

        case .enable:
            enableHours()

        case .disable:
            strHours = ""
        }

        let strMinutes = (minutes < 10 ? "0" : "") + String(minutes) + ":"

        let strSeconds = (seconds < 10 ? "0" : "") + String(seconds)

        let strMilliseconds: String
        if showMilliseconds {
            let ms = Int(absSeconds * 1000) % 1000
            strMilliseconds = "." + String(ms / 100) + String((ms / 10) % 10) + String(ms % 10)
        } else {
            strMilliseconds = ""
        }

        return sign + strHours + strMinutes + strSeconds + strMilliseconds
    }

    /// Converts a time string (real time, not timecode) into seconds
    /// - Parameter string: an input string such as 00:30.50
    /// - Returns: a `TimeInterval` or `nil` if the parse failed
    public static func seconds(string: String) -> TimeInterval? {
        let allowedChars = "0123456789:;.-"

        var string = string.filter {
            allowedChars.contains($0)
        }

        let sign: FloatingPointSign = string.first == "-" ? .minus : .plus

        if sign == .minus {
            string = string.dropFirst().string
        }

        let delimiters = [":", ";"]
        let signValue: Double = sign == .minus ? -1 : 1

        for delimiter in delimiters {
            let components = string.components(separatedBy: delimiter)

            if components.count >= 2, let value = parse(components: components) {
                return signValue * value
            }
        }

        guard let value = TimeInterval(string) else {
            return nil
        }

        return signValue * value // assume 1.1234 fractional seconds
    }

    private static func parse(components: [String]) -> TimeInterval? {
        switch components.count {
        // hour 01:00:00.000
        case 3:
            let h = (components[0].double ?? 0) * 3600
            let m = (components[1].double ?? 0) * 60
            let s = (components[2].double ?? 0)
            return (h + m + s)

        // minutes 01:00.000
        case 2:
            let m = (components[0].double ?? 0) * 60
            let s = (components[1].double ?? 0)
            return (m + s)

        default:
            return nil
        }
    }
}
