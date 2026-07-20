// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AudioToolbox
import Foundation

// MARK: - dB helpers

extension AUValue {
    /// Convert to dB from a linear
    public var dBValue: AUValue {
        20.0 * log10(self)
    }

    /// Convert from a dB value
    public var linearValue: AUValue {
        pow(10.0, self / 20)
    }

    public func dBString(decimalPlaces: Int = 1, dBMin: AUValue = -90) -> String {
        var out = ""
        let value = self

        let roundedDb = abs(
            value.rounded(decimalPlaces: 1)
        )

        if value <= dBMin {
            out = "∞"

        } else if roundedDb == 0 {
            out = "0 dB"

        } else {
            let sign = value > 0 ? "+" : "-"
            out = "\(sign)\(roundedDb) dB"
        }

        return out
    }
}
