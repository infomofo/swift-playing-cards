import PlayingCard
import XCTest

/// Compile-time and runtime verification of the full public API surface.
///
/// Every public type, initializer, property, and method is referenced here.
/// If anything is accidentally made internal, renamed, or removed, this file
/// will fail to compile before it reaches downstream consumers.
///
/// This is not a correctness test — correctness is covered by the type-specific
/// test files. This is a surface test: does the public contract still exist?
final class PublicAPITests: XCTestCase {
    // MARK: - PlayingCard, Rank, Suit

    func testPlayingCardPublicInterface() {
        let card = PlayingCard(rank: .ace, suit: .spades)
        let _: Rank = card.rank
        let _: Suit = card.suit
        XCTAssertEqual(card, PlayingCard(rank: .ace, suit: .spades))
        XCTAssertNotEqual(card, PlayingCard(rank: .king, suit: .hearts))
        // Hashable
        var set = Set<PlayingCard>()
        set.insert(card)
        XCTAssertTrue(set.contains(card))
        // Comparable
        XCTAssertLessThan(PlayingCard(rank: .two, suit: .clubs), PlayingCard(rank: .ace, suit: .spades))
    }

    func testRankPublicInterface() {
        XCTAssertEqual(Rank.allCases.count, 13)
        // rawValue
        XCTAssertEqual(Rank.ace.rawValue, 14)
        XCTAssertEqual(Rank.two.rawValue, 2)
        // description, name, compactDescription
        let _: String = Rank.ace.description
        let _: String = Rank.ace.name
        let _: String = Rank.ace.compactDescription
        // CaseIterable + Comparable
        XCTAssertLessThan(Rank.two, Rank.ace)
    }

    func testSuitPublicInterface() {
        XCTAssertEqual(Suit.allCases.count, 4)
        let _: String = Suit.spades.rawValue
        let _: String = Suit.spades.description
        // Comparable
        XCTAssertTrue(Suit.allCases.contains(.spades))
    }

    // MARK: - Deck

    func testDeckPublicInterface() {
        var deck = Deck()
        XCTAssertEqual(deck.count, 52)
        XCTAssertFalse(deck.isEmpty)
        XCTAssertEqual(deck.remainingCards.count, 52)

        let single = deck.dealCard()
        XCTAssertNotNil(single)
        XCTAssertEqual(deck.count, 51)

        let batch = deck.dealCards(5)
        XCTAssertEqual(batch.count, 5)

        deck.shuffle()
        deck.reset()
        XCTAssertEqual(deck.count, 52)

        // init(cards:)
        let seeded = Deck(cards: [PlayingCard(rank: .ace, suit: .spades)])
        XCTAssertEqual(seeded.count, 1)
    }

    // MARK: - Hand, HandType

    func testHandPublicInterface() {
        let royalFlush: [PlayingCard] = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .ten, suit: .spades),
        ]
        let hand = Hand(cards: royalFlush)
        let result: HandType = hand.evaluate()
        XCTAssertEqual(result, .royalFlush)

        let pair = Hand(cards: [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .ace, suit: .hearts),
            PlayingCard(rank: .two, suit: .clubs),
            PlayingCard(rank: .three, suit: .diamonds),
            PlayingCard(rank: .four, suit: .spades),
        ])
        XCTAssertEqual(pair.evaluate(), .pair)
    }

    func testHandTypePublicInterface() {
        XCTAssertFalse(HandType.allCases.isEmpty)
        let _: String = HandType.royalFlush.description
        // Comparable
        XCTAssertLessThan(HandType.highCard, HandType.royalFlush)
        // rawValue (Int)
        XCTAssertGreaterThan(HandType.royalFlush.rawValue, HandType.highCard.rawValue)
    }

    // MARK: - HandResult, PayTable

    func testHandResultPublicInterface() {
        XCTAssertFalse(HandResult.allCases.isEmpty)
        let _: String = HandResult.royalFlush.description
        XCTAssertTrue(HandResult.royalFlush.isWin)
        XCTAssertFalse(HandResult.noWin.isWin)
        // Comparable
        XCTAssertLessThan(HandResult.noWin, HandResult.royalFlush)

        let cards: [PlayingCard] = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .ten, suit: .spades),
        ]
        let result = HandResult.evaluate(cards: cards)
        XCTAssertEqual(result, .royalFlush)
    }

    func testPayTablePublicInterface() {
        let table = PayTable.jacksOrBetter96
        let _: String = table.name

        // multiplier(for:)
        XCTAssertEqual(table.multiplier(for: .royalFlush), 800)
        XCTAssertEqual(table.multiplier(for: .noWin), 0)

        let cards: [PlayingCard] = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .ten, suit: .spades),
        ]

        // handResult(for:), payout(for:bet:), netPayout(for:bet:)
        XCTAssertEqual(table.handResult(for: cards), .royalFlush)
        XCTAssertEqual(table.payout(for: cards, bet: 5), 4000)
        XCTAssertEqual(table.netPayout(for: cards, bet: 5), 3995)

        // custom init
        let custom = PayTable(name: "Custom", multipliers: [.royalFlush: 1000])
        XCTAssertEqual(custom.multiplier(for: .royalFlush), 1000)
        XCTAssertEqual(custom.multiplier(for: .noWin), 0)
    }

    // MARK: - CardFlipAnimator

    func testCardFlipAnimatorPublicInterface() {
        // isFrontVisible / isBackVisible
        XCTAssertTrue(CardFlipAnimator.isFrontVisible(at: 0))
        XCTAssertTrue(CardFlipAnimator.isFrontVisible(at: 90))
        XCTAssertFalse(CardFlipAnimator.isFrontVisible(at: 91))
        XCTAssertFalse(CardFlipAnimator.isBackVisible(at: 90))
        XCTAssertTrue(CardFlipAnimator.isBackVisible(at: 91))

        // backFaceRotation
        XCTAssertEqual(CardFlipAnimator.backFaceRotation(at: 180), 0)

        // rippleDelay
        XCTAssertEqual(CardFlipAnimator.rippleDelay(for: 0), 0.0)
        XCTAssertEqual(CardFlipAnimator.rippleDelay(for: 1), 0.1, accuracy: 0.001)
        XCTAssertEqual(CardFlipAnimator.rippleDelay(for: 2), 0.2, accuracy: 0.001)

        // frontFaceScale / backFaceScale
        XCTAssertEqual(CardFlipAnimator.frontFaceScale(at: 0), 1.0, accuracy: 0.001)
        XCTAssertEqual(CardFlipAnimator.frontFaceScale(at: 90), 0.9, accuracy: 0.001)
        XCTAssertEqual(CardFlipAnimator.backFaceScale(at: 180), 1.0, accuracy: 0.001)
    }

    // MARK: - VideoPokerExample

    func testVideoPokerExamplePublicInterface() {
        let hand = VideoPokerExample.playExampleHand()
        XCTAssertFalse(hand.isEmpty)

        let comparison = VideoPokerExample.demonstrateHandComparison()
        XCTAssertFalse(comparison.isEmpty)

        let probs = VideoPokerExample.demonstrateProbabilities()
        XCTAssertFalse(probs.isEmpty)

        let multi = VideoPokerExample.runMultipleHands(count: 1)
        XCTAssertFalse(multi.isEmpty)
    }
}
