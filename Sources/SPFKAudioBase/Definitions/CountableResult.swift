import Foundation

/// Track results and determine the most frequent entry.
public struct CountableResult<T: Hashable & Sendable>: ExpressibleByArrayLiteral {
    public enum TieBreakerWeight {
        case first
        case last
    }

    public private(set) var results: [T] = []
    public private(set) var suggestedValue: T?
    public var matchesRequired: Int?

    public init(arrayLiteral elements: T...) {
        results = elements
    }

    public init(elements: [T] = []) {
        results = elements
    }

    public init(matchesRequired: Int? = nil) {
        self.matchesRequired = matchesRequired
    }

    /// Append a value and check if it meets the required match threshold
    public mutating func append(_ value: T) -> Bool {
        results.append(value)

        let count = results.count(where: { $0 == value })

        if let matchesRequired, count >= matchesRequired {
            suggestedValue = value
            return true
        }

        return false
    }

    public func choose(tieBreakerWeight: TieBreakerWeight = .first) -> T? {
        if let suggestedValue { return suggestedValue }

        guard !results.isEmpty else { return nil }

        let frequencyMap: [T: Int] = results.reduce(into: [:]) { counts, value in
            counts[value, default: 0] += 1
        }

        // Find the highest frequency count
        guard let maxCount = frequencyMap.values.max() else { return nil }

        // Filter for all keys that share that maxCount
        let candidates = frequencyMap.filter { $0.value == maxCount }.map(\.key)

        // if there's more than one, pick the one that appeared first in the original array
        if candidates.count > 1 {
            return tieBreakerWeight == .first ?
                results.first { candidates.contains($0) } :
                results.last { candidates.contains($0) }
        }

        return candidates.first
    }
}
