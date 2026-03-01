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

    /// Optional custom match predicate. When provided, this is used instead of `==`
    /// for counting matches in `append` and grouping in `choose`.
    private let isMatch: (@Sendable (T, T) -> Bool)?

    /// Maintained incrementally when `isMatch` is set.
    /// Each entry tracks a representative value and its running count.
    private var groups: [(representative: T, count: Int)] = []

    public init(arrayLiteral elements: T...) {
        results = elements
        isMatch = nil
    }

    public init(elements: [T] = []) {
        results = elements
        isMatch = nil
    }

    public init(matchesRequired: Int? = nil) {
        self.matchesRequired = matchesRequired
        isMatch = nil
    }

    /// Initialize with a custom match predicate for approximate comparisons.
    /// - Parameters:
    ///   - matchesRequired: Number of matches required to suggest a value early.
    ///   - isMatch: A predicate that determines whether two values should be considered equal.
    public init(
        matchesRequired: Int? = nil,
        isMatch: @escaping @Sendable (T, T) -> Bool
    ) {
        self.matchesRequired = matchesRequired
        self.isMatch = isMatch
    }

    /// Append a value and check if it meets the required match threshold
    public mutating func append(_ value: T) -> Bool {
        results.append(value)

        let count: Int

        if let isMatch {
            // Update groups incrementally — O(groups) per append instead of O(results)
            if let index = groups.firstIndex(where: { isMatch($0.representative, value) }) {
                groups[index].count += 1
                count = groups[index].count
            } else {
                groups.append((representative: value, count: 1))
                count = 1
            }
        } else {
            count = results.count(where: { $0 == value })
        }

        if let matchesRequired, count >= matchesRequired {
            suggestedValue = value
            return true
        }

        return false
    }

    public func choose(tieBreakerWeight: TieBreakerWeight = .first) -> T? {
        if let suggestedValue { return suggestedValue }

        guard !results.isEmpty else { return nil }

        if isMatch != nil {
            return chooseFromGroups(tieBreakerWeight: tieBreakerWeight)
        }

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

    /// Choose the most frequent value from the incrementally maintained groups.
    private func chooseFromGroups(tieBreakerWeight: TieBreakerWeight) -> T? {
        guard let isMatch else { return nil }
        guard let maxCount = groups.map(\.count).max() else { return nil }

        let candidates = groups.filter { $0.count == maxCount }.map(\.representative)

        if candidates.count > 1 {
            // Break tie by order of first appearance in results
            return tieBreakerWeight == .first ?
                results.first { v in candidates.contains(where: { isMatch($0, v) }) } :
                results.last { v in candidates.contains(where: { isMatch($0, v) }) }
        }

        return candidates.first
    }
}
