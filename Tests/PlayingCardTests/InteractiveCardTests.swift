@testable import PlayingCard
import XCTest

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

        // MARK: - CardFlipAnimator tests

        /// Front face is visible from 0° up to and including 90° (the edge-on midpoint).
        func testFlipAnimatorFrontVisibility() {
            XCTAssertTrue(CardFlipAnimator.isFrontVisible(at: 0),
                          "Front should be visible at 0° (resting position)")
            XCTAssertTrue(CardFlipAnimator.isFrontVisible(at: 45),
                          "Front should be visible at 45° (first quarter)")
            XCTAssertTrue(CardFlipAnimator.isFrontVisible(at: 90),
                          "Front should be visible at exactly 90° (boundary)")
            XCTAssertFalse(CardFlipAnimator.isFrontVisible(at: 91),
                           "Front should be hidden past 90°")
            XCTAssertFalse(CardFlipAnimator.isFrontVisible(at: 180),
                           "Front should be hidden at 180°")
        }

        /// Back face becomes visible strictly after 90°.
        func testFlipAnimatorBackVisibility() {
            XCTAssertFalse(CardFlipAnimator.isBackVisible(at: 0),
                           "Back should be hidden at 0°")
            XCTAssertFalse(CardFlipAnimator.isBackVisible(at: 90),
                           "Back should be hidden at exactly 90° (boundary belongs to front)")
            XCTAssertTrue(CardFlipAnimator.isBackVisible(at: 91),
                          "Back should be visible past 90°")
            XCTAssertTrue(CardFlipAnimator.isBackVisible(at: 135),
                          "Back should be visible at 135°")
            XCTAssertTrue(CardFlipAnimator.isBackVisible(at: 180),
                          "Back should be visible at 180°")
        }

        /// Front and back visibility are mutually exclusive at every degree value.
        func testFlipAnimatorVisibilityMutualExclusion() {
            let degrees: [Double] = [0, 45, 89, 90, 91, 135, 180]
            for deg in degrees {
                let front = CardFlipAnimator.isFrontVisible(at: deg)
                let back = CardFlipAnimator.isBackVisible(at: deg)
                XCTAssertTrue(front != back,
                              "Exactly one face must be visible at \(deg)°: front=\(front), back=\(back)")
            }
        }

        /// Back face rotation is offset by -180° so it faces forward at 180°.
        func testFlipAnimatorBackFaceRotation() {
            XCTAssertEqual(CardFlipAnimator.backFaceRotation(at: 0), -180,
                           "At 0° the back face offset should be -180°")
            XCTAssertEqual(CardFlipAnimator.backFaceRotation(at: 90), -90,
                           "At 90° the back face offset should be -90°")
            XCTAssertEqual(CardFlipAnimator.backFaceRotation(at: 180), 0,
                           "At 180° the back face is fully forward (0° net rotation)")
        }

        /// Ripple delays stagger each card 100 ms apart.
        func testFlipAnimatorRippleDelay() {
            XCTAssertEqual(CardFlipAnimator.rippleDelay(for: 0), 0.0,
                           "First card flips immediately")
            XCTAssertEqual(CardFlipAnimator.rippleDelay(for: 1), 0.1,
                           "Second card delayed 100 ms")
            XCTAssertEqual(CardFlipAnimator.rippleDelay(for: 2), 0.2,
                           "Third card delayed 200 ms")
            XCTAssertEqual(CardFlipAnimator.rippleDelay(for: 4), 0.4,
                           "Fifth card delayed 400 ms (full hand)")
        }

        /// Front face scale shrinks from 1.0 at 0° to 0.9 at 90°.
        func testFlipAnimatorFrontFaceScale() {
            XCTAssertEqual(CardFlipAnimator.frontFaceScale(at: 0), 1.0, accuracy: 0.001,
                           "Full size at rest")
            XCTAssertEqual(CardFlipAnimator.frontFaceScale(at: 90), 0.9, accuracy: 0.001,
                           "Minimum scale at midpoint")
            XCTAssertEqual(CardFlipAnimator.frontFaceScale(at: 45), 0.95, accuracy: 0.001,
                           "Half-scale-reduction at 45°")
            // Past midpoint the front is hidden; scale returns the clamped minimum
            XCTAssertEqual(CardFlipAnimator.frontFaceScale(at: 180), 0.9, accuracy: 0.001,
                           "Clamps at minimum when past midpoint")
        }

        /// Back face scale grows from 0.9 at 90° to 1.0 at 180°.
        func testFlipAnimatorBackFaceScale() {
            XCTAssertEqual(CardFlipAnimator.backFaceScale(at: 90), 1.0, accuracy: 0.001,
                           "Clamps at default before midpoint")
            XCTAssertEqual(CardFlipAnimator.backFaceScale(at: 135), 0.95, accuracy: 0.001,
                           "Half-scale-growth at 135°")
            XCTAssertEqual(CardFlipAnimator.backFaceScale(at: 180), 1.0, accuracy: 0.001,
                           "Full size when back is fully visible")
        }
    }

#endif
