// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

extension AudioEditDescription {
    /// Returns a copy with `trim` replaced by the given value.
    /// All other fields (`fade`) are preserved.
    public func settingTrim(_ trim: TrimDescription) -> AudioEditDescription {
        var copy = self
        copy.trim = trim
        return copy
    }

    /// Returns a copy with trim cleared to a default `TrimDescription()`.
    /// All other fields (`fade`) are preserved.
    public func clearingTrim() -> AudioEditDescription {
        settingTrim(TrimDescription())
    }

    /// Returns trim points derived from a waveform selection, using the same boundary-detection
    /// logic as `selectionFades`. Returns `nil` when the selection is fully interior.
    ///
    /// When the selection starts at or near time 0 (within `tolerance`), `inPoint` equals the
    /// selection end. When it ends at or near the file duration, `outPoint` equals the selection
    /// start. Both conditions can apply when the selection spans nearly the entire file.
    public static func selectionTrim(
        selectionStart: TimeInterval,
        selectionEnd: TimeInterval,
        duration: TimeInterval,
        tolerance: TimeInterval = 0.1
    ) -> (inPoint: TimeInterval, outPoint: TimeInterval)? {
        let selDuration = selectionEnd - selectionStart
        guard selDuration > 0, duration > 0 else { return nil }

        let atStart = selectionStart < tolerance
        let atEnd = selectionEnd > duration - tolerance
        guard atStart || atEnd else { return nil }

        return (inPoint: atStart ? selectionEnd : 0, outPoint: atEnd ? selectionStart : 0)
    }
}
