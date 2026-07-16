@testable import PlayingCard
import XCTest

final class PayTableTests: XCTestCase {
    // MARK: - HandResult.evaluate

    func testRoyalFlush() {
        let cards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .ten, suit: .spades),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .royalFlush)
    }

    func testStraightFlush() {
        let cards = [
            PlayingCard(rank: .nine, suit: .hearts),
            PlayingCard(rank: .eight, suit: .hearts),
            PlayingCard(rank: .seven, suit: .hearts),
            PlayingCard(rank: .six, suit: .hearts),
            PlayingCard(rank: .five, suit: .hearts),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .straightFlush)
    }

    func testFourOfAKind() {
        let cards = [
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts),
            PlayingCard(rank: .king, suit: .diamonds),
            PlayingCard(rank: .king, suit: .clubs),
            PlayingCard(rank: .two, suit: .spades),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .fourOfAKind)
    }

    func testFullHouse() {
        let cards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .ace, suit: .diamonds),
            PlayingCard(rank: .king, suit: .clubs),
            PlayingCard(rank: .king, suit: .spades),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .fullHouse)
    }

    func testFlush() {
        let cards = [
            PlayingCard(rank: .ace, suit: .clubs),
            PlayingCard(rank: .ten, suit: .clubs),
            PlayingCard(rank: .seven, suit: .clubs),
            PlayingCard(rank: .four, suit: .clubs),
            PlayingCard(rank: .two, suit: .clubs),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .flush)
    }

    func testStraight() {
        let cards = [
            PlayingCard(rank: .nine, suit: .spades),
            PlayingCard(rank: .eight, suit: .hearts),
            PlayingCard(rank: .seven, suit: .diamonds),
            PlayingCard(rank: .six, suit: .clubs),
            PlayingCard(rank: .five, suit: .spades),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .straight)
    }

    func testThreeOfAKind() {
        let cards = [
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .queen, suit: .hearts),
            PlayingCard(rank: .queen, suit: .diamonds),
            PlayingCard(rank: .nine, suit: .clubs),
            PlayingCard(rank: .two, suit: .spades),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .threeOfAKind)
    }

    func testTwoPair() {
        let cards = [
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .three, suit: .clubs),
            PlayingCard(rank: .ace, suit: .spades),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .twoPair)
    }

    func testJacksOrBetter_jack() {
        let cards = [
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .jack, suit: .hearts),
            PlayingCard(rank: .nine, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .two, suit: .spades),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .jacksOrBetter)
    }

    func testJacksOrBetter_queen() {
        let cards = [
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .queen, suit: .clubs),
            PlayingCard(rank: .seven, suit: .hearts),
            PlayingCard(rank: .four, suit: .diamonds),
            PlayingCard(rank: .two, suit: .spades),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .jacksOrBetter)
    }

    func testJacksOrBetter_king() {
        let cards = [
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .king, suit: .clubs),
            PlayingCard(rank: .seven, suit: .hearts),
            PlayingCard(rank: .four, suit: .diamonds),
            PlayingCard(rank: .two, suit: .spades),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .jacksOrBetter)
    }

    func testJacksOrBetter_ace() {
        let cards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .clubs),
            PlayingCard(rank: .seven, suit: .hearts),
            PlayingCard(rank: .four, suit: .diamonds),
            PlayingCard(rank: .two, suit: .spades),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .jacksOrBetter)
    }

    func testLowPairIsNoWin() {
        let cards = [
            PlayingCard(rank: .ten, suit: .spades),
            PlayingCard(rank: .ten, suit: .hearts),
            PlayingCard(rank: .nine, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .two, suit: .spades),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .noWin)
    }

    func testHighCardIsNoWin() {
        let cards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts),
            PlayingCard(rank: .nine, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .two, suit: .spades),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .noWin)
    }

    func testIncompleteHandIsNoWin() {
        let cards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts),
        ]
        XCTAssertEqual(HandResult.evaluate(cards: cards), .noWin)
    }

    // MARK: - PayTable payouts

    func testJacksOrBetter96Payouts() {
        let table = PayTable.jacksOrBetter96
        XCTAssertEqual(table.multiplier(for: .royalFlush), 800)
        XCTAssertEqual(table.multiplier(for: .straightFlush), 50)
        XCTAssertEqual(table.multiplier(for: .fourOfAKind), 25)
        XCTAssertEqual(table.multiplier(for: .fullHouse), 9)
        XCTAssertEqual(table.multiplier(for: .flush), 6)
        XCTAssertEqual(table.multiplier(for: .straight), 4)
        XCTAssertEqual(table.multiplier(for: .threeOfAKind), 3)
        XCTAssertEqual(table.multiplier(for: .twoPair), 2)
        XCTAssertEqual(table.multiplier(for: .jacksOrBetter), 1)
        XCTAssertEqual(table.multiplier(for: .noWin), 0)
    }

    func testNetPayoutTwoPair() {
        let table = PayTable.jacksOrBetter96
        let cards = [
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .three, suit: .clubs),
            PlayingCard(rank: .ace, suit: .spades),
        ]
        XCTAssertEqual(table.netPayout(for: cards, bet: 5), 5) // 2x * 5 - 5 = +5
    }

    func testNetPayoutJacksOrBetter() {
        let table = PayTable.jacksOrBetter96
        let cards = [
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .jack, suit: .hearts),
            PlayingCard(rank: .nine, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .two, suit: .spades),
        ]
        XCTAssertEqual(table.netPayout(for: cards, bet: 5), 0) // 1x * 5 - 5 = 0 (push)
    }

    func testNetPayoutNoWin() {
        let table = PayTable.jacksOrBetter96
        let cards = [
            PlayingCard(rank: .ten, suit: .spades),
            PlayingCard(rank: .ten, suit: .hearts),
            PlayingCard(rank: .nine, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .two, suit: .spades),
        ]
        XCTAssertEqual(table.netPayout(for: cards, bet: 5), -5) // 0x * 5 - 5 = -5
    }

    func testNetPayoutFullHouse() {
        let table = PayTable.jacksOrBetter96
        let cards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .ace, suit: .diamonds),
            PlayingCard(rank: .king, suit: .clubs),
            PlayingCard(rank: .king, suit: .spades),
        ]
        XCTAssertEqual(table.netPayout(for: cards, bet: 5), 40) // 9x * 5 - 5 = +40
    }

    // MARK: - HandResult ordering

    func testHandResultOrdering() {
        XCTAssertLessThan(HandResult.noWin, .jacksOrBetter)
        XCTAssertLessThan(HandResult.jacksOrBetter, .twoPair)
        XCTAssertLessThan(HandResult.twoPair, .threeOfAKind)
        XCTAssertLessThan(HandResult.threeOfAKind, .straight)
        XCTAssertLessThan(HandResult.straight, .flush)
        XCTAssertLessThan(HandResult.flush, .fullHouse)
        XCTAssertLessThan(HandResult.fullHouse, .fourOfAKind)
        XCTAssertLessThan(HandResult.fourOfAKind, .straightFlush)
        XCTAssertLessThan(HandResult.straightFlush, .royalFlush)
    }

    // MARK: - isWin

    func testIsWin() {
        XCTAssertFalse(HandResult.noWin.isWin)
        XCTAssertTrue(HandResult.jacksOrBetter.isWin)
        XCTAssertTrue(HandResult.royalFlush.isWin)
    }
}
