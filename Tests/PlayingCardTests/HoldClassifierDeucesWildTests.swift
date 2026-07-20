@testable import PlayingCard
import XCTest

/// Tests for `HoldClassifier.classifyDeucesWild`, covering the 0-, 1-, and 2-deuce
/// strategy pattern thresholds and the pair vs. two pair distinction.
final class HoldClassifierDeucesWildTests: XCTestCase {
    // MARK: - Helpers

    private func card(_ rank: Rank, _ suit: Suit) -> PlayingCard {
        PlayingCard(rank: rank, suit: suit)
    }

    // MARK: - Strategy pattern threshold correctness

    func testDW2DeuceSFThresholdBelowSix() {
        // 2♣ 2♦ 4♣ 5♣ + K♦: both naturals below rank 6 → should NOT be fourToStraightFlushTwoDeuces.
        let hand = [
            card(.two, .clubs), card(.two, .diamonds),
            card(.four, .clubs), card(.five, .clubs), card(.king, .diamonds),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3])
        XCTAssertEqual(pattern, .twoDeuces)
    }

    func testDW2DeuceSFThresholdAtSix() {
        // 2♣ 2♦ 6♣ 9♣ + K♦: both naturals ≥ 6, span 3, same suit → fourToStraightFlushTwoDeuces.
        let hand = [
            card(.two, .clubs), card(.two, .diamonds),
            card(.six, .clubs), card(.nine, .clubs), card(.king, .diamonds),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3])
        XCTAssertEqual(pattern, .fourToStraightFlushTwoDeuces)
    }

    func testDW1DeuceSFHighThresholdBelowFive() {
        // 2♠ 3♣ 4♣ 5♣ + K♦: consecutive naturals 3-4-5, lowest < 5 → fourToStraightFlushOneDeuce (not high).
        let hand = [
            card(.two, .spades), card(.three, .clubs), card(.four, .clubs),
            card(.five, .clubs), card(.king, .diamonds),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3])
        XCTAssertEqual(pattern, .fourToStraightFlushOneDeuce)
    }

    func testDW1DeuceSFHighThresholdAtFive() {
        // 2♠ 5♣ 6♣ 7♣ + K♦: consecutive naturals 5-6-7, lowest = 5 → fourToStraightFlushHighOneDeuce.
        let hand = [
            card(.two, .spades), card(.five, .clubs), card(.six, .clubs),
            card(.seven, .clubs), card(.king, .diamonds),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3])
        XCTAssertEqual(pattern, .fourToStraightFlushHighOneDeuce)
    }

    func testDW1Deuce3SFHighThresholdBelowSix() {
        // 2♠ 4♥ 5♥ + K♦ Q♠: consecutive naturals 4-5, lowest < 6 → oneDeuce.
        let hand = [
            card(.two, .spades), card(.four, .hearts), card(.five, .hearts),
            card(.king, .diamonds), card(.queen, .spades),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2])
        XCTAssertEqual(pattern, .oneDeuce)
    }

    func testDW1Deuce3SFHighThresholdAtSix() {
        // 2♠ 6♥ 7♥ + K♦ Q♠: consecutive naturals 6-7, lowest = 6 → threeToStraightFlushHighOneDeuce.
        let hand = [
            card(.two, .spades), card(.six, .hearts), card(.seven, .hearts),
            card(.king, .diamonds), card(.queen, .spades),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2])
        XCTAssertEqual(pattern, .threeToStraightFlushHighOneDeuce)
    }

    // MARK: - Two pair vs pair (no deuces held)

    func testDW0DeucesFourHeldTwoPairIsDistinctFromPair() {
        // Holding both pairs (K♦ K♣ 3♦ 3♥) from a K-9-K-3-3 deal: two ranks each held twice.
        let hand = [
            card(.king, .diamonds), card(.nine, .clubs), card(.king, .clubs),
            card(.three, .diamonds), card(.three, .hearts),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 2, 3, 4])
        XCTAssertEqual(pattern, .twoPair)
    }

    func testDW0DeucesFourHeldSinglePairWithKickersIsPair() {
        // Holding one pair plus two unrelated kickers (K♦ K♣ 3♦ 7♥): only one rank repeats.
        let hand = [
            card(.king, .diamonds), card(.nine, .clubs), card(.king, .clubs),
            card(.three, .diamonds), card(.seven, .hearts),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 2, 3, 4])
        XCTAssertEqual(pattern, .pair)
    }

    func testDW0DeucesPatFiveHeldTwoPairIsDistinctFromPair() {
        // Pat five-card hold that evaluates to two pair without wilds.
        let hand = [
            card(.king, .diamonds), card(.king, .clubs), card(.three, .diamonds),
            card(.three, .hearts), card(.nine, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3, 4])
        XCTAssertEqual(pattern, .twoPair)
    }

    func testDW0DeucesPatFiveHeldSinglePairIsPair() {
        // Pat five-card hold that evaluates to a single pair without wilds.
        let hand = [
            card(.king, .diamonds), card(.king, .clubs), card(.three, .diamonds),
            card(.seven, .hearts), card(.nine, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3, 4])
        XCTAssertEqual(pattern, .pair)
    }

    func testDW0DeucesFourHeldQuadsIsFourOfAKind() {
        // Holding all four kings (K♦ K♣ K♥ K♠) from a K-K-K-K-9 deal: one rank held four times.
        let hand = [
            card(.king, .diamonds), card(.king, .clubs), card(.king, .hearts),
            card(.king, .spades), card(.nine, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3])
        XCTAssertEqual(pattern, .fourOfAKind)
    }

    func testDW0DeucesFourHeldTripsWithKickerIsThreeOfAKind() {
        // Holding three kings plus one kicker (K♦ K♣ K♥ 3♦) from a K-K-K-3-9 deal: one rank held three times.
        let hand = [
            card(.king, .diamonds), card(.king, .clubs), card(.king, .hearts),
            card(.three, .diamonds), card(.nine, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3])
        XCTAssertEqual(pattern, .threeOfAKind)
    }
}
