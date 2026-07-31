// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase

extension AudioEditDescription {
    /// The effective playback duration after accounting for any pending trim.
    /// When no trim is set, returns `fileDuration` unchanged.
    public func effectiveDuration(fileDuration: TimeInterval) -> TimeInterval {
        let start = trim.inPoint
        let end = trim.outPoint > 0 ? trim.outPoint : fileDuration
        return max(0, end - start)
    }

    /// Returns a copy with fade times proportionally clamped to fit within the effective
    /// trimmed duration. When no trim is set the clamp is against the raw file duration.
    /// Taper curves are preserved unchanged.
    public func clampingFadesToTrim(fileDuration: TimeInterval) -> AudioEditDescription {
        let duration = effectiveDuration(fileDuration: fileDuration)
        let clamped = AudioEditDescription.clampedFades(
            inTime: fade.inTime,
            outTime: fade.outTime,
            duration: duration
        )
        return settingFades(inTime: clamped.inTime, outTime: clamped.outTime)
    }

    /// Proportionally clamps fade-in and fade-out so their sum does not exceed `duration`.
    /// When the total exceeds `duration`, both are scaled down by the same factor so each
    /// fade retains its relative proportion. Returns the original values unchanged otherwise.
    public static func clampedFades(
        inTime: TimeInterval,
        outTime: TimeInterval,
        duration: TimeInterval
    ) -> (inTime: TimeInterval, outTime: TimeInterval) {
        let total = inTime + outTime
        guard total > duration, total > 0 else {
            return (inTime, outTime)
        }
        let scale = duration / total
        return (inTime * scale, outTime * scale)
    }

    /// Returns a copy with `inTime` and `outTime` replaced by the given values.
    /// All other fields (`trim`, `fade.inTaper`, `fade.outTaper`) are preserved.
    public func settingFades(inTime: TimeInterval, outTime: TimeInterval) -> AudioEditDescription {
        var copy = self
        copy.fade.inTime = inTime
        copy.fade.outTime = outTime
        return copy
    }

    /// Returns a copy with both fades zeroed.
    /// All other fields (`trim`, `fade.inTaper`, `fade.outTaper`) are preserved.
    public func clearingFades() -> AudioEditDescription {
        settingFades(inTime: 0, outTime: 0)
    }

    /// Returns fade durations derived from a waveform selection, respecting any trim region.
    ///
    /// The fade-in applies when the selection starts at or before the trim start (inPoint, or
    /// time 0 when no trim is set). Its duration is measured from the trim start to the selection
    /// end — not from the selection start — so the fade covers the region actually drawn.
    ///
    /// The fade-out applies when the selection ends at or after the trim end (outPoint, or the
    /// file duration when no trim is set). Its duration is measured from the selection start to
    /// the trim end for the same reason.
    ///
    /// Returns `nil` when the selection is fully interior — no trim boundary is touched and no
    /// meaningful fade can be inferred.
    public static func selectionFades(
        selectionStart: TimeInterval,
        selectionEnd: TimeInterval,
        duration: TimeInterval,
        trim: TrimDescription = TrimDescription(),
        tolerance: TimeInterval = 0.001
    ) -> (inTime: TimeInterval, outTime: TimeInterval)? {
        guard selectionEnd > selectionStart, duration > 0 else { return nil }

        let trimStart = trim.inPoint
        let trimEnd = trim.outPoint > 0 ? trim.outPoint : duration

        let atStart = selectionStart <= trimStart + tolerance
        let atEnd = selectionEnd >= trimEnd - tolerance
        guard atStart || atEnd else { return nil }

        return (
            inTime: atStart ? max(0, selectionEnd - trimStart) : 0,
            outTime: atEnd ? max(0, trimEnd - selectionStart) : 0
        )
    }
}
