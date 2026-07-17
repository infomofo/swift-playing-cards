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
            let pairRank = cards.first(where: { card in cards.filter { $0.rank == card.rank }.count == 2 })!.rank
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
}
