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

    // MARK: - 0-deuce mixed-suit fallbacks (no pair, no flush/straight-flush draw)

    func testDW0DeucesThreeHeldMixedSuitOneHighCardIsOneHighCard() {
        // J♠ T♣ 9♥ held from a J-4-T-9-T deal: mixed suits, no pair, one card ranked J+.
        let hand = [
            card(.jack, .spades), card(.four, .hearts),
            card(.ten, .clubs), card(.nine, .hearts), card(.ten, .diamonds),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 2, 3])
        XCTAssertEqual(pattern, .oneHighCard)
    }

    func testDW0DeucesThreeHeldMixedSuitTwoHighCardsIsTwoUnsuitedHighCards() {
        // J♠ Q♣ 4♥ held: mixed suits, no pair, two cards ranked J+.
        let hand = [
            card(.jack, .spades), card(.queen, .clubs), card(.four, .hearts),
            card(.six, .diamonds), card(.eight, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2])
        XCTAssertEqual(pattern, .twoUnsuitedHighCards)
    }

    func testDW0DeucesThreeHeldMixedSuitAllRoyalIsThreeUnsuitedHighCards() {
        // J♠ Q♣ A♥ held: mixed suits, no pair, all three in the royal set {T-A}.
        let hand = [
            card(.jack, .spades), card(.queen, .clubs), card(.ace, .hearts),
            card(.six, .diamonds), card(.eight, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2])
        XCTAssertEqual(pattern, .threeUnsuitedHighCards)
    }

    func testDW0DeucesThreeHeldMixedSuitNoHighCardsIsDiscardAll() {
        // 4♠ 6♣ 8♥ held: mixed suits, no pair, no card ranked J+.
        let hand = [
            card(.four, .spades), card(.six, .clubs), card(.eight, .hearts),
            card(.jack, .diamonds), card(.queen, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2])
        XCTAssertEqual(pattern, .discardAll)
    }

    func testDW0DeucesFourHeldMixedSuitOneHighCardIsOneHighCard() {
        // J♠ 4♣ 6♥ 8♦ held: mixed suits, no pair, no straight draw, one card ranked J+.
        let hand = [
            card(.jack, .spades), card(.four, .clubs),
            card(.six, .hearts), card(.eight, .diamonds), card(.queen, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3])
        XCTAssertEqual(pattern, .oneHighCard)
    }

    func testDW0DeucesFourHeldMixedSuitTwoHighCardsIsTwoUnsuitedHighCards() {
        // J♠ Q♣ 4♥ 6♦ held: mixed suits, no pair, no straight draw, two cards ranked J+.
        let hand = [
            card(.jack, .spades), card(.queen, .clubs),
            card(.four, .hearts), card(.six, .diamonds), card(.eight, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3])
        XCTAssertEqual(pattern, .twoUnsuitedHighCards)
    }

    func testDW0DeucesFourHeldMixedSuitNoHighCardsIsDiscardAll() {
        // 4♠ 6♣ 8♥ 3♦ held: mixed suits, no pair, no straight draw, no card ranked J+.
        let hand = [
            card(.four, .spades), card(.six, .clubs),
            card(.eight, .hearts), card(.three, .diamonds), card(.queen, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3])
        XCTAssertEqual(pattern, .discardAll)
    }

    func testDW0DeucesTwoHeldMixedSuitOneHighCardIsOneHighCard() {
        // J♠ 4♥ held: mixed suits, no pair, one card ranked J+.
        let hand = [
            card(.jack, .spades), card(.four, .hearts),
            card(.six, .diamonds), card(.eight, .clubs), card(.nine, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1])
        XCTAssertEqual(pattern, .oneHighCard)
    }

    func testDW0DeucesTwoHeldUnsuitedHighCardsIsTwoUnsuitedHighCards() {
        // J♠ Q♥ held: mixed suits, both cards ranked J+.
        let hand = [
            card(.jack, .spades), card(.queen, .hearts),
            card(.six, .diamonds), card(.eight, .clubs), card(.nine, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1])
        XCTAssertEqual(pattern, .twoUnsuitedHighCards)
    }

    func testDW0DeucesTwoHeldMixedSuitNoHighCardsIsDiscardAll() {
        // 4♠ 6♥ held: mixed suits, no pair, no card ranked J+.
        let hand = [
            card(.four, .spades), card(.six, .hearts),
            card(.jack, .diamonds), card(.eight, .clubs), card(.nine, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1])
        XCTAssertEqual(pattern, .discardAll)
    }

    // MARK: - 2-deuce coverage (pat hand, royal/SF draws, base fallback)

    func testDW2DeucesPatHandFiveOfAKindIsPatHandTwoDeuces() {
        // 2♦ 2♥ K♣ K♠ K♦ held: 2 deuces + trip kings evaluates to five of a kind with wilds.
        let hand = [
            card(.two, .diamonds), card(.two, .hearts),
            card(.king, .clubs), card(.king, .spades), card(.king, .diamonds),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3, 4])
        XCTAssertEqual(pattern, .patHandTwoDeuces)
    }

    func testDW2DeucesOneRoyalNaturalIsFourToRoyalFlushTwoDeuces() {
        // 2♦ 2♥ Q♣ held (3 cards): 1 royal natural completes 4 to a wild royal.
        let hand = [
            card(.two, .diamonds), card(.two, .hearts), card(.queen, .clubs),
            card(.four, .spades), card(.six, .diamonds),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2])
        XCTAssertEqual(pattern, .fourToRoyalFlushTwoDeuces)
    }

    func testDW2DeucesTwoRoyalNaturalsSameSuitIsFourToRoyalFlushTwoDeuces() {
        // 2♦ 2♥ Q♣ K♣ held: 2 same-suit royal naturals complete 4 to a wild royal.
        let hand = [
            card(.two, .diamonds), card(.two, .hearts),
            card(.queen, .clubs), card(.king, .clubs), card(.six, .diamonds),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3])
        XCTAssertEqual(pattern, .fourToRoyalFlushTwoDeuces)
    }

    func testDW2DeucesAloneIsTwoDeuces() {
        // 2♦ 2♥ held alone (no naturals) is the base two-deuces pattern.
        let hand = [
            card(.two, .diamonds), card(.two, .hearts),
            card(.six, .clubs), card(.nine, .clubs), card(.king, .spades),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1])
        XCTAssertEqual(pattern, .twoDeuces)
    }

    func testDW2DeucesOneLowNaturalFallsToTwoDeuces() {
        // 2♦ 2♥ 4♣ held: the extra natural isn't royal, no better pattern than twoDeuces.
        let hand = [
            card(.two, .diamonds), card(.two, .hearts), card(.four, .clubs),
            card(.nine, .clubs), card(.king, .spades),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2])
        XCTAssertEqual(pattern, .twoDeuces)
    }

    func testDW2DeucesTwoRoyalNaturalsDifferentSuitsFallsToTwoDeuces() {
        // 2♦ 2♥ Q♣ K♦ held: both royal but different suits, no wild-royal draw possible.
        let hand = [
            card(.two, .diamonds), card(.two, .hearts),
            card(.queen, .clubs), card(.king, .diamonds), card(.six, .spades),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3])
        XCTAssertEqual(pattern, .twoDeuces)
    }

    // MARK: - 1-deuce coverage (pat hand variants, royal/SF draws, base fallback)

    func testDW1DeucePatFourOfAKindIsPatHandOneDeuce() {
        // 2♦ K♣ K♠ K♦ 9♥ held: 1 deuce + trip kings evaluates to four of a kind with wild.
        let hand = [
            card(.two, .diamonds), card(.king, .clubs), card(.king, .spades),
            card(.king, .diamonds), card(.nine, .hearts),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3, 4])
        XCTAssertEqual(pattern, .patHandOneDeuce)
    }

    func testDW1DeucePatTwoPairIsPatFullHouseOneDeuce() {
        // 2♦ K♣ K♠ 9♥ 9♦ held: 1 deuce + two natural pairs promotes to a full house.
        let hand = [
            card(.two, .diamonds), card(.king, .clubs), card(.king, .spades),
            card(.nine, .hearts), card(.nine, .diamonds),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3, 4])
        XCTAssertEqual(pattern, .patFullHouseOneDeuce)
    }

    func testDW1DeucePatOnePairIsPatLowHandOneDeuceThreeOfAKind() {
        // 2♦ K♣ K♠ 6♥ 9♦ held: 1 deuce + one natural pair promotes to three of a kind.
        let hand = [
            card(.two, .diamonds), card(.king, .clubs), card(.king, .spades),
            card(.six, .hearts), card(.nine, .diamonds),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3, 4])
        XCTAssertEqual(pattern, .patLowHandOneDeuce)
    }

    func testDW1DeucePatStraightIsPatLowHandOneDeuce() {
        // 2♦ 4♣ 5♥ 6♠ 8♦ held: 1 deuce completes a straight (4-5-6-2(as 7 or 3)-8... verified below).
        let hand = [
            card(.two, .diamonds), card(.four, .clubs), card(.five, .hearts),
            card(.six, .spades), card(.eight, .diamonds),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3, 4])
        XCTAssertEqual(pattern, .patLowHandOneDeuce)
    }

    func testDW1DeucePatFlushIsPatLowHandOneDeuce() {
        // 2♦ 4♣ 7♣ 9♣ J♣ held: 1 deuce + four clubs is a flush with the deuce as itself or wild.
        let hand = [
            card(.two, .diamonds), card(.four, .clubs), card(.seven, .clubs),
            card(.nine, .clubs), card(.jack, .clubs),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3, 4])
        XCTAssertEqual(pattern, .patLowHandOneDeuce)
    }

    func testDW1DeucePatBelowThreeOfAKindFallsToOneDeuce() {
        // 2♦ 3♣ 5♥ 8♠ 9♦ held: naturals have no pair; the deuce can only pair with the
        // highest (9), which is below jacks-or-better, so the pat-hand switch doesn't
        // match and this falls through to the base oneDeuce label.
        let hand = [
            card(.two, .diamonds), card(.three, .clubs), card(.five, .hearts),
            card(.eight, .spades), card(.nine, .diamonds),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3, 4])
        XCTAssertEqual(pattern, .oneDeuce)
    }

    func testDW1DeuceFourToRoyalFlushOneDeuce() {
        // 2♦ J♣ Q♣ K♣ held (4 cards): 3 same-suit royal naturals + deuce = 4 to a wild royal.
        let hand = [
            card(.two, .diamonds), card(.jack, .clubs), card(.queen, .clubs),
            card(.king, .clubs), card(.nine, .hearts),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3])
        XCTAssertEqual(pattern, .fourToRoyalFlushOneDeuce)
    }

    func testDW1DeuceFourToStraightFlushOneDeuceLowThreshold() {
        // 2♦ 3♣ 4♣ 5♣ held: consecutive naturals below rank 5 → not the "high" variant.
        let hand = [
            card(.two, .diamonds), card(.three, .clubs), card(.four, .clubs),
            card(.five, .clubs), card(.nine, .hearts),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2, 3])
        XCTAssertEqual(pattern, .fourToStraightFlushOneDeuce)
    }

    func testDW1DeuceThreeToRoyalFlushOneDeuce() {
        // 2♦ Q♣ K♣ held (3 cards): 2 same-suit royal naturals + deuce = 3 to a wild royal.
        let hand = [
            card(.two, .diamonds), card(.queen, .clubs), card(.king, .clubs),
            card(.nine, .hearts), card(.four, .spades),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1, 2])
        XCTAssertEqual(pattern, .threeToRoyalFlushOneDeuce)
    }

    func testDW1DeuceAloneIsOneDeuce() {
        // 2♦ held alone (no naturals) is the base one-deuce pattern.
        let hand = [
            card(.two, .diamonds), card(.six, .clubs), card(.seven, .clubs),
            card(.nine, .hearts), card(.four, .spades),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0])
        XCTAssertEqual(pattern, .oneDeuce)
    }

    func testDW1DeuceOneLowNaturalFallsToOneDeuce() {
        // 2♦ 6♣ held: single non-royal natural, no better pattern than oneDeuce.
        let hand = [
            card(.two, .diamonds), card(.six, .clubs), card(.seven, .clubs),
            card(.nine, .hearts), card(.four, .spades),
        ]
        let pattern = HoldClassifier.classifyDeucesWild(hand: hand, holding: [0, 1])
        XCTAssertEqual(pattern, .oneDeuce)
    }
}
