/// An enumeration that defines the suit of a playing card.
public enum Suit: String, CaseIterable {
    case spades, hearts, diamonds, clubs
}

// MARK: - Comparable

/// An extension that allows comparisons between suits.
extension Suit: Comparable {
    public static func < (lhs: Suit, rhs: Suit) -> Bool {
        switch (lhs, rhs) {
        case (_, _) where lhs == rhs:
            false
        case (.spades, _),
             (.hearts, .diamonds), (.hearts, .clubs),
             (.diamonds, .clubs):
            false
        default:
            true
        }
    }
}

// MARK: - CustomStringConvertible

/// An extension that provides a human-readable description of a suit.
extension Suit: CustomStringConvertible {
    public var description: String {
        switch self {
        case .spades: "♠️"
        case .hearts: "♥️"
        case .diamonds: "♦️"
        case .clubs: "♣️"
        }
    }
}
