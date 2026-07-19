/// Names the strategic intent of a hold combination in Jacks or Better video poker.
///
/// Cases are listed in descending priority order matching the standard Jacks or Better
/// strategy hierarchy. When the classifier detects multiple matching patterns, it returns
/// the highest-priority one.
public enum StrategyPattern: String, Equatable, CaseIterable, Sendable {
    // MARK: - Pat hands (all 5 cards held)

    /// Suited A-K-Q-J-T.
    case royalFlush = "Royal flush"
    /// Suited straight (not royal).
    case straightFlush = "Straight flush"
    /// Four cards of the same rank.
    case fourOfAKind = "Four of a kind"
    /// Three of a kind plus a pair.
    case fullHouse = "Full house"
    /// Five cards of the same suit (not straight).
    case flush = "Flush"
    /// Five consecutive ranks (not suited).
    case straight = "Straight"
    /// Three cards of the same rank (held as 3 or held pat).
    case threeOfAKind = "Three of a kind"
    /// Two separate pairs (all 5 held).
    case twoPair = "Two pair"

    // MARK: - Partial holds

    /// Four suited cards all within {T, J, Q, K, A}.
    case fourToRoyalFlush = "Four to a royal flush"
    /// A pair of jacks, queens, kings, or aces.
    case highPair = "High pair"
    /// Three suited cards all within {T, J, Q, K, A}.
    case threeToRoyalFlush = "Three to a royal flush"
    /// Four suited cards that can complete to a straight flush.
    case fourToStraightFlush = "Four to a straight flush"
    /// Four suited cards that are not all royal-eligible.
    case fourToFlush = "Four to a flush"
    /// Mixed-suit T-J-Q-K: the only 4-card outside straight with 3 high cards.
    ///
    /// EV 0.87 — ranks above a low pair (EV 0.82). WoO optimal entry #14.
    case unsuitedTJQK = "Unsuited T-J-Q-K"
    /// A pair of twos through tens.
    case lowPair = "Low pair"
    /// Four consecutive cards that can be completed on either end (0–2 high cards).
    ///
    /// EV ~0.68 — ranks below a low pair. For T-J-Q-K specifically, see ``unsuitedTJQK``.
    case fourToOutsideStraight = "Four to an outside straight"
    /// Four cards to a straight with one internal gap.
    case fourToInsideStraight = "Four to an inside straight"
    /// Three suited cards forming a straight flush draw, type 1: high cards (J+) ≥ gaps.
    ///
    /// Examples: 9-T-J suited (0 gaps, 1 high), 8-J-Q suited (2 gaps, 2 high). EV ~0.63.
    /// Ranks above suited QJ on the WoO optimal list.
    case threeToStraightFlushType1 = "Three to a straight flush (type 1)"
    /// Three suited cards forming a straight flush draw, type 2.
    ///
    /// Covers: 1 gap + 0 high cards; 2 gaps + 1 high card; ace-low suited; 2-3-4 suited.
    /// Examples: 6-8-9 suited, A-2-4 suited, 2-3-4 suited. EV ~0.52.
    case threeToStraightFlushType2 = "Three to a straight flush (type 2)"
    /// Three suited cards forming a straight flush draw, type 3: 2 gaps, no high cards.
    ///
    /// Examples: 3-5-7 suited, 4-6-8 suited. EV 0.44 — weaker than holding a single high card.
    case threeToStraightFlushType3 = "Three to a straight flush (type 3)"
    /// Three suited cards not forming a royal or straight flush draw.
    case threeToFlush = "Three to a flush"
    /// Three mixed-suit cards all within {T, J, Q, K, A}, no pair.
    case threeUnsuitedHighCards = "Three unsuited high cards"
    /// Two suited cards both ranking jack or higher.
    case twoSuitedHighCards = "Two suited high cards"
    /// Two unsuited cards both ranking jack or higher.
    case twoUnsuitedHighCards = "Two unsuited high cards"
    /// A ten and a high card (J–A) of the same suit.
    case suitedTenHighCard = "Suited 10 with high card"
    /// A single jack, queen, king, or ace.
    case oneHighCard = "One high card"
    /// No cards held.
    case discardAll = "Discard all"

