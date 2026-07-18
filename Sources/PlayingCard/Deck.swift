import Foundation

/// A standard 52-card deck of playing cards.
public struct Deck {
    private var cards: [PlayingCard]
    private var nextCardIndex = 0

    /// Creates a new standard 52-card deck.
    public init() {
        cards = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(PlayingCard(rank: rank, suit: suit))
            }
        }
        nextCardIndex = 0
    }

    /// Creates a deck with the specified cards.
    public init(cards: [PlayingCard]) {
        self.cards = cards
        nextCardIndex = 0
    }

    /// The number of cards remaining in the deck.
    public var count: Int {
        cards.count - nextCardIndex
    }

    /// Returns true if the deck is empty.
    public var isEmpty: Bool {
        nextCardIndex >= cards.count
    }

    /// Shuffles the deck using Fisher-Yates algorithm with cryptographically secure randomization.
    public mutating func shuffle() {
        for index in (1 ..< cards.count).reversed() {
            let randomIndex = Int.random(in: 0 ... index)
            cards.swapAt(index, randomIndex)
        }
        nextCardIndex = 0
    }

    /// Deals a single card from the top of the deck.
    /// - Returns: The dealt card, or nil if the deck is empty.
    public mutating func dealCard() -> PlayingCard? {
        guard nextCardIndex < cards.count else { return nil }
        let card = cards[nextCardIndex]
        nextCardIndex += 1
        return card
    }

    /// Deals the specified number of cards from the deck.
    /// - Parameter count: The number of cards to deal.
    /// - Returns: An array of dealt cards. May contain fewer than requested if deck runs out.
    public mutating func dealCards(_ count: Int) -> [PlayingCard] {
        guard count > 0 else { return [] }
        let dealCount = min(count, cards.count - nextCardIndex)
        guard dealCount > 0 else { return [] }
        let dealtSlice = cards[nextCardIndex ..< nextCardIndex + dealCount]
        nextCardIndex += dealCount
        return Array(dealtSlice)
    }

    /// Resets the deck to a full 52-card standard deck.
    public mutating func reset() {
        self = Deck()
    }

    /// Returns the remaining cards in the deck without removing them.
    public var remainingCards: [PlayingCard] {
        nextCardIndex == 0 ? cards : Array(cards[nextCardIndex...])
    }
}
