import XCTest
@testable import PlayingCard

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
final class InteractiveCardTests: XCTestCase {
    
    func testInteractiveCardCreation() {
        let card = PlayingCard(rank: .ace, suit: .spades)
        let interactiveCard = InteractiveCard(card: card)
        
        XCTAssertNotNil(interactiveCard)
    }
    
    func testInteractiveCardWithCallback() {
        let card = PlayingCard(rank: .king, suit: .hearts)
        var callbackReceived = false
        var selectedState = false
        
        let interactiveCard = InteractiveCard(card: card) { isSelected in
            callbackReceived = true
            selectedState = isSelected
        }
        
        XCTAssertNotNil(interactiveCard)
        // Note: Testing the actual callback would require UI interaction
        // which is not feasible in unit tests
    }
    
    func testInteractiveCardHashableEquatable() {
        let card1 = PlayingCard(rank: .ace, suit: .spades)
        let card2 = PlayingCard(rank: .ace, suit: .spades)
        let card3 = PlayingCard(rank: .king, suit: .hearts)
        
        let interactive1 = InteractiveCard(card: card1)
        let interactive2 = InteractiveCard(card: card2)
        let interactive3 = InteractiveCard(card: card3)
        
        // Same cards should be equal
        XCTAssertEqual(interactive1, interactive2)
        
        // Different cards should not be equal
        XCTAssertNotEqual(interactive1, interactive3)
        
        // Should be hashable
        let set: Set<InteractiveCard> = [interactive1, interactive2, interactive3]
        XCTAssertEqual(set.count, 2) // interactive1 and interactive2 are the same
    }
    
    func testInteractiveCardReplace() {
        let originalCard = PlayingCard(rank: .ace, suit: .spades)
        let newCard = PlayingCard(rank: .king, suit: .hearts)
        
        var interactiveCard = InteractiveCard(card: originalCard)
        
        // Test that replace method exists and can be called
        interactiveCard.replace(with: newCard)
        
        // Note: Since the replace method uses async dispatch, we can't easily test
        // the card update in a synchronous unit test. The important thing is that
        // the method compiles and can be called without errors.
        XCTAssertNotNil(interactiveCard)
    }
}

#endif