    // MARK: - Deuces Wild patterns

    /// All four deuces held — already the second-highest winning hand.
    case fourDeuces = "Four deuces"
    /// Three deuces + two natural royals of the same suit forming a wild royal flush.
    case patWildRoyalFlush = "Pat wild royal flush"
    /// Three deuces held; no pat royal flush possible.
    case threeDeuces = "Three deuces"
    /// Two deuces + a pat hand (four of a kind or better, including wild royal or five of a kind).
    case patHandTwoDeuces = "Pat hand (two deuces)"
    /// Two deuces + four cards to a royal flush (deuce fills the fifth royal slot).
    case fourToRoyalFlushTwoDeuces = "Four to a royal flush (two deuces)"
    /// Two deuces + three consecutive naturals 6 or higher forming a straight-flush draw.
    case fourToStraightFlushTwoDeuces = "Four to a straight flush (two deuces)"
    /// Two deuces only — hold the pair of deuces and draw three.
    case twoDeuces = "Two deuces"
    /// One deuce + a pat hand (four of a kind or better).
    case patHandOneDeuce = "Pat hand (one deuce)"
    /// One deuce + four naturals completing a royal flush draw.
    case fourToRoyalFlushOneDeuce = "Four to a royal flush (one deuce)"
    /// One deuce + a pat full house.
    case patFullHouseOneDeuce = "Pat full house (one deuce)"
    /// One deuce + three consecutive naturals ranked 5 or higher, forming a high SF draw.
    case fourToStraightFlushHighOneDeuce = "Four to a straight flush, 3 consecutive 5+ (one deuce)"
    /// One deuce + a pat three of a kind, straight, or flush.
    case patLowHandOneDeuce = "Pat three of a kind, straight, or flush (one deuce)"
    /// One deuce + four cards to any other straight flush draw.
    case fourToStraightFlushOneDeuce = "Four to a straight flush (one deuce)"
    /// One deuce + three naturals to a royal flush.
    case threeToRoyalFlushOneDeuce = "Three to a royal flush (one deuce)"
    /// One deuce + two consecutive naturals ranked 6 or higher forming a SF draw.
    case threeToStraightFlushHighOneDeuce = "Three to a straight flush, 2 consecutive 6+ (one deuce)"
    /// One deuce only — hold only the deuce and draw four.
    case oneDeuce = "One deuce"
    /// Any pair (no distinction between high/low in Deuces Wild; pairs don't pay).
    case pair = "Pair"
    /// Two suited cards both J or higher (Deuces Wild 0-deuce position 10).
    case twoToRoyalFlushJQHigh = "Two to a royal flush (J/Q high)"
}

// MARK: - HoldClassifier

/// Classifies a hold combination by its Jacks or Better strategy pattern.
///
/// ## Usage
///
/// ```swift
/// let pattern = HoldClassifier.classify(hand: dealtCards, holding: [0, 2, 4])
/// print(pattern.rawValue) // e.g. "Three to a royal flush"
/// ```
// swiftlint:disable:next type_body_length
public struct HoldClassifier {
    private init() {}

    /// Returns the highest-priority strategy pattern for the given hold set.
    ///
    /// When the held cards match multiple patterns (e.g. four suited high cards
    /// is both four-to-royal and four-to-flush), the higher-priority pattern wins.
    ///
    /// - Parameters:
    ///   - hand: Exactly 5 dealt cards.
    ///   - holding: Indices (0–4) the player chose to hold.
    public static func classify(hand: [PlayingCard], holding: Set<Int>) -> StrategyPattern {
        precondition(hand.count == 5, "HoldClassifier requires exactly 5 dealt cards")
        precondition(
            holding.allSatisfy { (0 ..< 5).contains($0) },
            "holding indices must be in 0...4",
        )

        let held = holding.sorted().map { hand[$0] }

        switch held.count {
        case 0:
            return .discardAll
        case 1:
            return classifyOne(held[0])
        case 2:
            return classifyTwo(held[0], held[1])
        case 3:
            return classifyThree(held)
        case 4:
            return classifyFour(held)
        case 5:
            return classifyFive(held)
        default:
            preconditionFailure("holding set cannot have more than 5 elements")
        }
    }

