// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// Describes which metadata types and individual fields to transfer during a Paste Attributes operation.
///
/// Section-level `Bool` flags control entire sections. Per-field exclusion sets
/// allow individual fields within a section to be skipped while the section is enabled.
///
/// String key conventions (used in excluded-field sets):
/// - `excludedTagKeys` — `TagKey.rawValue`
/// - `excludedBEXTFields` — `BEXTDescription.Key.displayName`
/// - `excludedIXMLFields` — `IXMLTagDescriptor.identifier` (`"section.xmlTag"`)
public struct PasteAttributesOptions: Codable, Sendable, Hashable {
    // MARK: - Section Toggles

    public var tags: Bool
    public var bext: Bool
    public var ixml: Bool
    public var markers: Bool
    public var image: Bool
    public var finderTags: Bool

    // MARK: - Per-Field Exclusions

    /// `TagKey.rawValue` strings to skip within the Tags section.
    public var excludedTagKeys: Set<String>

    /// `BEXTDescription.Key.displayName` strings to skip within the BEXT section.
    public var excludedBEXTFields: Set<String>

    /// `IXMLTagDescriptor.identifier` strings to skip within the iXML section.
    public var excludedIXMLFields: Set<String>

    // MARK: - Init

    public init(
        tags: Bool = true,
        bext: Bool = true,
        ixml: Bool = true,
        markers: Bool = true,
        image: Bool = true,
        finderTags: Bool = true,
        excludedTagKeys: Set<String> = [],
        excludedBEXTFields: Set<String> = [],
        excludedIXMLFields: Set<String> = []
    ) {
        self.tags = tags
        self.bext = bext
        self.ixml = ixml
        self.markers = markers
        self.image = image
        self.finderTags = finderTags
        self.excludedTagKeys = excludedTagKeys
        self.excludedBEXTFields = excludedBEXTFields
        self.excludedIXMLFields = excludedIXMLFields
    }

    // MARK: - Presets

    /// Copy all metadata types with no field exclusions.
    public static let all = PasteAttributesOptions()

    /// Skip all metadata types.
    public static let none = PasteAttributesOptions(
        tags: false, bext: false, ixml: false,
        markers: false, image: false, finderTags: false
    )
}
