// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// Specifies how pending audio edits (fades, trim, normalize) are handled during export operations.
public enum AudioEditHandling: String, Codable, Sendable, CaseIterable {
    /// Render pending audio edits to a temp file and use that as the source.
    case render

    /// Skip pending audio edits and export the original file unchanged.
    case ignore

    public var displayName: String {
        switch self {
        case .render: localized("Render")
        case .ignore: localized("Ignore")
        }
    }
}