    // MARK: - Five cards

    private static func classifyFive(_ cards: [PlayingCard]) -> StrategyPattern {
        switch Hand(cards: cards).evaluate() {
        case .royalFlush:
            return .royalFlush
        case .straightFlush:
            return .straightFlush
        case .fourOfAKind:
            return .fourOfAKind
        case .fullHouse:
            return .fullHouse
        case .flush:
            return .flush
        case .straight:
            return .straight
        case .threeOfAKind:
            return .threeOfAKind
        case .twoPair:
            return .twoPair
        case .pair:
            // Zero-allocation search for the pair rank to avoid O(N^2) filter in loop.
            var pairRank = Rank.two
            let cardCount = cards.count
            for index1 in 0 ..< cardCount - 1 {
                let rank1 = cards[index1].rank
                var found = false
                for index2 in (index1 + 1) ..< cardCount {
                    if rank1 == cards[index2].rank {
                        pairRank = rank1
                        found = true
                        break
                    }
                }
                if found {
                    break
                }
            }
            return pairRank.rawValue >= 11 ? .highPair : .lowPair
        case .highCard:
            // Unusual to hold all 5 with no pair; return best single-card pattern.
            if let highCard = cards.max(by: { $0.rank < $1.rank }), highCard.rank.rawValue >= 11 {
                return .oneHighCard
            }
            return .discardAll
        }
    }

    // MARK: - Four cards

    private static func classifyFour(_ cards: [PlayingCard]) -> StrategyPattern {
        let suits = cards.map(\.suit)
        let ranks = cards.map(\.rank.rawValue)
        let allSameSuit = Set(suits).count == 1

        if allSameSuit {
            // All 4 in royal set {T, J, Q, K, A} (rawValues 10–14)?
            if ranks.allSatisfy({ $0 >= 10 }) {
                return .fourToRoyalFlush
            }
            // Can form a straight flush: all unique ranks, span <= 4 (or wheel)?
            if canFormStraightFlush(ranks) {
                return .fourToStraightFlush
            }
            return .fourToFlush
        }

        // Mixed suits: look for straight draws.
        let sorted = ranks.sorted()
        guard Set(ranks).count == 4 else {
            let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues { $0.count }
            if rankCounts.values.contains(4) {
                return .fourOfAKind
            }
            if rankCounts.values.contains(3) {
                return .threeOfAKind
            }
            let pairRanks = rankCounts.filter { $0.value == 2 }.map(\.key)
            if !pairRanks.isEmpty {
                return pairRanks.max()! >= 11 ? .highPair : .lowPair
            }
            preconditionFailure("4-card hold has duplicates but no pair, trips, or quads: impossible rank distribution")
        }

        // Open-ended: 4 consecutive ranks completable on both ends (span == 3, ace not high).
        if isOutsideStraightDraw(sorted) {
            // TJQK is the only outside straight with 3 high cards (EV 0.87, above low pair).
            // All other outside straights have 0–2 high cards (EV ~0.68, below low pair).
            if sorted == [10, 11, 12, 13] {
                return .unsuitedTJQK
            }
            return .fourToOutsideStraight
        }
        // Inside: span == 4 with exactly one internal gap.
        if isInsideStraightDraw(sorted) {
            return .fourToInsideStraight
        }
        // Mixed suits with no straight draw: classify by high card count.
        let highCount = ranks.filter { $0 >= 11 }.count
        if highCount >= 2 {
            return .twoUnsuitedHighCards
        }
        if highCount == 1 {
            return .oneHighCard
        }
        return .discardAll
    }

    // MARK: - Three cards

