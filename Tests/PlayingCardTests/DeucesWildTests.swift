@testable import PlayingCard
import XCTest

/// Tests for Deuces Wild pay tables, hand evaluation, and optimal play.
final class DeucesWildTests: XCTestCase {
    // MARK: - Helpers

    private func card(_ rank: Rank, _ suit: Suit) -> PlayingCard {
        PlayingCard(rank: rank, suit: suit)
    }

    private func eval(_ cards: [PlayingCard]) -> HandResult {
        HandResult.evaluate(cards: cards, wildcardRank: .two)
    }

    // MARK: - New Jacks or Better pay table multipliers

    func testJacksOrBetter95Payouts() {
        let table = PayTable.jacksOrBetter95
        XCTAssertEqual(table.multiplier(for: .royalFlush), 800)
        XCTAssertEqual(table.multiplier(for: .straightFlush), 50)
        XCTAssertEqual(table.multiplier(for: .fourOfAKind), 25)
        XCTAssertEqual(table.multiplier(for: .fullHouse), 9)
        XCTAssertEqual(table.multiplier(for: .flush), 5) // 5, not 6
        XCTAssertEqual(table.multiplier(for: .straight), 4)
        XCTAssertEqual(table.multiplier(for: .threeOfAKind), 3)
        XCTAssertEqual(table.multiplier(for: .twoPair), 2)
        XCTAssertEqual(table.multiplier(for: .jacksOrBetter), 1)
        XCTAssertEqual(table.multiplier(for: .noWin), 0)
    }

    func testJacksOrBetter86Payouts() {
        let table = PayTable.jacksOrBetter86
        XCTAssertEqual(table.multiplier(for: .royalFlush), 800)
        XCTAssertEqual(table.multiplier(for: .straightFlush), 50)
        XCTAssertEqual(table.multiplier(for: .fourOfAKind), 25)
        XCTAssertEqual(table.multiplier(for: .fullHouse), 8) // 8, not 9
        XCTAssertEqual(table.multiplier(for: .flush), 6)
        XCTAssertEqual(table.multiplier(for: .straight), 4)
        XCTAssertEqual(table.multiplier(for: .threeOfAKind), 3)
        XCTAssertEqual(table.multiplier(for: .twoPair), 2)
        XCTAssertEqual(table.multiplier(for: .jacksOrBetter), 1)
        XCTAssertEqual(table.multiplier(for: .noWin), 0)
    }

    func testJacksOrBetter95Name() {
        XCTAssertEqual(PayTable.jacksOrBetter95.name, "Jacks or Better (9/5)")
    }

    func testJacksOrBetter86Name() {
        XCTAssertEqual(PayTable.jacksOrBetter86.name, "Jacks or Better (8/6)")
    }

    // MARK: - Deuces Wild pay table

    func testDeucesWildPayouts() {
        let table = PayTable.deucesWild
        XCTAssertEqual(table.multiplier(for: .naturalRoyalFlush), 800)
        XCTAssertEqual(table.multiplier(for: .fourDeuces), 200)
        XCTAssertEqual(table.multiplier(for: .wildRoyalFlush), 25)
        XCTAssertEqual(table.multiplier(for: .fiveOfAKind), 15)
        XCTAssertEqual(table.multiplier(for: .straightFlush), 9)
        XCTAssertEqual(table.multiplier(for: .fourOfAKind), 5)
        XCTAssertEqual(table.multiplier(for: .fullHouse), 3)
        XCTAssertEqual(table.multiplier(for: .flush), 2)
        XCTAssertEqual(table.multiplier(for: .straight), 2)
        XCTAssertEqual(table.multiplier(for: .threeOfAKind), 1)
        XCTAssertEqual(table.multiplier(for: .noWin), 0)
    }

    func testDeucesWildWildcardRank() {
        XCTAssertEqual(PayTable.deucesWild.wildcardRank, .two)
    }

    func testDeucesWildName() {
        XCTAssertEqual(PayTable.deucesWild.name, "Deuces Wild (Full Pay)")
    }

    // MARK: - HandResult.evaluate with wildcardRank

    func testNaturalRoyalFlush() {
        let cards = [
            card(.ace, .spades), card(.king, .spades), card(.queen, .spades),
            card(.jack, .spades), card(.ten, .spades),
        ]
        XCTAssertEqual(eval(cards), .naturalRoyalFlush)
    }

