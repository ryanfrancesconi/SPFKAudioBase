// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

import Foundation

/// Tracks appended values and determines the most frequent entry via consensus voting.
///
/// Used for iterative analysis where results arrive over time and a "best guess"
/// can be requested at any point. Supports both exact `Hashable` matching and
/// custom approximate matching via a predicate.
///
/// When `matchesRequired` is set, ``append(_:)`` returns `true` as soon as any
/// value reaches that count, enabling early exit from streaming analysis.
public struct CountableResult<T: Hashable & Sendable>: ExpressibleByArrayLiteral {
    /// Controls which candidate wins when multiple values are tied for most frequent.
    public enum TieBreakerWeight {
        /// The value that appeared first in the results wins.
        case first
        /// The value that appeared last in the results wins.
        case last
    }

    /// All values appended so far, in insertion order.
    public private(set) var results: [T] = []

    /// The value that first reached `matchesRequired`, if any.
    public private(set) var suggestedValue: T?

    /// The number of matching entries needed for ``append(_:)`` to return `true`.
    public var matchesRequired: Int?

    /// Optional custom match predicate. When provided, this is used instead of `==`
    /// for counting matches in `append` and grouping in `choose`.
    private let isMatch: (@Sendable (T, T) -> Bool)?

    /// Maintained incrementally when `isMatch` is set.
    /// Each entry tracks a representative value and its running count.
    private var groups: [(representative: T, count: Int)] = []

    /// Maintained incrementally when `isMatch` is nil for O(1) counting.
    private var frequencyMap: [T: Int] = [:]

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

    /// Appends a value and checks whether the match threshold has been reached.
    ///
    /// - Returns: `true` if this value caused a group to reach `matchesRequired`,
    ///   at which point ``suggestedValue`` is set. Returns `false` otherwise
    ///   or if `matchesRequired` is `nil`.
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
            frequencyMap[value, default: 0] += 1
            count = frequencyMap[value]!
        }

        if let matchesRequired, count >= matchesRequired {
            suggestedValue = value
            return true
        }

        return false
    }

    /// Returns the most frequent value, or ``suggestedValue`` if one was set early.
    ///
    /// When multiple values are tied for the highest count, `tieBreakerWeight`
    /// determines whether the earliest or latest occurrence wins.
    ///
    /// - Parameter tieBreakerWeight: How to break ties. Defaults to `.first`.
    /// - Returns: The winning value, or `nil` if no results have been appended.
    public func choose(tieBreakerWeight: TieBreakerWeight = .first) -> T? {
        if let suggestedValue { return suggestedValue }

        guard !results.isEmpty else { return nil }

        if isMatch != nil {
            return chooseFromGroups(tieBreakerWeight: tieBreakerWeight)
        }

        // Use incrementally maintained frequencyMap if available, otherwise build one
        let map: [T: Int] = frequencyMap.isEmpty
            ? results.reduce(into: [:]) { counts, value in counts[value, default: 0] += 1 }
            : frequencyMap

        // Find the highest frequency count
        guard let maxCount = map.values.max() else { return nil }

        // Filter for all keys that share that maxCount
        let candidates = map.filter { $0.value == maxCount }.map(\.key)

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