    private static func classifyThree(_ cards: [PlayingCard]) -> StrategyPattern {
        let ranks = cards.map(\.rank.rawValue)
        let suits = cards.map(\.suit)

        // Three of a kind?
        if Set(ranks).count == 1 {
            return .threeOfAKind
        }

        let allSameSuit = Set(suits).count == 1

        if allSameSuit {
            // All in royal set {T, J, Q, K, A}?
            if ranks.allSatisfy({ $0 >= 10 }) {
                return .threeToRoyalFlush
            }
            // Straight flush draw: classify into WoO type (determines EV tier).
            if canFormStraightFlush(ranks) {
                return classifyThreeToSFType(ranks: ranks)
            }
            // Three suited cards that don't qualify as royal or SF draw.
            return .threeToFlush
        }

        // Mixed suits: check for pairs (two cards of same rank with a third).
        let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues { $0.count }
        if let pairRank = rankCounts.first(where: { $0.value == 2 })?.key {
            return pairRank >= 11 ? .highPair : .lowPair
        }

        // Three different ranks, mixed suits: look for high cards.
        let highRanks = ranks.filter { $0 >= 11 }
        // All three in royal set {T, J, Q, K, A}: three unsuited high cards.
        if ranks.allSatisfy({ $0 >= 10 }) {
            return .threeUnsuitedHighCards
        }
        switch highRanks.count {
        case 2: return .twoUnsuitedHighCards
        case 1: return .oneHighCard
        default: return .discardAll
        }
    }

    // MARK: - Two cards

    private static func classifyTwo(_ first: PlayingCard, _ second: PlayingCard) -> StrategyPattern {
        // Pair?
        if first.rank == second.rank {
            return first.rank.rawValue >= 11 ? .highPair : .lowPair
        }

        let firstVal = first.rank.rawValue
        let secondVal = second.rank.rawValue
        let firstHigh = firstVal >= 11
        let secondHigh = secondVal >= 11
        let firstTen = first.rank == .ten
        let secondTen = second.rank == .ten
        let sameSuit = first.suit == second.suit

        if sameSuit {
            if firstHigh && secondHigh {
                return .twoSuitedHighCards
            }
            if (firstTen && secondHigh) || (firstHigh && secondTen) {
                return .suitedTenHighCard
            }
        } else {
            if firstHigh, secondHigh {
                return .twoUnsuitedHighCards
            }
        }

        if firstHigh || secondHigh {
            return .oneHighCard
        }

        return .discardAll
    }

    // MARK: - One card

    private static func classifyOne(_ card: PlayingCard) -> StrategyPattern {
        card.rank.rawValue >= 11 ? .oneHighCard : .discardAll
    }

    // MARK: - Helpers

    /// Classifies a 3-card suited straight flush draw into WoO types 1, 2, or 3.
    ///
    /// Called only when `canFormStraightFlush` already returned true.
    ///
    /// - Type 1: high cards (J+) ≥ gaps. EV ~0.63. Ranks above suited QJ.
    /// - Type 2: 1 gap + 0 high; 2 gaps + 1 high; ace-low; 2-3-4. EV ~0.52.
    /// - Type 3: 2 gaps + 0 high cards. EV 0.44 — weaker than holding a lone high card.
    private static func classifyThreeToSFType(ranks: [Int]) -> StrategyPattern {
        let sorted = ranks.sorted()
        let highCards = sorted.filter { $0 >= 11 }.count

        // Ace-low: ace + two low cards (all ≤ 5) — wheel-direction draw, always type 2.
        if sorted.contains(14) {
            let nonAce = sorted.filter { $0 != 14 }
            if nonAce.allSatisfy({ $0 <= 5 }) {
                return .threeToStraightFlushType2
            }
        }

        // 2-3-4: explicitly type 2 per WoO (limited completion paths, similar to ace-low).
        if sorted == [2, 3, 4] {
            return .threeToStraightFlushType2
        }

        // Number of interior gaps: for 3 cards, gapCount = span - 2.
        let span = sorted.last! - sorted.first!
        let gapCount = span - 2

        if highCards >= gapCount {
            return .threeToStraightFlushType1
        }
        if gapCount == 2, highCards == 0 {
            return .threeToStraightFlushType3
        }
        return .threeToStraightFlushType2
    }

