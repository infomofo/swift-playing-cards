import Foundation

/// Represents the type of poker hand.
public enum HandType: Int, CaseIterable, Comparable {
    case highCard = 1
    case pair = 2
    case twoPair = 3
    case threeOfAKind = 4
    case straight = 5
    case flush = 6
    case fullHouse = 7
    case fourOfAKind = 8
    case straightFlush = 9
    case royalFlush = 10

    public static func < (lhs: HandType, rhs: HandType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - CustomStringConvertible

extension HandType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .highCard: return "High Card"
        case .pair: return "Pair"
        case .twoPair: return "Two Pair"
        case .threeOfAKind: return "Three of a Kind"
        case .straight: return "Straight"
        case .flush: return "Flush"
        case .fullHouse: return "Full House"
        case .fourOfAKind: return "Four of a Kind"
        case .straightFlush: return "Straight Flush"
        case .royalFlush: return "Royal Flush"
        }
    }
}

/// Represents a poker hand with evaluation capabilities.
public struct Hand {
    private var cards: [PlayingCard]

    /// The number of cards in the hand.
    public var numberOfCards: Int {
        return cards.count
    }

    /// The cards in the hand.
    public var handCards: [PlayingCard] {
        return cards
    }

    /// Creates a new empty hand.
    public init() {
        self.cards = []
    }

    /// Creates a hand with the specified cards.
    public init(cards: [PlayingCard]) {
        self.cards = cards
    }

    /// Adds a card to the hand.
    public mutating func addCard(_ card: PlayingCard) {
        cards.append(card)
    }

    /// Adds multiple cards to the hand.
    public mutating func addCards(_ newCards: [PlayingCard]) {
        cards.append(contentsOf: newCards)
    }

    /// Removes all cards from the hand.
    public mutating func clear() {
        cards.removeAll()
    }

    /// Removes a specific card from the hand.
    public mutating func removeCard(_ card: PlayingCard) {
        if let index = cards.firstIndex(of: card) {
            cards.remove(at: index)
        }
    }

    /// Replaces cards at specified indices with new cards.
    public mutating func replaceCards(at indices: [Int], with newCards: [PlayingCard]) {
        guard indices.count == newCards.count else { return }

        for (i, index) in indices.enumerated() {
            if index >= 0 && index < cards.count {
                cards[index] = newCards[i]
            }
        }
    }

    /// Evaluates the hand and returns the best 5-card poker hand type.
    /// Works with 5+ cards, finding the best possible hand.
    public func evaluate() -> HandType {
        guard cards.count >= 5 else { return .highCard }

        // For hands with more than 5 cards, we need to find the best 5-card combination
        if cards.count == 5 {
            return evaluateFiveCards(cards)
        } else {
            return findBestFiveCardHand()
        }
    }

    private func findBestFiveCardHand() -> HandType {
        let combinations = generateCombinations(from: cards, taking: 5)
        var bestHandType: HandType = .highCard

        for combination in combinations {
            let handType = evaluateFiveCards(combination)
            if handType > bestHandType {
                bestHandType = handType
            }
        }

        return bestHandType
    }

    private func evaluateFiveCards(_ fiveCards: [PlayingCard]) -> HandType {
        let sortedCards = fiveCards.sorted()
        let ranks = sortedCards.map { $0.rank }
        let suits = sortedCards.map { $0.suit }

        let isFlush = Set(suits).count == 1
        let isStraight = checkStraight(ranks)
        let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues { $0.count }
        let counts = Array(rankCounts.values).sorted(by: >)

        // Check for royal flush
        if isFlush && isStraight && ranks.contains(.ace) && ranks.contains(.king) {
            return .royalFlush
        }

        // Check for straight flush
        if isFlush && isStraight {
            return .straightFlush
        }

        // Check for four of a kind
        if counts == [4, 1] {
            return .fourOfAKind
        }

        // Check for full house
        if counts == [3, 2] {
            return .fullHouse
        }

        // Check for flush
        if isFlush {
            return .flush
        }

        // Check for straight
        if isStraight {
            return .straight
        }

        // Check for three of a kind
        if counts == [3, 1, 1] {
            return .threeOfAKind
        }

        // Check for two pair
        if counts == [2, 2, 1] {
            return .twoPair
        }

        // Check for pair
        if counts == [2, 1, 1, 1] {
            return .pair
        }

        return .highCard
    }

    private func checkStraight(_ ranks: [Rank]) -> Bool {
        let uniqueRanks = Array(Set(ranks)).sorted()
        guard uniqueRanks.count == 5 else { return false }

        // Check for wheel (A-2-3-4-5) special case first
        if uniqueRanks == [.two, .three, .four, .five, .ace] {
            return true
        }

        // Check for regular straight
        for i in 1..<uniqueRanks.count {
            if uniqueRanks[i].rawValue != uniqueRanks[i-1].rawValue + 1 {
                return false
            }
        }

        return true
    }

    private func generateCombinations<T>(from array: [T], taking k: Int) -> [[T]] {
        guard k <= array.count else { return [] }
        guard k > 0 else { return [[]] }

        if k == array.count {
            return [array]
        }

        let first = array[0]
        let rest = Array(array[1...])

        let withFirst = generateCombinations(from: rest, taking: k - 1).map { [first] + $0 }
        let withoutFirst = generateCombinations(from: rest, taking: k)

        return withFirst + withoutFirst
    }
}

// MARK: - Comparable

extension Hand: Comparable {
    public static func < (lhs: Hand, rhs: Hand) -> Bool {
        let lhsType = lhs.evaluate()
        let rhsType = rhs.evaluate()

        if lhsType != rhsType {
            return lhsType < rhsType
        }

        // If same hand type, compare by high cards
        // This is simplified - full poker comparison would be more complex
        let lhsSorted = lhs.cards.sorted(by: >)
        let rhsSorted = rhs.cards.sorted(by: >)

        for (lhsCard, rhsCard) in zip(lhsSorted, rhsSorted) {
            if lhsCard != rhsCard {
                return lhsCard < rhsCard
            }
        }

        return false
    }
}