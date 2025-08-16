//
//  PokerExample.swift
//
//  Example demonstrating video poker game functionality
//
//  Created by AI Assistant on 08/14/25.
//

import Foundation

/// Example demonstrating complete video poker game functionality
public struct VideoPokerExample {

    /// Simulates a complete video poker hand
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
        output.append("\nInitial hand evaluation: \(initialHandType.description)\n")

        // Simulate player deciding to hold some cards
        // For example, if we have a pair, hold the pair
        let cardsToReplace = simulatePlayerStrategy(hand: playerHand)
        output.append("Player strategy: Replace cards at positions \(cardsToReplace.map { $0 + 1 })")

        // Replace the unwanted cards
        let newCards = deck.dealCards(cardsToReplace.count)
        playerHand.replaceCards(at: cardsToReplace, with: newCards)

        output.append("\nAfter replacement:")
        for (index, card) in playerHand.handCards.enumerated() {
            let marker = cardsToReplace.contains(index) ? " (NEW)" : ""
            output.append("  \(index + 1): \(card.description)\(marker)")
        }

        // Evaluate final hand
        let finalHandType = playerHand.evaluate()
        output.append("\nFinal hand evaluation: \(finalHandType.description)")
        output.append("Cards remaining in deck: \(deck.count)")

        // Calculate payout (simplified)
        let payout = calculatePayout(handType: finalHandType)
        output.append("Payout: \(payout)x\n")

        return output.joined(separator: "\n")
    }

    /// Simulates a simple player strategy for card replacement
    private static func simulatePlayerStrategy(hand: Hand) -> [Int] {
        let cards = hand.handCards
        let handType = hand.evaluate()

        // Simple strategy: if we have a pair or better, keep it
        // Otherwise, keep any high cards (J, Q, K, A)
        switch handType {
        case .pair, .twoPair, .threeOfAKind, .straight, .flush, .fullHouse, .fourOfAKind, .straightFlush, .royalFlush:
            // For this example, if we have a made hand, keep all cards
            return []
        case .highCard:
            // Keep high cards (Jack or better), replace others
            var cardsToReplace: [Int] = []
            for (index, card) in cards.enumerated() {
                if card.rank.rawValue < Rank.jack.rawValue {
                    cardsToReplace.append(index)
                }
            }
            return cardsToReplace.isEmpty ? [0, 1, 2] : cardsToReplace // Replace at least some cards
        }
    }

    /// Simplified payout table for video poker
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
        case .pair: return 1
        case .highCard: return 0
        }
    }

    /// Demonstrates hand comparison functionality
    public static func demonstrateHandComparison() -> String {
        var output: [String] = []
        output.append("=== Hand Comparison Example ===\n")

        // Create two example hands
        let hand1 = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .king, suit: .diamonds),
            PlayingCard(rank: .queen, suit: .clubs),
            PlayingCard(rank: .jack, suit: .spades)
        ])

        let hand2 = Hand(cards: [
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts),
            PlayingCard(rank: .king, suit: .diamonds),
            PlayingCard(rank: .queen, suit: .clubs),
            PlayingCard(rank: .jack, suit: .spades)
        ])

        output.append("Hand 1: \(hand1.handCards.map { $0.description }.joined(separator: ", "))")
        output.append("Hand 1 evaluation: \(hand1.evaluate().description)")
        output.append("")
        output.append("Hand 2: \(hand2.handCards.map { $0.description }.joined(separator: ", "))")
        output.append("Hand 2 evaluation: \(hand2.evaluate().description)")
        output.append("")

        if hand1 > hand2 {
            output.append("Hand 1 wins!")
        } else if hand2 > hand1 {
            output.append("Hand 2 wins!")
        } else {
            output.append("It's a tie!")
        }

        return output.joined(separator: "\n")
    }
}