    /// Returns true when 3 or 4 ranks (as rawValues) can form a straight flush.
    ///
    /// Criteria: all unique, span (max - min) <= 4, OR ace-low wheel.
    private static func canFormStraightFlush(_ ranks: [Int]) -> Bool {
        let sorted = ranks.sorted()
        guard Set(ranks).count == ranks.count else { return false }
        let span = sorted.last! - sorted.first!
        if span <= 4 {
            return true
        }
        // Wheel: ace (14) + two/three/four/five
        let hasAce = sorted.contains(14)
        let lowRanks = sorted.filter { $0 != 14 }
        if hasAce, lowRanks.allSatisfy({ $0 <= 5 }) {
            return true
        }
        return false
    }

    /// Open-ended straight draw: 4 unique consecutive ranks completable on both ends.
    ///
    /// Excludes ace-high sequences (J-Q-K-A) and ace-low wheel sequences (A-2-3-4)
    /// because both are one-ended and are classified as inside draws instead.
    private static func isOutsideStraightDraw(_ sorted: [Int]) -> Bool {
        guard sorted.count == 4, Set(sorted).count == 4 else { return false }
        // Standard consecutive, excluding ace-high (J-Q-K-A can only complete with 10).
        if sorted[3] - sorted[0] == 3, sorted[3] != 14 {
            return true
        }
        return false
    }

    /// Inside (gutshot) straight draw: 4 unique ranks spanning 4 with exactly one gap,
    /// plus one-ended boundary draws (A-2-3-4 and J-Q-K-A).
    private static func isInsideStraightDraw(_ sorted: [Int]) -> Bool {
        guard sorted.count == 4, Set(sorted).count == 4 else { return false }
        // A-2-3-4: wheel one-ender (only 5 completes).
        if sorted == [2, 3, 4, 14] {
            return true
        }
        // J-Q-K-A: broadway one-ender (only 10 completes).
        if sorted == [11, 12, 13, 14] {
            return true
        }
        let span = sorted[3] - sorted[0]
        guard span == 4 else { return false }
        // Exactly 2 consecutive pairs means one gap exists.
        var consecutivePairs = 0
        for idx in 0 ..< 3 where sorted[idx + 1] - sorted[idx] == 1 {
            consecutivePairs += 1
        }
        return consecutivePairs == 2
    }

    // MARK: - Deuces Wild classification

    /// Returns the highest-priority Deuces Wild strategy pattern for the given hold set.
    ///
    /// All 2s (deuces) in the held cards are treated as wild. The pattern reflects
    /// the WoO simple-strategy hierarchy, broken into sections by deuce count.
    ///
    /// - Parameters:
    ///   - hand: Exactly 5 dealt cards.
    ///   - holding: Indices (0–4) the player chose to hold.
    public static func classifyDeucesWild(hand: [PlayingCard], holding: Set<Int>) -> StrategyPattern {
        precondition(hand.count == 5, "HoldClassifier requires exactly 5 dealt cards")
        precondition(
            holding.allSatisfy { (0 ..< 5).contains($0) },
            "holding indices must be in 0...4",
        )

        let held = holding.sorted().map { hand[$0] }
        let deuces = held.filter { $0.rank == .two }
        let naturals = held.filter { $0.rank != .two }
        let deuceCount = deuces.count

        switch deuceCount {
        case 4: return .fourDeuces
        case 3: return classifyDW3Deuces(naturals: naturals)
        case 2: return classifyDW2Deuces(naturals: naturals, allHeld: held)
        case 1: return classifyDW1Deuce(naturals: naturals, allHeld: held)
        default: return classifyDW0Deuces(held: held)
        }
    }

    // MARK: 3 deuces

