import Foundation

/// A standard 52-card deck of playing cards.
public struct Deck {
    private var cards: [PlayingCard]

    /// Creates a new standard 52-card deck.
    public init() {
        self.cards = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(PlayingCard(rank: rank, suit: suit))
            }
        }
    }

    /// Creates a deck with the specified cards.
    public init(cards: [PlayingCard]) {
        self.cards = cards
    }

    /// The number of cards remaining in the deck.
    public var count: Int {
        return cards.count
    }

    /// Returns true if the deck is empty.
    public var isEmpty: Bool {
        return cards.isEmpty
    }

    /// Shuffles the deck using Fisher-Yates algorithm with cryptographically secure randomization.
    public mutating func shuffle() {
        for i in (1..<cards.count).reversed() {
            let j = Int.random(in: 0...i)
            cards.swapAt(i, j)
        }
    }

    /// Deals a single card from the top of the deck.
    /// - Returns: The dealt card, or nil if the deck is empty.
    public mutating func dealCard() -> PlayingCard? {
        guard !cards.isEmpty else { return nil }
        return cards.removeFirst()
    }

    /// Deals the specified number of cards from the deck.
    /// - Parameter count: The number of cards to deal.
    /// - Returns: An array of dealt cards. May contain fewer than requested if deck runs out.
    public mutating func dealCards(_ count: Int) -> [PlayingCard] {
        var dealtCards: [PlayingCard] = []
        for _ in 0..<count {
            if let card = dealCard() {
                dealtCards.append(card)
            } else {
                break
            }
        }
        return dealtCards
    }

    /// Resets the deck to a full 52-card standard deck.
    public mutating func reset() {
        self = Deck()
    }

    /// Returns the remaining cards in the deck without removing them.
    public var remainingCards: [PlayingCard] {
        return cards
    }
}