    func testNaturalRoyalFlushIsHigherThanRoyalFlush() {
        XCTAssertGreaterThan(HandResult.naturalRoyalFlush, HandResult.royalFlush)
    }

    func testFourDeuces() {
        let cards = [
            card(.two, .spades), card(.two, .hearts), card(.two, .diamonds),
            card(.two, .clubs), card(.ace, .spades),
        ]
        XCTAssertEqual(eval(cards), .fourDeuces)
    }

    func testWildRoyalFlush() {
        // A♠ K♠ Q♠ J♠ 2♥ — deuce acts as T♠, completing the royal flush.
        let cards = [
            card(.ace, .spades), card(.king, .spades), card(.queen, .spades),
            card(.jack, .spades), card(.two, .hearts),
        ]
        XCTAssertEqual(eval(cards), .wildRoyalFlush)
    }

    func testWildRoyalFlushTwoDeuces() {
        // A♠ K♠ Q♠ 2♥ 2♦ — two deuces act as J♠ and T♠.
        let cards = [
            card(.ace, .spades), card(.king, .spades), card(.queen, .spades),
            card(.two, .hearts), card(.two, .diamonds),
        ]
        XCTAssertEqual(eval(cards), .wildRoyalFlush)
    }

    func testFiveOfAKind() {
        // Four aces + one deuce → five aces.
        let cards = [
            card(.ace, .spades), card(.ace, .hearts), card(.ace, .diamonds),
            card(.ace, .clubs), card(.two, .spades),
        ]
        XCTAssertEqual(eval(cards), .fiveOfAKind)
    }

    func testFiveOfAKindThreeDeuces() {
        // K♠ K♥ 2♠ 2♥ 2♦ → two deuces fill king slots → five kings.
        let cards = [
            card(.king, .spades), card(.king, .hearts),
            card(.two, .spades), card(.two, .hearts), card(.two, .diamonds),
        ]
        XCTAssertEqual(eval(cards), .fiveOfAKind)
    }

    func testWildStraightFlush() {
        // 7♠ 8♠ 9♠ T♠ 2♥ — deuce acts as 6♠ or J♠ → straight flush.
        let cards = [
            card(.seven, .spades), card(.eight, .spades), card(.nine, .spades),
            card(.ten, .spades), card(.two, .hearts),
        ]
        XCTAssertEqual(eval(cards), .straightFlush)
    }

    func testWildFourOfAKind() {
        // K♠ K♥ K♦ 2♠ 7♣ — deuce acts as K♣ → four kings.
        let cards = [
            card(.king, .spades), card(.king, .hearts), card(.king, .diamonds),
            card(.two, .spades), card(.seven, .clubs),
        ]
        XCTAssertEqual(eval(cards), .fourOfAKind)
    }

    func testWildFullHouse() {
        // Q♠ Q♥ 7♦ 7♣ 2♠ — deuce completes trips → Q-Q-Q-7-7.
        let cards = [
            card(.queen, .spades), card(.queen, .hearts),
            card(.seven, .diamonds), card(.seven, .clubs),
            card(.two, .spades),
        ]
        XCTAssertEqual(eval(cards), .fullHouse)
    }

    func testWildFlush() {
        // 3♠ 7♠ 9♠ K♠ 2♥ — deuce can be any ♠ → flush.
        let cards = [
            card(.three, .spades), card(.seven, .spades), card(.nine, .spades),
            card(.king, .spades), card(.two, .hearts),
        ]
        XCTAssertEqual(eval(cards), .flush)
    }

    func testWildStraight() {
        // 4♠ 5♥ 7♦ 8♣ 2♠ — deuce acts as 6 → 4-5-6-7-8 straight.
        let cards = [
            card(.four, .spades), card(.five, .hearts), card(.seven, .diamonds),
            card(.eight, .clubs), card(.two, .spades),
        ]
        XCTAssertEqual(eval(cards), .straight)
    }

    func testWildThreeOfAKind() {
        // J♠ J♥ 4♦ 8♣ 2♠ — deuce acts as J → three jacks.
        let cards = [
            card(.jack, .spades), card(.jack, .hearts),
            card(.four, .diamonds), card(.eight, .clubs),
            card(.two, .spades),
        ]
        XCTAssertEqual(eval(cards), .threeOfAKind)
    }

