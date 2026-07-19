/// An enumeration that defines the rank of a playing card.
public enum Rank: Int, CaseIterable {
    case two = 2
    case three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace
}

// MARK: - Comparable

/// An extension that allows comparisons between ranks.
extension Rank: Comparable {
    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        switch (lhs, rhs) {
        case (_, _) where lhs == rhs:
            false
        case (.ace, _):
            false
        default:
            lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - CustomStringConvertible

/// An extension that provides a human-readable description of a rank.
extension Rank: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ace: "A"
        case .jack: "J"
        case .queen: "Q"
        case .king: "K"
        default:
            "\(rawValue)"
        }
    }
}

// MARK: - Display Extensions

/// Extensions for display purposes, especially for compact views
public extension Rank {
    var name: String {
        switch self {
        case .ace: "Ace"
        case .jack: "Jack"
        case .queen: "Queen"
        case .king: "King"
        default: "\(rawValue)"
        }
    }

    /// Returns the first letter of the rank for compact display
    var compactDescription: String {
        switch self {
        case .ace: "A"
        case .jack: "J"
        case .queen: "Q"
        case .king: "K"
        default:
            "\(rawValue)"
        }
    }
}
