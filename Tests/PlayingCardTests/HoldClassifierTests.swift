import PlayingCard
import Testing

// MARK: - Shared helpers

extension HoldClassifierTests {
    func card(_ rank: Rank, _ suit: Suit) -> PlayingCard {
        PlayingCard(rank: rank, suit: suit)
    }

    func classify(hand: [PlayingCard], holding: Set<Int>) -> StrategyPattern {
        HoldClassifier.classify(hand: hand, holding: holding)
    }
}

@Suite("HoldClassifier: basic patterns")
struct HoldClassifierTests {
    // MARK: - Discard All / One Card

    @Test func testDiscardAll() {
        let hand = [
            card(.two, .hearts), card(.five, .clubs), card(.seven, .diamonds),
            card(.nine, .spades), card(.jack, .hearts),
        ]
        #expect(classify(hand: hand, holding: []) == .discardAll)
    }

    @Test func oneHighCardJack() {
        let hand = [
            card(.jack, .spades), card(.three, .hearts), card(.six, .clubs),
            card(.eight, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0]) == .oneHighCard)
    }

    @Test func oneHighCardAce() {
        let hand = [
            card(.ace, .hearts), card(.four, .clubs), card(.seven, .spades),
            card(.nine, .diamonds), card(.two, .hearts),
        ]
        #expect(classify(hand: hand, holding: [0]) == .oneHighCard)
    }

    @Test func oneLowCardIsDiscardAll() {
        let hand = [
            card(.two, .hearts), card(.five, .clubs), card(.seven, .diamonds),
            card(.nine, .spades), card(.jack, .hearts),
        ]
        #expect(classify(hand: hand, holding: [0]) == .discardAll)
    }

    // MARK: - High Pair

    @Test func highPairJacks() {
        let hand = [
            card(.jack, .spades), card(.jack, .hearts), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1]) == .highPair)
    }

    @Test func highPairAces() {
        let hand = [
            card(.ace, .spades), card(.ace, .hearts), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1]) == .highPair)
    }

    // MARK: - Low Pair

    @Test func lowPairTens() {
        let hand = [
            card(.ten, .spades), card(.ten, .hearts), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1]) == .lowPair)
    }

    @Test func lowPairTwos() {
        let hand = [
            card(.two, .spades), card(.two, .hearts), card(.three, .clubs),
            card(.seven, .diamonds), card(.jack, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1]) == .lowPair)
    }

    // MARK: - Two Suited High Cards

    @Test func twoSuitedHighCardsAceKing() {
        let hand = [
            card(.ace, .spades), card(.king, .spades), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .hearts),
        ]
        #expect(classify(hand: hand, holding: [0, 1]) == .twoSuitedHighCards)
    }

    @Test func twoSuitedHighCardsQueenJack() {
        let hand = [
            card(.queen, .hearts), card(.jack, .hearts), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1]) == .twoSuitedHighCards)
    }

    // MARK: - Two Unsuited High Cards

    @Test func twoUnsuitedHighCardsKingQueen() {
        let hand = [
            card(.king, .spades), card(.queen, .hearts), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1]) == .twoUnsuitedHighCards)
    }

    @Test func twoUnsuitedHighCardsAceJack() {
        let hand = [
            card(.ace, .clubs), card(.jack, .diamonds), card(.three, .hearts),
            card(.seven, .spades), card(.two, .clubs),
        ]
        #expect(classify(hand: hand, holding: [0, 1]) == .twoUnsuitedHighCards)
    }

    // MARK: - Suited Ten + High Card

    @Test func suitedTenKing() {
        let hand = [
            card(.ten, .spades), card(.king, .spades), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .hearts),
        ]
        #expect(classify(hand: hand, holding: [0, 1]) == .suitedTenHighCard)
    }

    @Test func suitedTenAce() {
        let hand = [
            card(.ten, .hearts), card(.ace, .hearts), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1]) == .suitedTenHighCard)
    }

    // MARK: - Three to Royal Flush

    @Test func threeToRoyalFlushUserExample() {
        // K♠ T♠ Q♠: optimal in the user's K♠ T♠ 3♣ Q♠ 8♠ hand
        let hand = [
            card(.king, .spades), card(.ten, .spades), card(.three, .clubs),
            card(.queen, .spades), card(.eight, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 3]) == .threeToRoyalFlush)
    }

    @Test func threeToRoyalFlushAceKingJack() {
        let hand = [
            card(.ace, .diamonds), card(.king, .diamonds), card(.jack, .diamonds),
            card(.three, .clubs), card(.seven, .hearts),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2]) == .threeToRoyalFlush)
    }

    @Test func threeToRoyalFlushQueenJackTen() {
        let hand = [
            card(.queen, .clubs), card(.jack, .clubs), card(.ten, .clubs),
            card(.two, .hearts), card(.nine, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2]) == .threeToRoyalFlush)
    }

    // MARK: - Three to Straight Flush

    @Test func threeToStraightFlushConsecutive() {
        let hand = [
            card(.seven, .hearts), card(.eight, .hearts), card(.nine, .hearts),
            card(.ace, .spades), card(.king, .clubs),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2]) == .threeToStraightFlush)
    }

    @Test func threeToStraightFlushWithGap() {
        let hand = [
            card(.six, .clubs), card(.eight, .clubs), card(.nine, .clubs),
            card(.ace, .spades), card(.king, .hearts),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2]) == .threeToStraightFlush)
    }

    // MARK: - Three to Flush (regression cases)

    /// Three suited cards with high-card spread too large for SF draw.
    /// Regression: previously fell through allSameSuit block and returned twoUnsuitedHighCards.
    /// Hand: 4d 6c Kc 9h Ac, held 6c Kc Ac (indices 1,2,4).
    @Test func threeToFlushHighLowMixed() {
        let hand = [
            card(.four, .diamonds), card(.six, .clubs), card(.king, .clubs),
            card(.nine, .hearts), card(.ace, .clubs),
        ]
        #expect(classify(hand: hand, holding: [1, 2, 4]) == .threeToFlush)
    }

    /// Three low suited cards not forming any straight flush draw.
    /// Regression: previously fell through allSameSuit block and returned discardAll.
    /// Hand: 4c 9h Tc 2d 6c, held 4c Tc 6c (indices 0,2,4).
    @Test func threeToFlushAllLow() {
        let hand = [
            card(.four, .clubs), card(.nine, .hearts), card(.ten, .clubs),
            card(.two, .diamonds), card(.six, .clubs),
        ]
        #expect(classify(hand: hand, holding: [0, 2, 4]) == .threeToFlush)
    }

    // MARK: - Three of a Kind (3-card hold)

    @Test func threeOfAKindHeld() {
        let hand = [
            card(.seven, .spades), card(.seven, .hearts), card(.seven, .diamonds),
            card(.ace, .clubs), card(.king, .clubs),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2]) == .threeOfAKind)
    }

    // MARK: - Four to Royal Flush

    @Test func fourToRoyalFlushThroughKing() {
        let hand = [
            card(.ten, .spades), card(.jack, .spades), card(.queen, .spades),
            card(.king, .spades), card(.two, .hearts),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToRoyalFlush)
    }

    @Test func fourToRoyalFlushAceHigh() {
        let hand = [
            card(.ace, .hearts), card(.king, .hearts), card(.queen, .hearts),
            card(.jack, .hearts), card(.three, .clubs),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToRoyalFlush)
    }

    // MARK: - Four to Straight Flush

    @Test func fourToStraightFlushConsecutive() {
        let hand = [
            card(.five, .clubs), card(.six, .clubs), card(.seven, .clubs),
            card(.eight, .clubs), card(.ace, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToStraightFlush)
    }

    @Test func fourToStraightFlushNotFlush() {
        let hand = [
            card(.three, .hearts), card(.four, .hearts), card(.five, .hearts),
            card(.six, .hearts), card(.ace, .clubs),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToStraightFlush)
    }

    // MARK: - Four to Flush

    @Test func fourToFlushNonConsecutive() {
        let hand = [
            card(.two, .spades), card(.five, .spades), card(.nine, .spades),
            card(.king, .spades), card(.ace, .hearts),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToFlush)
    }

    @Test func fourToFlushUserExample() {
        // K♠ T♠ Q♠ 8♠: player's suboptimal hold (8 breaks royal set)
        let hand = [
            card(.king, .spades), card(.ten, .spades), card(.three, .clubs),
            card(.queen, .spades), card(.eight, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 3, 4]) == .fourToFlush)
    }

    // MARK: - Four to Outside Straight

    @Test func fourToOutsideStraightConsecutive() {
        let hand = [
            card(.five, .spades), card(.six, .hearts), card(.seven, .diamonds),
            card(.eight, .clubs), card(.ace, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToOutsideStraight)
    }

    @Test func fourToInsideStraightBroadway() {
        // J-Q-K-A: only a 10 completes, so one-ended (inside).
        let hand = [
            card(.jack, .spades), card(.queen, .hearts), card(.king, .diamonds),
            card(.ace, .clubs), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToInsideStraight)
    }

    @Test func fourToInsideStraightWheel() {
        // A-2-3-4: only a 5 completes (ace-low wheel), so one-ended (inside).
        let hand = [
            card(.ace, .spades), card(.two, .hearts), card(.three, .diamonds),
            card(.four, .clubs), card(.king, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToInsideStraight)
    }

    // MARK: - Four to Inside Straight

    @Test func testFourToInsideStraight() {
        let hand = [
            card(.five, .spades), card(.six, .hearts), card(.eight, .diamonds),
            card(.nine, .clubs), card(.ace, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToInsideStraight)
    }

    @Test func fourToInsideStraightHighCards() {
        let hand = [
            card(.ten, .spades), card(.jack, .hearts), card(.queen, .diamonds),
            card(.ace, .clubs), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToInsideStraight)
    }

    // MARK: - Pat hands (five cards held)

    @Test func patRoyalFlush() {
        let hand = [
            card(.ace, .spades), card(.king, .spades), card(.queen, .spades),
            card(.jack, .spades), card(.ten, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3, 4]) == .royalFlush)
    }

    @Test func patStraightFlush() {
        let hand = [
            card(.nine, .hearts), card(.eight, .hearts), card(.seven, .hearts),
            card(.six, .hearts), card(.five, .hearts),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3, 4]) == .straightFlush)
    }

    @Test func patFourOfAKind() {
        let hand = [
            card(.king, .spades), card(.king, .hearts), card(.king, .diamonds),
            card(.king, .clubs), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3, 4]) == .fourOfAKind)
    }

    @Test func patFullHouse() {
        let hand = [
            card(.ace, .spades), card(.ace, .hearts), card(.ace, .diamonds),
            card(.king, .clubs), card(.king, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3, 4]) == .fullHouse)
    }

    @Test func patFlush() {
        let hand = [
            card(.ace, .clubs), card(.nine, .clubs), card(.seven, .clubs),
            card(.five, .clubs), card(.two, .clubs),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3, 4]) == .flush)
    }

    @Test func patStraight() {
        let hand = [
            card(.nine, .spades), card(.eight, .hearts), card(.seven, .clubs),
            card(.six, .diamonds), card(.five, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3, 4]) == .straight)
    }

    @Test func patThreeOfAKind() {
        let hand = [
            card(.eight, .spades), card(.eight, .hearts), card(.eight, .clubs),
            card(.king, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3, 4]) == .threeOfAKind)
    }

    @Test func patTwoPair() {
        let hand = [
            card(.ace, .spades), card(.ace, .hearts), card(.king, .clubs),
            card(.king, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3, 4]) == .twoPair)
    }

    @Test func patHighPair() {
        let hand = [
            card(.king, .spades), card(.king, .hearts), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .hearts),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3, 4]) == .highPair)
    }

    @Test func patLowPair() {
        let hand = [
            card(.nine, .spades), card(.nine, .hearts), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .hearts),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3, 4]) == .lowPair)
    }
}