    private static func classifyDW3Deuces(naturals: [PlayingCard]) -> StrategyPattern {
        guard naturals.count == 2 else { return .threeDeuces }
        let ranks = naturals.map(\.rank.rawValue)
        let suits = naturals.map(\.suit)
        // Pat wild royal: both naturals are distinct royal cards (T–A) of the same suit.
        if ranks.allSatisfy({ $0 >= 10 }), Set(ranks).count == 2, suits[0] == suits[1] {
            return .patWildRoyalFlush
        }
        return .threeDeuces
    }

    // MARK: 2 deuces

    private static func classifyDW2Deuces(naturals: [PlayingCard], allHeld: [PlayingCard]) -> StrategyPattern {
        // Pat hand (4+ cards held = 2 deuces + 3 naturals evaluates as 5-card hand).
        if allHeld.count == 5 {
            let result = HandResult.evaluate(cards: allHeld, wildcardRank: .two)
            if result >= .fourOfAKind {
                return .patHandTwoDeuces
            }
        }
        // Partial holds: 2 deuces + 1 natural = 3 held cards total.
        if naturals.count == 1 {
            let natural = naturals[0]
            // 4 to a royal: deuce + deuce + royal card = need 1 natural to be in {T–A}.
            // With 2 deuces + 1 royal natural, drawing 2 can complete a wild RF.
            if natural.rank.rawValue >= 10 {
                return .fourToRoyalFlushTwoDeuces
            }
        }
        // 2 deuces + 2 naturals.
        if naturals.count == 2 {
            let ranks = naturals.map(\.rank.rawValue).sorted()
            let suits = naturals.map(\.suit)
            // 4 to a royal flush: both naturals are distinct royal cards of same suit.
            if ranks.allSatisfy({ $0 >= 10 }), Set(ranks).count == 2, suits[0] == suits[1] {
                return .fourToRoyalFlushTwoDeuces
            }
            // 4 to a SF: same suit, distinct ranks, both ≥ 6 (rank value), span ≤ 4.
            if suits[0] == suits[1], Set(ranks).count == 2 {
                let span = ranks[1] - ranks[0]
                if span <= 4, ranks[0] >= 6 {
                    return .fourToStraightFlushTwoDeuces
                }
            }
        }
        return .twoDeuces
    }

    // MARK: 1 deuce

    private static func classifyDW1Deuce(naturals: [PlayingCard], allHeld: [PlayingCard]) -> StrategyPattern {
        // Pat hand (1 deuce + 4 naturals = 5 cards total).
        if allHeld.count == 5 {
            let result = HandResult.evaluate(cards: allHeld, wildcardRank: .two)
            switch result {
            case .fourDeuces, .wildRoyalFlush, .fiveOfAKind, .naturalRoyalFlush, .straightFlush,
                 .fourOfAKind:
                return .patHandOneDeuce
            case .fullHouse:
                return .patFullHouseOneDeuce
            case .flush, .straight, .threeOfAKind:
                return .patLowHandOneDeuce
            default:
                break
            }
        }

        // Partial holds with 1 deuce.
        // 4 to a royal: 1 deuce + 3 naturals all in {T–A} of same suit.
        if naturals.count == 3 {
            let ranks = naturals.map(\.rank.rawValue)
            let suits = naturals.map(\.suit)
            if ranks.allSatisfy({ $0 >= 10 }), Set(ranks).count == 3,
               suits.dropFirst().allSatisfy({ $0 == suits[0] })
            {
                return .fourToRoyalFlushOneDeuce
            }
            // 4 to a SF: all same suit, distinct, 3 consecutive naturals ranked 5+.
            if suits.dropFirst().allSatisfy({ $0 == suits[0] }), Set(ranks).count == 3 {
                let sorted = ranks.sorted()
                let span = sorted[2] - sorted[0]
                if span == 2, sorted[0] >= 5 { // consecutive (no gaps), rank value ≥ 5
                    return .fourToStraightFlushHighOneDeuce
                }
                // Other SF draws (span ≤ 4).
                if span <= 4 {
                    return .fourToStraightFlushOneDeuce
                }
            }
        }

        // 3 to a royal: 1 deuce + 2 naturals all in {T–A} of same suit.
        if naturals.count == 2 {
            let ranks = naturals.map(\.rank.rawValue)
            let suits = naturals.map(\.suit)
            if ranks.allSatisfy({ $0 >= 10 }), Set(ranks).count == 2, suits[0] == suits[1] {
                return .threeToRoyalFlushOneDeuce
            }
            // 3 to a SF: same suit, distinct, 2 consecutive naturals ranked 6+.
            if suits[0] == suits[1], Set(ranks).count == 2 {
                let sorted = ranks.sorted()
                let span = sorted[1] - sorted[0]
                if span == 1, sorted[0] >= 6 { // consecutive, rank value ≥ 6
                    return .threeToStraightFlushHighOneDeuce
                }
            }
        }

        return .oneDeuce
    }

