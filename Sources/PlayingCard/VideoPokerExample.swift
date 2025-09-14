import Foundation

/// Example demonstrating complete video poker game functionality
public struct VideoPokerExample {

    /// Simulates a complete video poker hand with detailed output
    public static func playExampleHand() -> String {
        var output: [String] = []
        output.append("=== Video Poker Game Example ===\n")

        // Create and shuffle deck
        var deck = Deck()
        deck.shuffle()
        output.append("Created and shuffled a standard 52-card deck")
        output.append("Cards remaining in deck: \(deck.count)\n")

        // Deal initial 5 cards
        let initialCards = deck.dealCards(5)
        var playerHand = Hand(cards: initialCards)

        output.append("Initial 5-card hand dealt:")
        for (index, card) in initialCards.enumerated() {
            output.append("  \(index + 1): \(card.description)")
        }

        let initialHandType = playerHand.evaluate()
        output.append("\nInitial hand evaluation: \(initialHandType.description)")
        output.append("Initial payout: \(calculatePayout(handType: initialHandType))x\n")

        // Simulate player deciding to hold some cards
        let cardsToReplace = simulatePlayerStrategy(hand: playerHand)
        if cardsToReplace.isEmpty {
            output.append("Player strategy: Hold all cards (standing pat)")
        } else {
            output.append("Player strategy: Replace cards at positions \(cardsToReplace.map { $0 + 1 })")
        }

        // Replace the unwanted cards
        if !cardsToReplace.isEmpty {
            let newCards = deck.dealCards(cardsToReplace.count)
            playerHand.replaceCards(at: cardsToReplace, with: newCards)

            output.append("\nAfter replacement:")
            for (index, card) in playerHand.handCards.enumerated() {
                let marker = cardsToReplace.contains(index) ? " (NEW)" : " (HELD)"
                output.append("  \(index + 1): \(card.description)\(marker)")
            }
        }

        // Evaluate final hand
        let finalHandType = playerHand.evaluate()
        output.append("\nFinal hand evaluation: \(finalHandType.description)")
        output.append("Cards remaining in deck: \(deck.count)")

        // Calculate payout
        let payout = calculatePayout(handType: finalHandType)
        output.append("Final payout: \(payout)x")
        
        if payout > 0 {
            output.append("🎉 WINNER! 🎉")
        } else {
            output.append("Better luck next time!")
        }
        
        output.append("")
        return output.joined(separator: "\n")
    }

    /// Simulates an intelligent player strategy for card replacement
    private static func simulatePlayerStrategy(hand: Hand) -> [Int] {
        let cards = hand.handCards
        let handType = hand.evaluate()

        switch handType {
        case .royalFlush, .straightFlush, .fourOfAKind, .fullHouse, .flush, .straight:
            // Always hold made hands
            return []
            
        case .threeOfAKind:
            // Hold the three of a kind, replace the other two
            let rankCounts = Dictionary(grouping: cards, by: { $0.rank }).mapValues { $0.count }
            let threeOfAKindRank = rankCounts.first { $0.value == 3 }?.key
            
            var cardsToReplace: [Int] = []
            for (index, card) in cards.enumerated() {
                if card.rank != threeOfAKindRank {
                    cardsToReplace.append(index)
                }
            }
            return cardsToReplace
            
        case .twoPair:
            // Hold both pairs, replace the kicker
            let rankCounts = Dictionary(grouping: cards, by: { $0.rank }).mapValues { $0.count }
            let pairRanks = Set(rankCounts.filter { $0.value == 2 }.keys)
            
            var cardsToReplace: [Int] = []
            for (index, card) in cards.enumerated() {
                if !pairRanks.contains(card.rank) {
                    cardsToReplace.append(index)
                }
            }
            return cardsToReplace
            
        case .pair:
            // Hold the pair, replace the other three
            let rankCounts = Dictionary(grouping: cards, by: { $0.rank }).mapValues { $0.count }
            let pairRank = rankCounts.first { $0.value == 2 }?.key
            
            var cardsToReplace: [Int] = []
            for (index, card) in cards.enumerated() {
                if card.rank != pairRank {
                    cardsToReplace.append(index)
                }
            }
            return cardsToReplace
            
        case .highCard:
            // Hold high cards (J, Q, K, A) and suited connectors
            return simulateHighCardStrategy(cards: cards)
        }
    }
    
    private static func simulateHighCardStrategy(cards: [PlayingCard]) -> [Int] {
        var cardsToReplace: [Int] = []
        var highCards: [Int] = []
        
        // Identify high cards (Jack or better)
        for (index, card) in cards.enumerated() {
            if card.rank.rawValue >= Rank.jack.rawValue {
                highCards.append(index)
            }
        }
        
        // Check for flush draw (4 cards of same suit)
        let suitCounts = Dictionary(grouping: cards, by: { $0.suit }).mapValues { $0.count }
        let flushSuit = suitCounts.first { $0.value == 4 }?.key
        
        if let flushSuit = flushSuit {
            // Hold the 4 cards of the flush suit
            for (index, card) in cards.enumerated() {
                if card.suit != flushSuit {
                    cardsToReplace.append(index)
                }
            }
            return cardsToReplace
        }
        
        // Check for straight draw
        let sortedRanks = cards.map { $0.rank }.sorted()
        if isOpenEndedStraightDraw(ranks: sortedRanks) {
            // Hold all cards for straight draw
            return []
        }
        
        // If we have high cards, hold them
        if !highCards.isEmpty {
            for index in cards.indices {
                if !highCards.contains(index) {
                    cardsToReplace.append(index)
                }
            }
        } else {
            // No high cards, replace lowest 3 cards
            let sortedWithIndices = cards.enumerated().sorted { $0.element < $1.element }
            for i in 0..<3 {
                cardsToReplace.append(sortedWithIndices[i].offset)
            }
        }
        
        return cardsToReplace
    }
    
