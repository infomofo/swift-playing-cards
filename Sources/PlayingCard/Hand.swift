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
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - CustomStringConvertible

extension HandType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .highCard: "High Card"
        case .pair: "Pair"
        case .twoPair: "Two Pair"
        case .threeOfAKind: "Three of a Kind"
        case .straight: "Straight"
        case .flush: "Flush"
        case .fullHouse: "Full House"
        case .fourOfAKind: "Four of a Kind"
        case .straightFlush: "Straight Flush"
        case .royalFlush: "Royal Flush"
        }
    }
}

/// Represents a poker hand with evaluation capabilities.
public struct Hand {
    private var cards: [PlayingCard]

    /// The number of cards in the hand.
    public var numberOfCards: Int {
        cards.count
    }

    /// The cards in the hand.
    public var handCards: [PlayingCard] {
        cards
    }

    /// Creates a new empty hand.
    public init() {
        cards = []
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

        for (cardIndex, index) in indices.enumerated() {
            if index >= 0, index < cards.count {
                cards[index] = newCards[cardIndex]
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

    // swiftlint:disable identifier_name cyclomatic_complexity function_body_length
    private func evaluateFiveCards(_ fiveCards: [PlayingCard]) -> HandType {
        // Direct, allocation-free flush check
        let isFlush = fiveCards[0].suit == fiveCards[1].suit &&
            fiveCards[1].suit == fiveCards[2].suit &&
            fiveCards[2].suit == fiveCards[3].suit &&
            fiveCards[3].suit == fiveCards[4].suit

        // Inline insertion sort of the 5 ranks using stack-allocated registers
        var s0 = fiveCards[0].rank.rawValue
        var s1 = fiveCards[1].rank.rawValue
        var s2 = fiveCards[2].rank.rawValue
        var s3 = fiveCards[3].rank.rawValue
        var s4 = fiveCards[4].rank.rawValue
        var t = 0

        if s0 > s1 {
            t = s0; s0 = s1; s1 = t
        }
        if s1 > s2 {
            t = s1; s1 = s2; s2 = t
            if s0 > s1 {
                t = s0; s0 = s1; s1 = t
            }
        }
        if s2 > s3 {
            t = s2; s2 = s3; s3 = t
            if s1 > s2 {
                t = s1; s1 = s2; s2 = t
                if s0 > s1 {
                    t = s0; s0 = s1; s1 = t
                }
            }
        }
        if s3 > s4 {
            t = s3; s3 = s4; s4 = t
            if s2 > s3 {
                t = s2; s2 = s3; s3 = t
                if s1 > s2 {
                    t = s1; s1 = s2; s2 = t
                    if s0 > s1 {
                        t = s0; s0 = s1; s1 = t
                    }
                }
            }
        }

        // Inline straight check (including ace-low wheel straight: 2, 3, 4, 5, 14)
        let isStraight = (s1 == s0 + 1 && s2 == s1 + 1 && s3 == s2 + 1 && s4 == s3 + 1) ||
            (s0 == 2 && s1 == 3 && s2 == 4 && s3 == 5 && s4 == 14)

        // Evaluate Hand Result in precedence order
        if isFlush && isStraight {
            if s4 == 14, s3 == 13 {
                return .royalFlush
            }
            return .straightFlush
        }

        // Four of a kind
        if s0 == s3 || s1 == s4 {
            return .fourOfAKind
        }

        // Full house
        if (s0 == s2 && s3 == s4) || (s0 == s1 && s2 == s4) {
            return .fullHouse
        }

        // Flush
        if isFlush {
            return .flush
        }

        // Straight
        if isStraight {
            return .straight
        }

        // Three of a kind
        if s0 == s2 || s1 == s3 || s2 == s4 {
            return .threeOfAKind
        }

        // Two pair
        if (s0 == s1 && s2 == s3) || (s0 == s1 && s3 == s4) || (s1 == s2 && s3 == s4) {
            return .twoPair
        }

        // Pair
        if s0 == s1 || s1 == s2 || s2 == s3 || s3 == s4 {
            return .pair
        }

        return .highCard
    }

    // swiftlint:enable identifier_name cyclomatic_complexity function_body_length

    private func generateCombinations<T>(from array: [T], taking count: Int) -> [[T]] {
        guard count <= array.count else { return [] }
        guard count > 0 else { return [[]] }

        if count == array.count {
            return [array]
        }

        let first = array[0]
        let rest = Array(array[1...])

        let withFirst = generateCombinations(from: rest, taking: count - 1).map { [first] + $0 }
        let withoutFirst = generateCombinations(from: rest, taking: count)

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

        for (lhsCard, rhsCard) in zip(lhsSorted, rhsSorted) where lhsCard != rhsCard {
            return lhsCard < rhsCard
        }

        return false
    }
}