    func testPairIsNoWinInDW() {
        // A pair without a deuce doesn't pay in Deuces Wild.
        let cards = [
            card(.king, .spades), card(.king, .hearts),
            card(.three, .diamonds), card(.seven, .clubs),
            card(.nine, .spades),
        ]
        XCTAssertEqual(eval(cards), .noWin)
    }

    func testTwoPairIsNoWinInDW() {
        let cards = [
            card(.king, .spades), card(.king, .hearts),
            card(.ace, .diamonds), card(.ace, .clubs),
            card(.seven, .spades),
        ]
        XCTAssertEqual(eval(cards), .noWin)
    }

    func testHighCardIsNoWinInDW() {
        let cards = [
            card(.ace, .spades), card(.king, .hearts),
            card(.queen, .diamonds), card(.nine, .clubs),
            card(.four, .spades),
        ]
        XCTAssertEqual(eval(cards), .noWin)
    }

    func testWheelStraightFlushInDW() {
        // A♠ 3♠ 4♠ 5♠ 2♥ — deuce acts as 2♠ → A-2-3-4-5♠ wheel SF.
        let cards = [
            card(.ace, .spades), card(.three, .spades), card(.four, .spades),
            card(.five, .spades), card(.two, .hearts),
        ]
        XCTAssertEqual(eval(cards), .straightFlush)
    }

    // MARK: - PayTable.deucesWild payout

    func testDWNaturalRoyalFlushPayoutMaxBet() {
        let table = PayTable.deucesWild
        let cards = [
            card(.ace, .spades), card(.king, .spades), card(.queen, .spades),
            card(.jack, .spades), card(.ten, .spades),
        ]
        XCTAssertEqual(table.payout(for: cards, bet: 5), 4000)
    }

    func testDWNaturalRoyalFlushPayoutSubMaxBet() {
        let table = PayTable.deucesWild
        let cards = [
            card(.ace, .spades), card(.king, .spades), card(.queen, .spades),
            card(.jack, .spades), card(.ten, .spades),
        ]
        XCTAssertEqual(table.payout(for: cards, bet: 1), 250)
    }

    func testDWFourDeucesPayout() {
        let table = PayTable.deucesWild
        let cards = [
            card(.two, .spades), card(.two, .hearts), card(.two, .diamonds),
            card(.two, .clubs), card(.ace, .spades),
        ]
        // 200 × 5 coins
        XCTAssertEqual(table.payout(for: cards, bet: 5), 1000)
    }

    func testDWFourOfAKindNetPayout() {
        let table = PayTable.deucesWild
        // J♠ J♥ J♦ 2♠ 5♣ → three jacks + wild deuce = four jacks (4K: 5x)
        // Wait: 3 natural jacks + 1 deuce → maxFreq=3 + k=1 = 4 ≥ 4 → four of a kind!
        let cards = [
            card(.jack, .spades), card(.jack, .hearts), card(.jack, .diamonds),
            card(.two, .spades), card(.five, .clubs),
        ]
        XCTAssertEqual(table.handResult(for: cards), .fourOfAKind)
        // 5 × 5 - 5 = +20
        XCTAssertEqual(table.netPayout(for: cards, bet: 5), 20)
    }

    // MARK: - HandResult ordering

    func testNewHandResultOrdering() {
        XCTAssertLessThan(HandResult.royalFlush, HandResult.fiveOfAKind)
        XCTAssertLessThan(HandResult.fiveOfAKind, HandResult.wildRoyalFlush)
        XCTAssertLessThan(HandResult.wildRoyalFlush, HandResult.fourDeuces)
        XCTAssertLessThan(HandResult.fourDeuces, HandResult.naturalRoyalFlush)
    }

    func testNewHandResultDescriptions() {
        XCTAssertEqual(HandResult.fiveOfAKind.description, "Five of a Kind")
        XCTAssertEqual(HandResult.wildRoyalFlush.description, "Wild Royal Flush")
        XCTAssertEqual(HandResult.fourDeuces.description, "Four Deuces")
        XCTAssertEqual(HandResult.naturalRoyalFlush.description, "Natural Royal Flush")
    }

    func testNewHandResultIsWin() {
        XCTAssertTrue(HandResult.fiveOfAKind.isWin)
        XCTAssertTrue(HandResult.wildRoyalFlush.isWin)
        XCTAssertTrue(HandResult.fourDeuces.isWin)
        XCTAssertTrue(HandResult.naturalRoyalFlush.isWin)
    }

