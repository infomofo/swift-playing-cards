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
            return false
        case (.ace, _):
            return false
        default:
            return lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - CustomStringConvertible

/// An extension that provides a human-readable description of a rank.
extension Rank: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default:
            return "\(rawValue)"
        }
    }
}

// MARK: - Display Extensions

/// Extensions for display purposes, especially for compact views
extension Rank {
    public var name: String {
        switch self {
        case .ace: return "Ace"
        case .jack: return "Jack"
        case .queen: return "Queen"
        case .king: return "King"
        default: return "\(rawValue)"
        }
    }

    /// Returns the first letter of the rank for compact display
    public var compactDescription: String {
        switch self {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default:
            return "\(rawValue)"
        }
    }
}