// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import AVFoundation
import Foundation
import SPFKBase

/// Detects non-silent regions in an audio file and returns them as a time-ordered
/// array of ``TrimDescription`` values.
///
/// Wraps ``AudioSilenceScanner`` to locate non-silent frame ranges, then converts
/// each range to seconds, applies pre/post-roll padding, and discards segments
/// shorter than ``SegmentDetectorOptions/minimumSegmentDuration``.
public struct SegmentDetector: Sendable {
    public let options: SegmentDetectorOptions

    public init(options: SegmentDetectorOptions = SegmentDetectorOptions()) {
        self.options = options
    }

    /// Detect non-silent segments in an audio file.
    /// - Parameter audioFile: The file to analyze. The file must be open for reading.
    /// - Returns: A time-ordered array of ``TrimDescription`` values, one per detected segment.
    public func detect(in audioFile: AVAudioFile) async throws -> [TrimDescription] {
        let scanner = AudioSilenceScanner(silenceThreshold: options.linearThreshold)

        let regions = try await scanner.nonSilentRegions(
            in: audioFile,
            minimumSilenceDuration: options.minimumSilenceDuration
        )

        guard !regions.isEmpty else { return [] }

        let sampleRate = audioFile.processingFormat.sampleRate
        let totalDuration = Double(audioFile.length) / sampleRate

        return regions.compactMap { range in
            // lowerBound is the first audio frame; upperBound is the last audio frame (inclusive).
            // Add 1 to upperBound to get the exclusive end frame, matching AVAudioFile semantics.
            let rawIn = Double(range.lowerBound) / sampleRate
            let rawOut = (Double(range.upperBound) + 1.0) / sampleRate

            let paddedIn = max(0, rawIn - options.preRollPadding)
            let paddedOut = min(totalDuration, rawOut + options.postRollPadding)

            guard paddedOut - paddedIn >= options.minimumSegmentDuration else { return nil }

            return TrimDescription(inPoint: paddedIn, outPoint: paddedOut)
        }
    }
}
