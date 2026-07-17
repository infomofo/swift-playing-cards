import PlayingCard
import XCTest

/// Tests for `OptimalPlay` covering key Jacks or Better strategy decisions.
///
/// Strategy hierarchy (simplified): pat hands > 4-to-royal > 3-of-a-kind/two-pair >
/// 4-to-straight-flush > high pair > 3-to-royal > 4-to-flush > low pair >
/// 4-to-outside-straight > 2 suited high cards > 3-to-SF > unsuited high cards >
/// 1 high card > discard all.
final class OptimalPlayTests: XCTestCase {
    let engine = OptimalPlay(payTable: .jacksOrBetter96)

    // MARK: - Helpers

    private func assertOptimal(
        hand: [PlayingCard],
        expectedHeld: Set<Int>,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = engine.evaluate(hand: hand)
        XCTAssertEqual(
            result.optimalHeld, expectedHeld,
            "Expected to hold \(expectedHeld) but got \(result.optimalHeld)",
            file: file, line: line
        )
    }

    // MARK: - Pat Hands (hold all 5)

    func testPatRoyalFlushHoldsAll() {
        assertOptimal(
            hand: [
                PlayingCard(rank: .ace, suit: .spades),
                PlayingCard(rank: .king, suit: .spades),
                PlayingCard(rank: .queen, suit: .spades),
                PlayingCard(rank: .jack, suit: .spades),
                PlayingCard(rank: .ten, suit: .spades),
            ],
            expectedHeld: [0, 1, 2, 3, 4]
        )
    }

    func testPatStraightFlushHoldsAll() {
        assertOptimal(
            hand: [
                PlayingCard(rank: .nine, suit: .hearts),
                PlayingCard(rank: .eight, suit: .hearts),
                PlayingCard(rank: .seven, suit: .hearts),
                PlayingCard(rank: .six, suit: .hearts),
                PlayingCard(rank: .five, suit: .hearts),
            ],
            expectedHeld: [0, 1, 2, 3, 4]
        )
    }

    func testPatFourOfAKindHoldsAll() {
        assertOptimal(
            hand: [
                PlayingCard(rank: .ace, suit: .spades),
                PlayingCard(rank: .ace, suit: .hearts),
                PlayingCard(rank: .ace, suit: .diamonds),
                PlayingCard(rank: .ace, suit: .clubs),
                PlayingCard(rank: .king, suit: .spades),
            ],
            expectedHeld: [0, 1, 2, 3, 4]
        )
    }

    func testPatFullHouseHoldsAll() {
        assertOptimal(
            hand: [
                PlayingCard(rank: .king, suit: .spades),
                PlayingCard(rank: .king, suit: .hearts),
                PlayingCard(rank: .king, suit: .diamonds),
                PlayingCard(rank: .queen, suit: .clubs),
                PlayingCard(rank: .queen, suit: .spades),
            ],
            expectedHeld: [0, 1, 2, 3, 4]
        )
    }

    func testPatFlushHoldsAll() {
        assertOptimal(
            hand: [
                PlayingCard(rank: .ace, suit: .hearts),
                PlayingCard(rank: .jack, suit: .hearts),
                PlayingCard(rank: .eight, suit: .hearts),
                PlayingCard(rank: .five, suit: .hearts),
                PlayingCard(rank: .two, suit: .hearts),
            ],
            expectedHeld: [0, 1, 2, 3, 4]
        )
    }

    // MARK: - Four to a Royal Flush

