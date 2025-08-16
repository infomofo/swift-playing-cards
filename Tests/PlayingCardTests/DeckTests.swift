/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

@testable import PlayingCard
import XCTest

class DeckTests: XCTestCase {

    func testDeckInitialization() {
        let deck = Deck()

        XCTAssertEqual(deck.count, 52)
        XCTAssertFalse(deck.isEmpty)

        // Verify all cards are present
        let remainingCards = deck.remainingCards
        XCTAssertEqual(remainingCards.count, 52)

        // Check that we have 4 suits and 13 ranks
        let suits = Set(remainingCards.map { $0.suit })
        let ranks = Set(remainingCards.map { $0.rank })

        XCTAssertEqual(suits.count, 4)
        XCTAssertEqual(ranks.count, 13)
    }

    func testDeckInitializationWithCards() {
        let cards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts)
        ]
        let deck = Deck(cards: cards)

        XCTAssertEqual(deck.count, 2)
        XCTAssertFalse(deck.isEmpty)
    }

    func testDealSingleCard() {
        var deck = Deck()
        let originalCount = deck.count

        let dealtCard = deck.dealCard()

        XCTAssertNotNil(dealtCard)
        XCTAssertEqual(deck.count, originalCount - 1)
    }

    func testDealCardFromEmptyDeck() {
        var deck = Deck(cards: [])

        let dealtCard = deck.dealCard()

        XCTAssertNil(dealtCard)
        XCTAssertTrue(deck.isEmpty)
    }

    func testDealMultipleCards() {
        var deck = Deck()
        let originalCount = deck.count

        let dealtCards = deck.dealCards(5)

        XCTAssertEqual(dealtCards.count, 5)
        XCTAssertEqual(deck.count, originalCount - 5)

        // Verify all dealt cards are unique
        let uniqueCards = Set(dealtCards.map { "\($0.rank)\($0.suit)" })
        XCTAssertEqual(uniqueCards.count, 5)
    }

    func testDealMoreCardsThanAvailable() {
        var deck = Deck(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts)
        ])

        let dealtCards = deck.dealCards(5)

        XCTAssertEqual(dealtCards.count, 2)
        XCTAssertTrue(deck.isEmpty)
    }

    func testShuffle() {
        var deck1 = Deck()
        let deck2 = Deck()

        let originalOrder1 = deck1.remainingCards
        let originalOrder2 = deck2.remainingCards

        // Verify both decks start with the same order
        XCTAssertEqual(originalOrder1, originalOrder2)

        deck1.shuffle()
        let shuffledOrder1 = deck1.remainingCards

        // The shuffle should (almost certainly) change the order
        // Note: There's a tiny probability this could fail randomly
        XCTAssertNotEqual(shuffledOrder1, originalOrder1)
        XCTAssertEqual(shuffledOrder1.count, 52)

        // Verify all cards are still present after shuffle
        let shuffledSuits = Set(shuffledOrder1.map { $0.suit })
        let shuffledRanks = Set(shuffledOrder1.map { $0.rank })

        XCTAssertEqual(shuffledSuits.count, 4)
        XCTAssertEqual(shuffledRanks.count, 13)
    }

    func testReset() {
        var deck = Deck()

        // Deal some cards
        _ = deck.dealCards(10)
        XCTAssertEqual(deck.count, 42)

        // Reset the deck
        deck.reset()

        XCTAssertEqual(deck.count, 52)
        XCTAssertFalse(deck.isEmpty)
    }

    func testMultipleDealsUntilEmpty() {
        var deck = Deck()
        var totalDealtCards: [PlayingCard] = []

        // Deal cards until deck is empty
        while !deck.isEmpty {
            if let card = deck.dealCard() {
                totalDealtCards.append(card)
            }
        }

        XCTAssertEqual(totalDealtCards.count, 52)
        XCTAssertTrue(deck.isEmpty)

        // Verify we dealt all unique cards
        let uniqueCards = Set(totalDealtCards.map { "\($0.rank)\($0.suit)" })
        XCTAssertEqual(uniqueCards.count, 52)
    }

    static var allTests = [
        ("testDeckInitialization", testDeckInitialization),
        ("testDeckInitializationWithCards", testDeckInitializationWithCards),
        ("testDealSingleCard", testDealSingleCard),
        ("testDealCardFromEmptyDeck", testDealCardFromEmptyDeck),
        ("testDealMultipleCards", testDealMultipleCards),
        ("testDealMoreCardsThanAvailable", testDealMoreCardsThanAvailable),
        ("testShuffle", testShuffle),
        ("testReset", testReset),
        ("testMultipleDealsUntilEmpty", testMultipleDealsUntilEmpty),
    ]
}
