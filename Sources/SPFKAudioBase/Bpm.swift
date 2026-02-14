import Foundation
import SPFKBase

public struct Bpm: Equatable, Sendable, Comparable, Hashable, Codable {
    public static let tempoRange: ClosedRange<Bpm> = Bpm(1)! ... Bpm(1024)!

    public static let _60bpm = Bpm(60)!
    public static let _120bpm = Bpm(120)!

    public static func < (lhs: Bpm, rhs: Bpm) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public let rawValue: Double

    public var stringValue: String {
        if isWholeNumber {
            return "\(Int(rawValue))"
        }

        return "\(rawValue)"
    }

    public var quarterNoteDuration: TimeInterval {
        60.0 / rawValue
    }

    public let multiples: [Double]

    public var isWholeNumber: Bool {
        rawValue.truncatingRemainder(dividingBy: 1) == 0
    }

    public init?(_ rawValue: Double) {
        guard rawValue > 0 else {
            Log.error("Bpm must be a positive value > 0")
            return nil
        }

        self.rawValue = rawValue

        multiples = [0.125, 0.25, 0.5, 1, 2, 4, 8].map {
            rawValue * $0
        }
    }

    /// x8 to /8 values, E.g., 80 Bpm == 160 Bpm/
    public func isMultiple(of rhs: Double) -> Bool {
        guard let testValue = Bpm(rhs) else { return false }

        return isMultiple(of: testValue)
    }

    /// x8 to /8 values, E.g., 80 Bpm == 160 Bpm/
    public func isMultiple(of rhs: Bpm) -> Bool {
        multiples.contains(rhs.rawValue)
    }
}

extension Bpm: CustomStringConvertible {
    public var description: String {
        "Bpm(\(stringValue))"
    }
}

extension [Bpm] {
    public var average: Bpm? {
        let value = map(\.rawValue).averaged.rounded(.toNearestOrEven)
        return Bpm(value)
    }
}