    private static func isOpenEndedStraightDraw(ranks: [Rank]) -> Bool {
        let uniqueRanks = Array(Set(ranks)).sorted()
        guard uniqueRanks.count >= 4 else { return false }
        
        // Check for consecutive sequences of 4 cards
        for i in 0...(uniqueRanks.count - 4) {
            var isConsecutive = true
            for j in 1..<4 {
                if uniqueRanks[i + j].rawValue != uniqueRanks[i + j - 1].rawValue + 1 {
                    isConsecutive = false
                    break
                }
            }
            if isConsecutive {
                return true
            }
        }
        
        // Check for wheel draw (A, 2, 3, 4)
        if uniqueRanks.contains(.ace) && uniqueRanks.contains(.two) && 
           uniqueRanks.contains(.three) && uniqueRanks.contains(.four) {
            return true
        }
        
        return false
    }

    /// Standard video poker payout table (Jacks or Better)
    private static func calculatePayout(handType: HandType) -> Int {
        switch handType {
        case .royalFlush: return 250
        case .straightFlush: return 50
        case .fourOfAKind: return 25
        case .fullHouse: return 9
        case .flush: return 6
        case .straight: return 4
        case .threeOfAKind: return 3
        case .twoPair: return 2
        case .pair: return 1  // Only Jacks or better
        case .highCard: return 0
        }
    }

    /// Demonstrates hand comparison functionality
    public static func demonstrateHandComparison() -> String {
        var output: [String] = []
        output.append("=== Hand Comparison Example ===\n")

        // Create example hands of different strengths
        let hands = [
            ("Royal Flush", Hand(cards: [
                PlayingCard(rank: .ace, suit: .spades),
                PlayingCard(rank: .king, suit: .spades),
                PlayingCard(rank: .queen, suit: .spades),
                PlayingCard(rank: .jack, suit: .spades),
                PlayingCard(rank: .ten, suit: .spades)
            ])),
            ("Pair of Aces", Hand(cards: [
                PlayingCard(rank: .ace, suit: .spades),
                PlayingCard(rank: .ace, suit: .hearts),
                PlayingCard(rank: .king, suit: .diamonds),
                PlayingCard(rank: .queen, suit: .clubs),
                PlayingCard(rank: .jack, suit: .spades)
            ])),
            ("Three Kings", Hand(cards: [
                PlayingCard(rank: .king, suit: .spades),
                PlayingCard(rank: .king, suit: .hearts),
                PlayingCard(rank: .king, suit: .diamonds),
                PlayingCard(rank: .queen, suit: .clubs),
                PlayingCard(rank: .jack, suit: .spades)
            ])),
            ("High Card", Hand(cards: [
                PlayingCard(rank: .king, suit: .spades),
                PlayingCard(rank: .queen, suit: .hearts),
                PlayingCard(rank: .jack, suit: .diamonds),
                PlayingCard(rank: .nine, suit: .clubs),
                PlayingCard(rank: .seven, suit: .spades)
            ]))
        ]

        for (name, hand) in hands {
            output.append("\(name): \(hand.handCards.map { $0.description }.joined(separator: " "))")
            output.append("  Evaluation: \(hand.evaluate().description)")
            output.append("  Payout: \(calculatePayout(handType: hand.evaluate()))x")
            output.append("")
        }

        // Compare hands
        let sortedHands = hands.sorted { $0.1 > $1.1 }
        output.append("Ranking from best to worst:")
        for (index, (name, _)) in sortedHands.enumerated() {
            output.append("  \(index + 1). \(name)")
        }

        return output.joined(separator: "\n")
    }
    
    /// Demonstrates probability analysis for different starting hands
    public static func demonstrateProbabilities() -> String {
        var output: [String] = []
        output.append("=== Probability Analysis Example ===\n")
        
        // Example probabilities for common video poker scenarios
        let scenarios = [
            ("Royal Flush (dealt)", "1 in 649,740"),
            ("Straight Flush (dealt)", "1 in 72,193"),
            ("Four of a Kind (dealt)", "1 in 4,165"),
            ("Full House (dealt)", "1 in 694"),
            ("Flush (dealt)", "1 in 509"),
            ("Straight (dealt)", "1 in 255"),
            ("Three of a Kind (dealt)", "1 in 47"),
            ("Two Pair (dealt)", "1 in 21"),
            ("Jacks or Better (dealt)", "1 in 6")
        ]
        
        output.append("Probability of being dealt various hands:")
        for (hand, probability) in scenarios {
            output.append("  \(hand): \(probability)")
        }
        
        output.append("\nNote: These are theoretical probabilities.")
        output.append("Actual gameplay involves drawing decisions that affect final outcomes.")
        
        return output.joined(separator: "\n")
    }
    
    /// Runs multiple example hands to show variety
    public static func runMultipleHands(count: Int = 3) -> String {
        var output: [String] = []
        
        for i in 1...count {
            output.append("HAND #\(i)")
            output.append(String(repeating: "=", count: 50))
            output.append(playExampleHand())
        }
        
        return output.joined(separator: "\n")
    }
}