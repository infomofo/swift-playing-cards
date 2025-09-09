import XCTest
@testable import PlayingCard

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
final class DisplayCardTests: XCTestCase {
    
    func testDisplayCardCreation() {
        let card = PlayingCard(rank: .ace, suit: .spades)
        let displayCard = DisplayCard(card: card)
        
        // Test that we can create the view without issues
        XCTAssertNotNil(displayCard)
    }
    
    func testDisplayCardCompactMode() {
        let card = PlayingCard(rank: .king, suit: .hearts)
        let displayCard = DisplayCard(card: card, displayMode: .compact)
        
        XCTAssertNotNil(displayCard)
    }
    
    func testDisplayCardLargeMode() {
        let card = PlayingCard(rank: .nine, suit: .diamonds)
        let displayCard = DisplayCard(card: card, displayMode: .large)
        
        XCTAssertNotNil(displayCard)
    }
    
    func testAllRanksAndSuits() {
        // Test that all combinations of ranks and suits can be displayed
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                let card = PlayingCard(rank: rank, suit: suit)
                let compactView = DisplayCard(card: card, displayMode: .compact)
                let largeView = DisplayCard(card: card, displayMode: .large)
                
                XCTAssertNotNil(compactView)
                XCTAssertNotNil(largeView)
            }
        }
    }
}

#endif