    /// `HandType` has no five-of-a-kind or "four deuces" case, so the mapping from
    /// wild-only `HandResult` cases to `HandType` is intentionally lossy. This test
    /// pins down the exact (documented) approximation so any future change to it is explicit.
    func testHandResultHandTypeLossyWildMapping() {
        XCTAssertEqual(HandResult.fiveOfAKind.handType, .fourOfAKind)
        XCTAssertEqual(HandResult.fourDeuces.handType, .fourOfAKind)
        XCTAssertEqual(HandResult.wildRoyalFlush.handType, .royalFlush)
        XCTAssertEqual(HandResult.naturalRoyalFlush.handType, .royalFlush)
    }

    // MARK: - OptimalPlay with Deuces Wild

    func testDWOptimalHoldFourDeuces() async {
        // Four deuces + any kicker: always hold all.
        let engine = OptimalPlay(payTable: .deucesWild)
        let hand = [
            card(.two, .spades), card(.two, .hearts), card(.two, .diamonds),
            card(.two, .clubs), card(.ace, .spades),
        ]
        let result = await engine.evaluate(hand: hand)
        XCTAssertEqual(result.optimalHeld, [0, 1, 2, 3, 4])
        XCTAssertEqual(result.optimalEV, 200.0, accuracy: 0.001)
    }

    func testDWOptimalHoldNaturalRoyalFlushHoldsAll() async {
        let engine = OptimalPlay(payTable: .deucesWild)
        let hand = [
            card(.ace, .clubs), card(.king, .clubs), card(.queen, .clubs),
            card(.jack, .clubs), card(.ten, .clubs),
        ]
        let result = await engine.evaluate(hand: hand)
        XCTAssertEqual(result.optimalHeld, [0, 1, 2, 3, 4])
        XCTAssertEqual(result.optimalEV, 800.0, accuracy: 0.001)
    }

    func testDWOptimalHoldPatWildRoyalFlush() async {
        // A♠ K♠ Q♠ J♠ 2♥ → already a wild royal flush (25x). Hold all.
        let engine = OptimalPlay(payTable: .deucesWild)
        let hand = [
            card(.ace, .spades), card(.king, .spades), card(.queen, .spades),
            card(.jack, .spades), card(.two, .hearts),
        ]
        let result = await engine.evaluate(hand: hand)
        XCTAssertEqual(result.optimalHeld, [0, 1, 2, 3, 4])
        XCTAssertEqual(result.optimalEV, 25.0, accuracy: 0.001)
    }

    func testDWOptimalHoldThreeDeuces() async {
        // Three deuces + two non-royal naturals: hold the deuces.
        let engine = OptimalPlay(payTable: .deucesWild)
        let hand = [
            card(.two, .spades), card(.two, .hearts), card(.two, .diamonds),
            card(.three, .clubs), card(.seven, .spades),
        ]
        let result = await engine.evaluate(hand: hand)
        XCTAssertEqual(result.optimalHeld, [0, 1, 2])
    }

    func testDWOptimalEVNonNegative() async {
        let engine = OptimalPlay(payTable: .deucesWild)
        let hand = [
            card(.three, .spades), card(.six, .hearts), card(.eight, .clubs),
            card(.queen, .diamonds), card(.king, .spades),
        ]
        let result = await engine.evaluate(hand: hand)
        XCTAssertGreaterThanOrEqual(result.optimalEV, 0)
    }

    func testJoB95OptimalPlayUsesCorrectFlushMultiplier() async {
        // Flush pays 5 in 9/5 instead of 6 in 9/6. Verify engine uses the right table.
        let engine95 = OptimalPlay(payTable: .jacksOrBetter95)
        let engine96 = OptimalPlay(payTable: .jacksOrBetter96)
        // Pat flush.
        let hand = [
            card(.ace, .clubs), card(.jack, .clubs), card(.eight, .clubs),
            card(.five, .clubs), card(.two, .clubs),
        ]
        let result95 = await engine95.evaluate(hand: hand)
        let result96 = await engine96.evaluate(hand: hand)
        // 9/6 flush = 6x, 9/5 flush = 5x.
        XCTAssertEqual(result96.optimalEV, 6.0, accuracy: 0.001)
        XCTAssertEqual(result95.optimalEV, 5.0, accuracy: 0.001)
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
}
