import Foundation

/// Track results and determine the most frequent entry.
public struct CountableResult<T: Hashable & Sendable>: ExpressibleByArrayLiteral {
    private var results: [T] = []
    private var suggestedValue: T?
    private var matchesRequired: Int?

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

    public func mostLikely() -> T? {
        if let suggestedValue { return suggestedValue }
        guard !results.isEmpty else { return nil }

        return Self.mostLikely(from: results)
    }

    static func mostLikely(from results: [T]) -> T? {
        let frequencyMap = results.reduce(into: [:]) { counts, value in
            counts[value, default: 0] += 1
        }

        return frequencyMap.max { $0.value < $1.value }?.key
    }
}