    /// 4-to-royal beats a made straight.
    func testFourToRoyalBeatsStright() {
        // A-K-Q-J of spades + 10 of hearts = made straight, but hold 4 royals.
        let hand = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .ten, suit: .hearts),
        ]
        let result = engine.evaluate(hand: hand)
        // Should hold the 4 suited royals (indices 0-3), not the full straight.
        XCTAssertEqual(result.optimalHeld, [0, 1, 2, 3])
    }

    /// 4-to-royal beats a made flush.
    func testFourToRoyalBeatsFlush() {
        // A-K-Q-J of spades + 3 of spades = made flush, but hold 4 royals.
        let hand = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .three, suit: .spades),
        ]
        let result = engine.evaluate(hand: hand)
        XCTAssertEqual(result.optimalHeld, [0, 1, 2, 3])
    }

    // MARK: - High Pair vs. Four to a Flush

    /// A high pair (jacks or better) beats four to a flush.
    func testHighPairBeatsFourToFlush() {
        // J-J (high pair) + Q-9-7 of hearts = four to a flush.
        let hand = [
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .jack, suit: .hearts),
            PlayingCard(rank: .queen, suit: .hearts),
            PlayingCard(rank: .nine, suit: .hearts),
            PlayingCard(rank: .seven, suit: .hearts),
        ]
        let result = engine.evaluate(hand: hand)
        // High pair EV ~1.54; flush draw EV ~1.22. Hold the pair.
        XCTAssertEqual(result.optimalHeld, [0, 1])
    }

    // MARK: - Low Pair vs. Four to an Outside Straight

    /// A low pair beats four to an outside straight.
    func testLowPairBeatsFourToOutsideStraight() {
        // 7-7 (low pair) + 8-9-10 = four to an outside straight (7-8-9-10, needs 6 or J).
        let hand = [
            PlayingCard(rank: .seven, suit: .spades),
            PlayingCard(rank: .seven, suit: .hearts),
            PlayingCard(rank: .eight, suit: .clubs),
            PlayingCard(rank: .nine, suit: .diamonds),
            PlayingCard(rank: .ten, suit: .spades),
        ]
        let result = engine.evaluate(hand: hand)
        // Low pair EV ~0.82; outside straight draw EV ~0.68. Hold the pair.
        XCTAssertEqual(result.optimalHeld, [0, 1])
    }

    // MARK: - Single High Card vs. Discard All

    /// A single jack (high card) beats discarding everything.
    func testSingleHighCardBeatsDiscardAll() {
        // J-high with no draws to anything: hold the jack.
        let hand = [
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .seven, suit: .hearts),
            PlayingCard(rank: .four, suit: .clubs),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .two, suit: .hearts),
        ]
        let result = engine.evaluate(hand: hand)
        // Holding J alone gives slightly better EV than discarding all.
        XCTAssertEqual(result.optimalHeld, [0])
    }

    /// King alone beats discarding all when no other draw exists.
    func testKingHighBeatsDiscardAll() {
        let hand = [
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .seven, suit: .hearts),
            PlayingCard(rank: .four, suit: .clubs),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .two, suit: .hearts),
        ]
        let result = engine.evaluate(hand: hand)
        XCTAssertEqual(result.optimalHeld, [0])
    }

    // MARK: - EV Comparison (playerHeld)

    func testPlayerEVMatchesOptimalWhenCorrect() {
        // Royal flush: holding all 5 is optimal. Player also holds all.
        let hand = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .ten, suit: .spades),
        ]
        let result = engine.evaluate(hand: hand, playerHeld: [0, 1, 2, 3, 4])
        XCTAssertTrue(result.wasOptimal)
        XCTAssertEqual(result.evDifference ?? -1, 0.0, accuracy: 0.001)
    }

    func testEVDifferencePositiveWhenSuboptimal() {
        // High pair exists but player discards everything.
        let hand = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .seven, suit: .clubs),
            PlayingCard(rank: .four, suit: .diamonds),
            PlayingCard(rank: .two, suit: .hearts),
        ]
        let result = engine.evaluate(hand: hand, playerHeld: [])
        XCTAssertFalse(result.wasOptimal)
        XCTAssertGreaterThan(result.evDifference ?? 0, 0)
    }

    func testWasOptimalFalseWhenPlayerSuboptimal() {
        // 4-to-royal hand but player holds the full straight instead.
        let hand = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .ten, suit: .hearts),
        ]
        // Player holds all 5 (keeping the straight), optimal is to hold 0-3 (4-to-royal).
        let result = engine.evaluate(hand: hand, playerHeld: [0, 1, 2, 3, 4])
        XCTAssertFalse(result.wasOptimal)
        XCTAssertGreaterThan(result.evDifference ?? 0, 0)
    }

    func testOptimalEVIsNonNegative() {
        // Worst possible hand should still have non-negative EV (discard all = chance at quads).
        let hand = [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .four, suit: .hearts),
            PlayingCard(rank: .six, suit: .clubs),
            PlayingCard(rank: .eight, suit: .diamonds),
            PlayingCard(rank: .ten, suit: .hearts),
        ]
        let result = engine.evaluate(hand: hand)
        XCTAssertGreaterThanOrEqual(result.optimalEV, 0)
    }

    func testOptimalEVRoyalFlushIs800() {
        // Holding a made royal flush should return exactly 800x.
        let hand = [
            PlayingCard(rank: .ace, suit: .clubs),
            PlayingCard(rank: .king, suit: .clubs),
            PlayingCard(rank: .queen, suit: .clubs),
            PlayingCard(rank: .jack, suit: .clubs),
            PlayingCard(rank: .ten, suit: .clubs),
        ]
        let result = engine.evaluate(hand: hand)
        XCTAssertEqual(result.optimalEV, 800.0, accuracy: 0.001)
    }
}
