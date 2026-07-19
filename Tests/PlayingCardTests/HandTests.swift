@testable import PlayingCard
import XCTest

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
            PlayingCard(rank: .king, suit: .hearts),
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
            PlayingCard(rank: .ten, suit: .spades),
        ])

        XCTAssertEqual(hand.evaluate(), .highCard)
    }

    func testPair() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .seven, suit: .spades),
        ])

        XCTAssertEqual(hand.evaluate(), .pair)
    }

    func testTwoPair() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .three, suit: .clubs),
            PlayingCard(rank: .seven, suit: .spades),
        ])

        XCTAssertEqual(hand.evaluate(), .twoPair)
    }

    func testThreeOfAKind() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .ace, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .seven, suit: .spades),
        ])

        XCTAssertEqual(hand.evaluate(), .threeOfAKind)
    }

    func testStraight() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .three, suit: .hearts),
            PlayingCard(rank: .four, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .six, suit: .spades),
        ])

        XCTAssertEqual(hand.evaluate(), .straight)
    }

    func testWheelStraight() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .two, suit: .hearts),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .four, suit: .clubs),
            PlayingCard(rank: .five, suit: .spades),
        ])

        XCTAssertEqual(hand.evaluate(), .straight)
    }

    func testFlush() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .four, suit: .spades),
            PlayingCard(rank: .six, suit: .spades),
            PlayingCard(rank: .eight, suit: .spades),
            PlayingCard(rank: .ten, suit: .spades),
        ])

        XCTAssertEqual(hand.evaluate(), .flush)
    }

    func testFullHouse() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .ace, suit: .diamonds),
            PlayingCard(rank: .king, suit: .clubs),
            PlayingCard(rank: .king, suit: .spades),
        ])

        XCTAssertEqual(hand.evaluate(), .fullHouse)
    }

    func testFourOfAKind() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .ace, suit: .diamonds),
            PlayingCard(rank: .ace, suit: .clubs),
            PlayingCard(rank: .king, suit: .spades),
        ])

        XCTAssertEqual(hand.evaluate(), .fourOfAKind)
    }

    func testStraightFlush() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .three, suit: .spades),
            PlayingCard(rank: .four, suit: .spades),
            PlayingCard(rank: .five, suit: .spades),
            PlayingCard(rank: .six, suit: .spades),
        ])

        XCTAssertEqual(hand.evaluate(), .straightFlush)
    }

    func testRoyalFlush() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .ten, suit: .spades),
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
            PlayingCard(rank: .jack, suit: .diamonds),
        ])

        XCTAssertEqual(hand.evaluate(), .pair)
    }

    func testSevenCardStraight() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .three, suit: .hearts),
            PlayingCard(rank: .four, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .six, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts),
            PlayingCard(rank: .ace, suit: .diamonds),
        ])

        XCTAssertEqual(hand.evaluate(), .straight)
    }

    func testSevenCardFlush() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .four, suit: .spades),
            PlayingCard(rank: .six, suit: .spades),
            PlayingCard(rank: .eight, suit: .spades),
            PlayingCard(rank: .ten, suit: .spades),
            PlayingCard(rank: .three, suit: .hearts),
            PlayingCard(rank: .five, suit: .diamonds),
        ])

        XCTAssertEqual(hand.evaluate(), .flush)
    }

    func testSevenCardFullHouse() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .ace, suit: .diamonds),
            PlayingCard(rank: .king, suit: .clubs),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .two, suit: .hearts),
            PlayingCard(rank: .seven, suit: .diamonds),
        ])

        XCTAssertEqual(hand.evaluate(), .fullHouse)
    }

    func testSevenCardStraightFlush() {
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .three, suit: .spades),
            PlayingCard(rank: .four, suit: .spades),
            PlayingCard(rank: .five, suit: .spades),
            PlayingCard(rank: .six, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .king, suit: .diamonds),
        ])

        XCTAssertEqual(hand.evaluate(), .straightFlush)
    }

    func testSevenCardRoyalFlush() {
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .ten, suit: .spades),
            PlayingCard(rank: .two, suit: .hearts),
            PlayingCard(rank: .seven, suit: .diamonds),
        ])

        XCTAssertEqual(hand.evaluate(), .royalFlush)
    }

    func testSevenCardBestHandIgnoresHighestRankedCards() {
        // Best 5-card hand is a straight flush (2-3-4-5-6 of spades),
        // not using the two highest-ranked cards (A♥, K♣).
        let hand = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .three, suit: .spades),
            PlayingCard(rank: .four, suit: .spades),
            PlayingCard(rank: .five, suit: .spades),
            PlayingCard(rank: .six, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .king, suit: .clubs),
        ])

        XCTAssertEqual(hand.evaluate(), .straightFlush)
    }

    func testHandEvaluatePerformance() {
        let hand5 = Hand(cards: [
            PlayingCard(rank: .two, suit: .spades),
            PlayingCard(rank: .four, suit: .hearts),
            PlayingCard(rank: .six, suit: .diamonds),
            PlayingCard(rank: .eight, suit: .clubs),
            PlayingCard(rank: .ten, suit: .spades),
        ])
        let hand7 = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .seven, suit: .spades),
            PlayingCard(rank: .nine, suit: .hearts),
            PlayingCard(rank: .jack, suit: .diamonds),
        ])

        measure {
            for _ in 0 ..< 10000 {
                _ = hand5.evaluate()
            }
            for _ in 0 ..< 1000 {
                _ = hand7.evaluate()
            }
        }
    }

    // MARK: - Wildcard-aware evaluate

    func testEvaluateWildcardNilMatchesStandard() {
        let hand = Hand(cards: [
            PlayingCard(rank: .nine, suit: .diamonds),
            PlayingCard(rank: .two, suit: .diamonds),
            PlayingCard(rank: .five, suit: .diamonds),
            PlayingCard(rank: .four, suit: .spades),
            PlayingCard(rank: .eight, suit: .clubs),
        ])
        XCTAssertEqual(hand.evaluate(wildcardRank: nil), hand.evaluate())
    }

    func testEvaluateWildcardUpgradesHighCardToPair() {
        // 9,2,5,4,8: no natural pair; 2 is wild → at least a pair.
        let hand = Hand(cards: [
            PlayingCard(rank: .nine, suit: .diamonds),
            PlayingCard(rank: .two, suit: .diamonds),
            PlayingCard(rank: .five, suit: .diamonds),
            PlayingCard(rank: .four, suit: .spades),
            PlayingCard(rank: .eight, suit: .clubs),
        ])
        XCTAssertEqual(hand.evaluate(wildcardRank: .two), .pair)
    }

    func testEvaluateWildcardNaturalPairBecomesThreeOfAKind() {
        // 9,2,9,4,8: natural pair of 9s + wild → three of a kind.
        let hand = Hand(cards: [
            PlayingCard(rank: .nine, suit: .diamonds),
            PlayingCard(rank: .two, suit: .diamonds),
            PlayingCard(rank: .nine, suit: .hearts),
            PlayingCard(rank: .four, suit: .spades),
            PlayingCard(rank: .eight, suit: .clubs),
        ])
        XCTAssertEqual(hand.evaluate(wildcardRank: .two), .threeOfAKind)
    }

    func testEvaluateWildcardNoWildActsLikeStandard() {
        // Pair of aces, no wild cards in hand.
        let hand = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .five, suit: .clubs),
            PlayingCard(rank: .seven, suit: .spades),
        ])
        XCTAssertEqual(hand.evaluate(wildcardRank: .two), hand.evaluate())
    }

    func testEvaluateWildcardSupportsSevenCards() {
        // 7 cards: 9,9,2(wild),4,8,3,6. The best 5-card subset (9,9,2,4,8) is three of
        // a kind via the wild 9. No 5-card subset of these 7 cards forms a flush, straight,
        // full house, or four of a kind, so three of a kind is the overall best. The standard
        // (non-wildcard) evaluation of the full 7 cards is only a pair, so this also confirms
        // the wildcard-aware search is actually considering the winning subset.
        let hand = Hand(cards: [
            PlayingCard(rank: .nine, suit: .diamonds),
            PlayingCard(rank: .nine, suit: .hearts),
            PlayingCard(rank: .two, suit: .clubs),
            PlayingCard(rank: .four, suit: .spades),
            PlayingCard(rank: .eight, suit: .clubs),
            PlayingCard(rank: .three, suit: .spades),
            PlayingCard(rank: .six, suit: .diamonds),
        ])
        XCTAssertEqual(hand.evaluate(), .pair)
        XCTAssertEqual(hand.evaluate(wildcardRank: .two), .threeOfAKind)
    }

    func testEvaluateWildcardSupportsSixCards() {
        // Drop one filler card from the 7-card case above; the winning 5-card subset
        // (9,9,2,4,8) is unaffected, so the wildcard-aware result stays three of a kind.
        let hand = Hand(cards: [
            PlayingCard(rank: .nine, suit: .diamonds),
            PlayingCard(rank: .nine, suit: .hearts),
            PlayingCard(rank: .two, suit: .clubs),
            PlayingCard(rank: .four, suit: .spades),
            PlayingCard(rank: .eight, suit: .clubs),
            PlayingCard(rank: .three, suit: .spades),
        ])
        XCTAssertEqual(hand.evaluate(wildcardRank: .two), .threeOfAKind)
    }
}
