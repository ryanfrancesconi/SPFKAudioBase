// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-musical-analysis

import Foundation
import SPFKBase

public enum NoteName: Int32, Sendable, Hashable, Equatable, CustomStringConvertible, CaseIterable {
    case c = 0
    case cSharp
    case d
    case dSharp
    case e
    case f
    case fSharp
    case g
    case gSharp
    case a
    case aSharp
    case b

    public init?(string: String) {
        for item in Self.allCases
            where item.description.equalsIgnoringCase(string) ||
            item.enharmonic.equalsIgnoringCase(string)
        {
            self = item
            return
        }

        return nil
    }

    public var description: String {
        switch self {
        case .c:
            "C"
        case .cSharp:
            "C#"
        case .d:
            "D"
        case .dSharp:
            "D#"
        case .e:
            "E"
        case .f:
            "F"
        case .fSharp:
            "F#"
        case .g:
            "G"
        case .gSharp:
            "G#"
        case .a:
            "A"
        case .aSharp:
            "A#"
        case .b:
            "B"
        }
    }

    public var enharmonic: String {
        switch self {
        case .cSharp:
            "Db"
        case .dSharp:
            "Eb"
        case .fSharp:
            "Gb"
        case .gSharp:
            "Ab"
        case .aSharp:
            "Bb"
        default:
            description
        }
    }
}
