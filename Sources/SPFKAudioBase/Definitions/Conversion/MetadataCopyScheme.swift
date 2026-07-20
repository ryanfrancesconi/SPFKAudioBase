// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// Controls which metadata categories are copied when converting audio files.
///
/// Construct a custom scheme using the memberwise initializer, or use one of the
/// pre-defined static instances for common combinations.
public struct MetadataCopyScheme: Codable, Sendable, Equatable, Hashable {
    /// Copy text-based metadata: ID3 tags, Vorbis comments, INFO chunks, BEXT, iXML, XMP.
    public var text: Bool
    /// Copy markers: RIFF cue points, ID3 CHAP frames, Vorbis chapter fields.
    public var markers: Bool
    /// Copy embedded artwork.
    public var image: Bool
    /// Copy Finder tags (xattr color labels and custom text tags).
    public var finderTags: Bool

    public init(text: Bool = false, markers: Bool = false, image: Bool = false, finderTags: Bool = false) {
        self.text = text
        self.markers = markers
        self.image = image
        self.finderTags = finderTags
    }

    // MARK: - Named presets

    /// Copy all metadata: text, markers, image, and Finder tags.
    public static let copyAll = MetadataCopyScheme(text: true, markers: true, image: true, finderTags: true)

    /// Copy text-based metadata only; skip markers, image, and Finder tags.
    public static let copyText = MetadataCopyScheme(text: true)

    /// Copy markers only; skip text, image, and Finder tags.
    public static let copyMarkers = MetadataCopyScheme(markers: true)

    /// Copy text and markers; skip image and Finder tags.
    public static let copyTextAndMarkers = MetadataCopyScheme(text: true, markers: true)

    /// Copy text, image, and Finder tags; skip markers.
    public static let copyTextAndAssets = MetadataCopyScheme(text: true, image: true, finderTags: true)

    /// Ignore all metadata.
    public static let ignore = MetadataCopyScheme()

    // MARK: - UI

    /// Ordered presets for display in a picker or popup.
    public static let uiCases: [MetadataCopyScheme] = [
        .copyAll, .copyText, .copyMarkers, .copyTextAndMarkers, .ignore,
    ]

    // MARK: - Convenience accessors

    public var includesText: Bool { text }
    public var includesMarkers: Bool { markers }
    public var includesImage: Bool { image }
    public var includesFinderTags: Bool { finderTags }

    // MARK: - Display

    public var displayName: String {
        if self == .copyAll { return localized("Copy All") }
        if self == .copyText { return localized("Copy Text Based") }
        if self == .copyMarkers { return localized("Copy Markers") }
        if self == .copyTextAndMarkers { return localized("Copy Text and Markers") }
        if self == .copyTextAndAssets { return localized("Copy Text and Assets") }
        if self == .ignore { return localized("Ignore") }
        return "Custom"
    }
}