@Suite("HoldClassifier: priority edge cases")
struct HoldClassifierPriorityTests {
    private func card(_ rank: Rank, _ suit: Suit) -> PlayingCard {
        PlayingCard(rank: rank, suit: suit)
    }

    private func classify(hand: [PlayingCard], holding: Set<Int>) -> StrategyPattern {
        HoldClassifier.classify(hand: hand, holding: holding)
    }

    /// Four suited high cards → four to royal (not four-to-flush or four-to-SF)
    @Test func fourHighSuitedBeatsFlush() {
        let hand = [
            card(.ace, .clubs), card(.king, .clubs), card(.queen, .clubs),
            card(.ten, .clubs), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToRoyalFlush)
    }

    /// Four suited consecutive non-high → four to SF (not four to flush)
    @Test func fourConsecutiveSuitedBeatsBareFlush() {
        let hand = [
            card(.four, .diamonds), card(.five, .diamonds), card(.six, .diamonds),
            card(.seven, .diamonds), card(.ace, .clubs),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToStraightFlush)
    }

    /// Three suited high cards → three to royal (not three to SF)
    @Test func threeHighSuitedBeatsThreeToSF() {
        let hand = [
            card(.ace, .hearts), card(.queen, .hearts), card(.ten, .hearts),
            card(.three, .clubs), card(.seven, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2]) == .threeToRoyalFlush)
    }

    /// Two suited high cards preferred over unsuited when same suit
    @Test func suitedHighCardsBeatUnsuited() {
        let suited = [
            card(.ace, .spades), card(.king, .spades), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .hearts),
        ]
        #expect(classify(hand: suited, holding: [0, 1]) == .twoSuitedHighCards)
        let unsuited = [
            card(.ace, .spades), card(.king, .hearts), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .clubs),
        ]
        #expect(classify(hand: unsuited, holding: [0, 1]) == .twoUnsuitedHighCards)
    }

    /// Suited T + high card: ten is not high (< J) but pattern takes priority
    @Test func suitedTenHighCardOverUnsuitedHigh() {
        let hand = [
            card(.ten, .clubs), card(.king, .clubs), card(.three, .spades),
            card(.seven, .hearts), card(.two, .diamonds),
        ]
        #expect(classify(hand: hand, holding: [0, 1]) == .suitedTenHighCard)
    }

    /// Three-card hold with embedded pair: pair pattern wins
    @Test func threeCardHoldPairWins() {
        let hand = [
            card(.jack, .spades), card(.jack, .hearts), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2]) == .highPair)
    }

    @Test func threeCardHoldLowPairWins() {
        let hand = [
            card(.five, .spades), card(.five, .hearts), card(.king, .clubs),
            card(.seven, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2]) == .lowPair)
    }

    /// Four-to-royal beats four-to-straight-flush when all high suited
    @Test func fourToRoyalBeats4ToSF() {
        let hand = [
            card(.ten, .diamonds), card(.jack, .diamonds), card(.queen, .diamonds),
            card(.king, .diamonds), card(.nine, .hearts),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToRoyalFlush)
    }

    // MARK: - Three to flush (three suited, non-royal, non-SF)

    /// Three suited cards spanning > 4 with one high card → threeToFlush.
    /// Previously mislabeled as oneHighCard due to suit info being discarded.
    @Test func threeSuitedNonSFDrawWithHighCard() {
        // 2♣ 9♣ K♣: span 11, not a SF draw; all clubs → threeToFlush
        let hand = [
            card(.two, .clubs), card(.nine, .clubs), card(.king, .clubs),
            card(.three, .hearts), card(.seven, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2]) == .threeToFlush)
    }

    @Test func threeSuitedNonSFDrawNoHighCard() {
        // 2♣ 5♣ 9♣: span 7, not a SF draw, no high cards → threeToFlush
        let hand = [
            card(.two, .clubs), card(.five, .clubs), card(.nine, .clubs),
            card(.king, .hearts), card(.seven, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2]) == .threeToFlush)
    }

    // MARK: - canFormStraightFlush wheel fix (Thread 2)

    /// A-2-4-5 suited is a valid wheel SF draw (can complete to A-2-3-4-5).
    @Test func fourToStraightFlushWheelWithGap() {
        let hand = [
            card(.ace, .hearts), card(.two, .hearts), card(.four, .hearts),
            card(.five, .hearts), card(.king, .clubs),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .fourToStraightFlush)
    }

    /// A-2-5 suited (3 cards) is a valid wheel SF draw.
    @Test func threeToStraightFlushWheelWithGap() {
        let hand = [
            card(.ace, .spades), card(.two, .spades), card(.five, .spades),
            card(.king, .hearts), card(.nine, .clubs),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2]) == .threeToStraightFlush)
    }

    // MARK: - classifyFour duplicate-ranks fix (Thread 3)

    /// Holding 4 cards that include a high pair must return .highPair, not .lowPair.
    @Test func fourCardHoldHighPair() {
        // J♠ J♥ 3♣ 7♦ held as 4 cards
        let hand = [
            card(.jack, .spades), card(.jack, .hearts), card(.three, .clubs),
            card(.seven, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .highPair)
    }

    /// Holding 4 cards with trips must return .threeOfAKind, not .lowPair.
    @Test func fourCardHoldTrips() {
        // 7♠ 7♥ 7♣ K♦ held as 4 cards
        let hand = [
            card(.seven, .spades), card(.seven, .hearts), card(.seven, .clubs),
            card(.king, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .threeOfAKind)
    }

    /// Two-pair 4-card hold: J-J-3-3 must deterministically return .highPair.
    @Test func fourCardHoldTwoPairHighWins() {
        let hand = [
            card(.jack, .spades), card(.jack, .hearts), card(.three, .clubs),
            card(.three, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .highPair)
    }

    /// Two-pair 4-card hold with both low pairs returns .lowPair.
    @Test func fourCardHoldTwoPairBothLow() {
        let hand = [
            card(.five, .spades), card(.five, .hearts), card(.three, .clubs),
            card(.three, .diamonds), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .lowPair)
    }

    // MARK: - classifyFour zero-high-cards fix (Thread 4)

    /// Four mixed-suit low cards with no straight draw should be .discardAll.
    @Test func fourMixedLowNoDrawIsDiscardAll() {
        // 2♠ 4♥ 8♦ 9♣: span 7, no straight draw, no high cards
        let hand = [
            card(.two, .spades), card(.four, .hearts), card(.eight, .diamonds),
            card(.nine, .clubs), card(.king, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .discardAll)
    }

    /// Four mixed-suit cards with exactly one high card returns .oneHighCard.
    @Test func fourMixedOneHighCardReturnsOneHighCard() {
        // 5♠ 6♥ 9♦ K♣: no straight draw, one high card
        let hand = [
            card(.five, .spades), card(.six, .hearts), card(.nine, .diamonds),
            card(.king, .clubs), card(.two, .spades),
        ]
        #expect(classify(hand: hand, holding: [0, 1, 2, 3]) == .oneHighCard)
    }
}
