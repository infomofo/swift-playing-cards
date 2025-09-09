import XCTest
@testable import PlayingCard

final class DeckTests: XCTestCase {
    
    func testDeckCreation() {
        let deck = Deck()
        XCTAssertEqual(deck.count, 52)
        XCTAssertFalse(deck.isEmpty)
    }
    
    func testDeckDealing() {
        var deck = Deck()
        let card = deck.dealCard()
        
        XCTAssertNotNil(card)
        XCTAssertEqual(deck.count, 51)
    }
    
    func testDeckDealingMultiple() {
        var deck = Deck()
        let cards = deck.dealCards(5)
        
        XCTAssertEqual(cards.count, 5)
        XCTAssertEqual(deck.count, 47)
    }
    
    func testDeckDealingAll() {
        var deck = Deck()
        let cards = deck.dealCards(52)
        
        XCTAssertEqual(cards.count, 52)
        XCTAssertEqual(deck.count, 0)
        XCTAssertTrue(deck.isEmpty)
    }
    
    func testDeckDealingEmpty() {
        var deck = Deck()
        _ = deck.dealCards(52) // Deal all cards
        
        let card = deck.dealCard()
        XCTAssertNil(card)
    }
    
    func testDeckReset() {
        var deck = Deck()
        _ = deck.dealCards(10)
        
        deck.reset()
        XCTAssertEqual(deck.count, 52)
    }
    
    func testDeckShuffle() {
        var deck1 = Deck()
        var deck2 = Deck()
        
        deck1.shuffle()
        
        // Very unlikely that shuffled deck matches original order
        let originalCards = deck2.remainingCards
        let shuffledCards = deck1.remainingCards
        
        XCTAssertNotEqual(originalCards, shuffledCards)
    }
}