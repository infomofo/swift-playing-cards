import Foundation

/// The video-poker-specific result of a 5-card hand under a Jacks or Better pay table.
///
/// Differs from `HandType` in two ways: a non-qualifying pair (lower than Jacks) maps to
/// `.noWin`, and `.highCard` is also `.noWin`. All other hand types map one-to-one.
public enum HandResult: Int, CaseIterable, Comparable, CustomStringConvertible {
    case noWin = 0
    case jacksOrBetter = 1
    case twoPair = 2
    case threeOfAKind = 3
    case straight = 4
    case flush = 5
    case fullHouse = 6
    case fourOfAKind = 7
    case straightFlush = 8
    case royalFlush = 9

    public static func < (lhs: HandResult, rhs: HandResult) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        switch self {
        case .noWin: "No Win"
        case .jacksOrBetter: "Jacks or Better"
        case .twoPair: "Two Pair"
        case .threeOfAKind: "Three of a Kind"
        case .straight: "Straight"
        case .flush: "Flush"
        case .fullHouse: "Full House"
        case .fourOfAKind: "Four of a Kind"
        case .straightFlush: "Straight Flush"
        case .royalFlush: "Royal Flush"
        }
    }

    /// True when the hand pays out at least 1x.
    public var isWin: Bool {
        self != .noWin
    }

    /// Classifies a 5-card hand into its video poker result.
    ///
    /// Returns `.noWin` for incomplete hands, non-qualifying pairs, and high-card hands.
    public static func evaluate(cards: [PlayingCard]) -> HandResult {
        guard cards.count == 5 else { return .noWin }
        switch Hand(cards: cards).evaluate() {
        case .royalFlush: return .royalFlush
        case .straightFlush: return .straightFlush
        case .fourOfAKind: return .fourOfAKind
        case .fullHouse: return .fullHouse
        case .flush: return .flush
        case .straight: return .straight
        case .threeOfAKind: return .threeOfAKind
        case .twoPair: return .twoPair
        case .pair:
            // Zero-allocation search for the pair rank. Since we know the hand contains
            // exactly one pair, we can find the pair rank using simple loops over the cards.
            var pairRank: Rank?
            let cardCount = cards.count
            for index1 in 0 ..< cardCount - 1 {
                let rank1 = cards[index1].rank
                for index2 in (index1 + 1) ..< cardCount {
                    if rank1 == cards[index2].rank {
                        pairRank = rank1
                        break
                    }
                }
                if pairRank != nil {
                    break
                }
            }
            if let pairRank, pairRank >= .jack {
                return .jacksOrBetter
            }
            return .noWin
        case .highCard:
            return .noWin
        }
    }
}

/// A video poker pay table mapping hand results to coin multipliers.
public struct PayTable {
    /// Human-readable name, e.g. "Jacks or Better (9/6)".
    public let name: String

    private let multipliers: [HandResult: Int]

    public init(name: String, multipliers: [HandResult: Int]) {
        self.name = name
        self.multipliers = multipliers
    }

    /// The payout multiplier for a given hand result.
    ///
    /// For royal flush, this returns the max-bet (5-coin) rate of 800. Use `payout(for:bet:)`
    /// when bet size varies, as it applies the correct 250x rate for bets 1-4.
    public func multiplier(for result: HandResult) -> Int {
        multipliers[result] ?? 0
    }

    /// Evaluates the cards and returns their `HandResult`.
    public func handResult(for cards: [PlayingCard]) -> HandResult {
        HandResult.evaluate(cards: cards)
    }

    /// Total coins returned for the given bet. `bet` must be 1-5.
    ///
    /// Royal flush pays 800x at bet=5 (4000 total) and 250x at bet 1-4.
    public func payout(for cards: [PlayingCard], bet: Int = 5) -> Int {
        precondition((1 ... 5).contains(bet), "bet must be between 1 and 5")
        let result = handResult(for: cards)
        if result == .royalFlush, bet != 5 {
            return 250 * bet
        }
        return multiplier(for: result) * bet
    }

    /// Net coins won or lost: `payout - bet`. `bet` must be 1-5.
    public func netPayout(for cards: [PlayingCard], bet: Int = 5) -> Int {
        precondition((1 ... 5).contains(bet), "bet must be between 1 and 5")
        return payout(for: cards, bet: bet) - bet
    }

    /// Full-pay 9/6 Jacks or Better. Returns 99.54% with optimal play.
    public static let jacksOrBetter96 = PayTable(
        name: "Jacks or Better (9/6)",
        multipliers: [
            .royalFlush: 800,
            .straightFlush: 50,
            .fourOfAKind: 25,
            .fullHouse: 9,
            .flush: 6,
            .straight: 4,
            .threeOfAKind: 3,
            .twoPair: 2,
            .jacksOrBetter: 1,
            .noWin: 0,
        ],
    )
}
