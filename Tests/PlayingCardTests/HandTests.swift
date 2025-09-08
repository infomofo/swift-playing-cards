import XCTest
@testable import PlayingCard

final class HandTests: XCTestCase {
    
    func testHandCreation() {
        let hand = Hand()
        XCTAssertEqual(hand.numberOfCards, 0)
    }
    
    func testHandAddCard() {
        var hand = Hand()
        let card = PlayingCard(rank: .ace, suit: .spades)
        
        hand.addCard(card)
        XCTAssertEqual(hand.numberOfCards, 1)
        XCTAssertEqual(hand.handCards.first, card)
    }
    
    func testHandAddCards() {
        var hand = Hand()
        let cards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts)
        ]
        
        hand.addCards(cards)
        XCTAssertEqual(hand.numberOfCards, 2)
    }
    
    func testHandClear() {
        var hand = Hand()
        hand.addCard(PlayingCard(rank: .ace, suit: .spades))
        
        hand.clear()
        XCTAssertEqual(hand.numberOfCards, 0)
    }
    
    func testHandRemoveCard() {
        var hand = Hand()
        let card = PlayingCard(rank: .ace, suit: .spades)
        hand.addCard(card)
        
        hand.removeCard(card)
        XCTAssertEqual(hand.numberOfCards, 0)
    }
    
    // MARK: - Poker Hand Evaluation Tests
    
    func testHighCard() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .four, suit: .hearts),
            PlayingCard(rank: .six, suit: .diamonds),
            PlayingCard(rank: .eight, suit: .clubs),
            PlayingCard(rank: .ten, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .highCard)
    }
    
    func testPair() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .seven, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .pair)
    }
    
    func testTwoPair() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .three, suit: .clubs),
            PlayingCard(rank: .seven, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .twoPair)
    }
    
    func testThreeOfAKind() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .ace, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .seven, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .threeOfAKind)
    }
    
    func testStraight() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .three, suit: .hearts),
            PlayingCard(rank: .four, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .six, suit: .spades)
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
            PlayingCard(rank: .ten, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .flush)
    }
    
    func testFullHouse() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .ace, suit: .diamonds),
            PlayingCard(rank: .king, suit: .clubs),
            PlayingCard(rank: .king, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .fullHouse)
    }
    
    func testFourOfAKind() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .ace, suit: .diamonds),
            PlayingCard(rank: .ace, suit: .clubs),
            PlayingCard(rank: .king, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .fourOfAKind)
    }
    
    func testStraightFlush() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .three, suit: .spades),
            PlayingCard(rank: .four, suit: .spades),
            PlayingCard(rank: .five, suit: .spades),
            PlayingCard(rank: .six, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .straightFlush)
    }
    
    func testRoyalFlush() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .ten, suit: .spades)
        ])
        
        XCTAssertEqual(hand.evaluate(), .royalFlush)
    }
    
    func testSevenCardHand() {
        // Test with 7 cards (Texas Hold'em scenario)
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .seven, suit: .spades),
            PlayingCard(rank: .nine, suit: .hearts),
            PlayingCard(rank: .jack, suit: .diamonds)
        ])
        
        XCTAssertEqual(hand.evaluate(), .pair)
    }
}