    // MARK: 0 deuces

    private static func classifyDW0Deuces(held: [PlayingCard]) -> StrategyPattern {
        switch held.count {
        case 0:
            return .discardAll
        case 1:
            let rankValue = held[0].rank.rawValue
            return rankValue >= 11 ? .oneHighCard : .discardAll
        case 2:
            return classifyDW0Two(held[0], held[1])
        case 3:
            return classifyDW0Three(held)
        case 4:
            return classifyDW0Four(held)
        case 5:
            return classifyDW0Five(held)
        default:
            preconditionFailure("holding set cannot have more than 5 elements")
        }
    }

    private static func classifyDW0Five(_ cards: [PlayingCard]) -> StrategyPattern {
        // In DW, pat hands are evaluated without wilds (k=0 path).
        switch Hand(cards: cards).evaluate() {
        case .royalFlush: .royalFlush
        case .straightFlush: .straightFlush
        case .fourOfAKind: .fourOfAKind
        case .fullHouse: .fullHouse
        case .flush: .flush
        case .straight: .straight
        case .threeOfAKind: .threeOfAKind
        case .twoPair, .pair: .pair // two-pair treated as pair in DW
        case .highCard: .discardAll
        }
    }

    private static func classifyDW0Four(_ cards: [PlayingCard]) -> StrategyPattern {
        let suits = cards.map(\.suit)
        let ranks = cards.map(\.rank.rawValue)
        let allSameSuit = Set(suits).count == 1

        if allSameSuit {
            if ranks.allSatisfy({ $0 >= 10 }) {
                return .fourToRoyalFlush
            }
            if canFormStraightFlush(ranks) {
                return .fourToStraightFlush
            }
            return .fourToFlush
        }
        let sorted = ranks.sorted()
        guard Set(ranks).count == 4 else {
            // Duplicate ranks = pair.
            return .pair
        }
        if isOutsideStraightDraw(sorted) {
            return .fourToOutsideStraight
        }
        if isInsideStraightDraw(sorted) {
            return .fourToInsideStraight
        }
        return .discardAll
    }

    private static func classifyDW0Three(_ cards: [PlayingCard]) -> StrategyPattern {
        let ranks = cards.map(\.rank.rawValue)
        let suits = cards.map(\.suit)
        if Set(ranks).count == 1 {
            return .threeOfAKind
        }
        let allSameSuit = Set(suits).count == 1
        if allSameSuit {
            if ranks.allSatisfy({ $0 >= 10 }) {
                return .threeToRoyalFlush
            }
            if canFormStraightFlush(ranks) {
                return .threeToStraightFlushType1
            }
        }
        let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues { $0.count }
        if rankCounts.values.contains(2) {
            return .pair
        }
        return .discardAll
    }

    private static func classifyDW0Two(_ first: PlayingCard, _ second: PlayingCard) -> StrategyPattern {
        if first.rank == second.rank {
            return .pair
        }
        let fv = first.rank.rawValue, sv = second.rank.rawValue
        let sameSuit = first.suit == second.suit
        // 2 to a royal flush, J/Q high (highest-rank 2-card hold in DW).
        if sameSuit, fv >= 11, sv >= 11 {
            return .twoToRoyalFlushJQHigh
        }
        return .discardAll
    }
}
