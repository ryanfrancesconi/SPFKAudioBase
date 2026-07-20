// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation
import SPFKBase

/// An async callback that receives ``URLProgressEvent`` updates during file processing.
public typealias URLProgressEventHandler = @Sendable (URLProgressEvent) async -> Void

/// Progress events emitted during URL-based file processing operations.
public enum URLProgressEvent: Sendable {
    /// Processing is underway, with the current progress as a 0–1 value.
    case progress(url: URL, value: UnitInterval)
    /// Processing has completed for the given URL.
    case complete(url: URL)

    /// The progress value (0–1). Returns 1 for ``complete``.
    public var progress: UnitInterval {
        switch self {
        case let .progress(url: _, value: progress):
            progress

        case .complete:
            1
        }
    }
}
