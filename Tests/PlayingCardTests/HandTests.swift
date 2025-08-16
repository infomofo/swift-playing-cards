/*
 This source file is part of the Swift.org open source project
 
 Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception
 
 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

@testable import PlayingCard
import XCTest

class HandTests: XCTestCase {
    
    func testHandInitialization() {
        let hand = Hand()
        XCTAssertEqual(hand.numberOfCards, 0)
        XCTAssertEqual(hand.handCards.count, 0)
        
        let cards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts)
        ]
        let handWithCards = Hand(cards: cards)
        XCTAssertEqual(handWithCards.numberOfCards, 2)
        XCTAssertEqual(handWithCards.handCards, cards)
    }
    
    func testAddCard() {
        var hand = Hand()
        let card = PlayingCard(rank: .queen, suit: .diamonds)
        
        hand.addCard(card)
        
        XCTAssertEqual(hand.numberOfCards, 1)
        XCTAssertEqual(hand.handCards.first, card)
    }
    
    func testAddMultipleCards() {
        var hand = Hand()
        let cards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts),
            PlayingCard(rank: .queen, suit: .diamonds)
        ]
        
        hand.addCards(cards)
        
        XCTAssertEqual(hand.numberOfCards, 3)
        XCTAssertEqual(hand.handCards, cards)
    }
    
    func testRemoveCard() {
        let cards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts),
            PlayingCard(rank: .queen, suit: .diamonds)
        ]
        var hand = Hand(cards: cards)
        let cardToRemove = PlayingCard(rank: .king, suit: .hearts)
        
        hand.removeCard(cardToRemove)
        
        XCTAssertEqual(hand.numberOfCards, 2)
        XCTAssertFalse(hand.handCards.contains(cardToRemove))
    }
    
    func testClearHand() {
        let cards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts)
        ]
        var hand = Hand(cards: cards)
        
        hand.clear()
        
        XCTAssertEqual(hand.numberOfCards, 0)
        XCTAssertEqual(hand.handCards.count, 0)
    }
    
    // MARK: - Poker Hand Evaluation Tests
    
    func testHighCard() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .four, suit: .hearts),
            PlayingCard(rank: .six, suit: .diamonds),
            PlayingCard(rank: .eight, suit: .clubs),
            PlayingCard(rank: .jack, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .highCard)
    }
    
    func testPair() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .two, suit: .hearts),
            PlayingCard(rank: .six, suit: .diamonds),
            PlayingCard(rank: .eight, suit: .clubs),
            PlayingCard(rank: .jack, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .pair)
    }
    
    func testTwoPair() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .two, suit: .hearts),
            PlayingCard(rank: .six, suit: .diamonds),
            PlayingCard(rank: .six, suit: .clubs),
            PlayingCard(rank: .jack, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .twoPair)
    }
    
    func testThreeOfAKind() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .two, suit: .hearts),
            PlayingCard(rank: .two, suit: .diamonds),
            PlayingCard(rank: .eight, suit: .clubs),
            PlayingCard(rank: .jack, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .threeOfAKind)
    }
    
    func testStraight() {
        let hand = Hand(cards: [
            PlayingCard(rank: .five, suit: .spades),
            PlayingCard(rank: .six, suit: .hearts),
            PlayingCard(rank: .seven, suit: .diamonds),
            PlayingCard(rank: .eight, suit: .clubs),
            PlayingCard(rank: .nine, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .straight)
    }
    
    func testWheelStraight() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .two, suit: .hearts),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .four, suit: .clubs),
            PlayingCard(rank: .five, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .straight)
    }
    
    func testFlush() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .four, suit: .spades),
            PlayingCard(rank: .six, suit: .spades),
            PlayingCard(rank: .eight, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .flush)
    }
    
    func testFullHouse() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .two, suit: .hearts),
            PlayingCard(rank: .two, suit: .diamonds),
            PlayingCard(rank: .eight, suit: .clubs),
            PlayingCard(rank: .eight, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .fullHouse)
    }
    
    func testFourOfAKind() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .two, suit: .hearts),
            PlayingCard(rank: .two, suit: .diamonds),
            PlayingCard(rank: .two, suit: .clubs),
            PlayingCard(rank: .jack, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .fourOfAKind)
    }
    
    func testStraightFlush() {
        let hand = Hand(cards: [
            PlayingCard(rank: .five, suit: .spades),
            PlayingCard(rank: .six, suit: .spades),
            PlayingCard(rank: .seven, suit: .spades),
            PlayingCard(rank: .eight, suit: .spades),
            PlayingCard(rank: .nine, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .straightFlush)
    }
    
    func testRoyalFlush() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ten, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .ace, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .royalFlush)
    }
    
    func testHandComparison() {
        let pair = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .two, suit: .hearts),
            PlayingCard(rank: .six, suit: .diamonds),
            PlayingCard(rank: .eight, suit: .clubs),
            PlayingCard(rank: .jack, suit: .spades)
        ])
        
        let threeOfAKind = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .two, suit: .hearts),
            PlayingCard(rank: .two, suit: .diamonds),
            PlayingCard(rank: .eight, suit: .clubs),
            PlayingCard(rank: .jack, suit: .spades)
        ])
        
        XCTAssertLessThan(pair, threeOfAKind)
        XCTAssertGreaterThan(threeOfAKind, pair)
    }
    
    func testSevenCardHandEvaluation() {
        // Test with 7 cards (like Texas Hold'em)
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .two, suit: .hearts),
            PlayingCard(rank: .two, suit: .diamonds),
            PlayingCard(rank: .eight, suit: .clubs),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .queen, suit: .hearts),
            PlayingCard(rank: .king, suit: .diamonds)
        ])
        
        // Should find the three of a kind
        XCTAssertEqual(hand.evaluate(), .threeOfAKind)
    }
    
    func testHandTypeComparison() {
        XCTAssertLessThan(HandType.highCard, HandType.pair)
        XCTAssertLessThan(HandType.pair, HandType.twoPair)
        XCTAssertLessThan(HandType.twoPair, HandType.threeOfAKind)
        XCTAssertLessThan(HandType.threeOfAKind, HandType.straight)
        XCTAssertLessThan(HandType.straight, HandType.flush)
        XCTAssertLessThan(HandType.flush, HandType.fullHouse)
        XCTAssertLessThan(HandType.fullHouse, HandType.fourOfAKind)
        XCTAssertLessThan(HandType.fourOfAKind, HandType.straightFlush)
        XCTAssertLessThan(HandType.straightFlush, HandType.royalFlush)
    }
    
    func testHandTypeDescription() {
        XCTAssertEqual(HandType.highCard.description, "High Card")
        XCTAssertEqual(HandType.pair.description, "Pair")
        XCTAssertEqual(HandType.twoPair.description, "Two Pair")
        XCTAssertEqual(HandType.threeOfAKind.description, "Three of a Kind")
        XCTAssertEqual(HandType.straight.description, "Straight")
        XCTAssertEqual(HandType.flush.description, "Flush")
        XCTAssertEqual(HandType.fullHouse.description, "Full House")
        XCTAssertEqual(HandType.fourOfAKind.description, "Four of a Kind")
        XCTAssertEqual(HandType.straightFlush.description, "Straight Flush")
        XCTAssertEqual(HandType.royalFlush.description, "Royal Flush")
    }
    
    static var allTests = [
        ("testHandInitialization", testHandInitialization),
        ("testAddCard", testAddCard),
        ("testAddMultipleCards", testAddMultipleCards),
        ("testRemoveCard", testRemoveCard),
        ("testClearHand", testClearHand),
        ("testHighCard", testHighCard),
        ("testPair", testPair),
        ("testTwoPair", testTwoPair),
        ("testThreeOfAKind", testThreeOfAKind),
        ("testStraight", testStraight),
        ("testWheelStraight", testWheelStraight),
        ("testFlush", testFlush),
        ("testFullHouse", testFullHouse),
        ("testFourOfAKind", testFourOfAKind),
        ("testStraightFlush", testStraightFlush),
        ("testRoyalFlush", testRoyalFlush),
        ("testHandComparison", testHandComparison),
        ("testSevenCardHandEvaluation", testSevenCardHandEvaluation),
        ("testHandTypeComparison", testHandTypeComparison),
        ("testHandTypeDescription", testHandTypeDescription),
    ]
}