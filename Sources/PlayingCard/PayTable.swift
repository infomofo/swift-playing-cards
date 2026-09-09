import Foundation

/// The video-poker-specific result of a 5-card hand.
///
/// Covers both Jacks or Better and Deuces Wild variants. For Jacks or Better, a
/// non-qualifying pair maps to `.noWin` and `.highCard` maps to `.noWin`. For Deuces
/// Wild, pairs and two-pair also map to `.noWin`; the minimum winning hand is
/// `.threeOfAKind`. Wild-card-specific hands (`.fiveOfAKind`, `.wildRoyalFlush`,
/// `.fourDeuces`, `.naturalRoyalFlush`) appear only in Deuces Wild evaluation.
///
/// Raw values define the ordering used by `Comparable` and by `OptimalPlay`'s
/// internal multiplier lookup. All cases are ordered weakest-to-strongest.
public enum HandResult: Int, CaseIterable, Comparable, CustomStringConvertible {
    // MARK: - Standard hands (rawValues 0–9, used in Jacks or Better and Deuces Wild)

    case noWin = 0
    case jacksOrBetter = 1
    case twoPair = 2
    case threeOfAKind = 3
    case straight = 4
    case flush = 5
    case fullHouse = 6
    case fourOfAKind = 7
    case straightFlush = 8
    /// A natural (no-wild) royal flush. Used by Jacks or Better pay tables.
    /// For Deuces Wild, use `.naturalRoyalFlush` (rawValue 13).
    case royalFlush = 9

    // MARK: - Deuces Wild additions (rawValues 10–13)

    /// Five cards of the same rank (requires at least one wild). Pays 15x in full-pay Deuces Wild.
    case fiveOfAKind = 10
    /// A royal flush made with at least one wild deuce. Pays 25x in full-pay Deuces Wild.
    case wildRoyalFlush = 11
    /// Four deuces in hand. Pays 200x in full-pay Deuces Wild.
    case fourDeuces = 12
    /// A natural royal flush (no wild deuces used). Pays 800x in full-pay Deuces Wild.
    case naturalRoyalFlush = 13

    public static func < (lhs: HandResult, rhs: HandResult) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        switch self {
        case .noWin: "No Winner"
        case .jacksOrBetter: "Jacks or Better"
        case .twoPair: "Two Pair"
        case .threeOfAKind: "Three of a Kind"
        case .straight: "Straight"
        case .flush: "Flush"
        case .fullHouse: "Full House"
        case .fourOfAKind: "Four of a Kind"
        case .straightFlush: "Straight Flush"
        case .royalFlush: "Royal Flush"
        case .fiveOfAKind: "Five of a Kind"
        case .wildRoyalFlush: "Wild Royal Flush"
        case .fourDeuces: "Four Deuces"
        case .naturalRoyalFlush: "Natural Royal Flush"
        }
    }

    /// True when the hand pays out at least 1x under any supported pay table.
    public var isWin: Bool {
        self != .noWin
    }

    /// The generic poker hand type corresponding to this video poker result.
    ///
    /// Returns nil for `.noWin` because the underlying hand type (pair, two-pair, high card)
    /// cannot be determined from the pay table result alone.
    ///
    /// This mapping is lossy for wild-only results that have no equivalent `HandType` case:
    /// `.fiveOfAKind` and `.fourDeuces` both map to `.fourOfAKind`, and `.wildRoyalFlush` /
    /// `.naturalRoyalFlush` both map to `.royalFlush`. Callers that need to distinguish these
    /// wild-enhanced hands from their standard counterparts should switch on `HandResult`
    /// directly instead of relying on `handType`.
    public var handType: HandType? {
        switch self {
        case .noWin: nil
        case .jacksOrBetter: .pair
        case .twoPair: .twoPair
        case .threeOfAKind: .threeOfAKind
        case .straight: .straight
        case .flush: .flush
        case .fullHouse: .fullHouse
        case .fourOfAKind, .fourDeuces: .fourOfAKind
        case .straightFlush: .straightFlush
        case .royalFlush, .wildRoyalFlush, .naturalRoyalFlush: .royalFlush
        case .fiveOfAKind: .fourOfAKind
        }
    }

    ///
    /// - Parameters:
    ///   - cards: Exactly 5 cards.
    ///   - wildcardRank: When non-nil, cards of this rank act as wild cards (Deuces Wild: `.two`).
    ///     Pass `nil` for Jacks or Better evaluation.
    ///
    /// For Jacks or Better (`wildcardRank == nil`): returns `.noWin` for incomplete hands,
    /// non-qualifying pairs, and high-card hands. Returns `.royalFlush` for a natural royal.
    ///
    /// For Deuces Wild (`wildcardRank == .two`): returns `.naturalRoyalFlush` for a natural royal,
    /// `.fourDeuces` / `.wildRoyalFlush` / `.fiveOfAKind` for wild-enhanced hands, and `.noWin`
    /// for pairs, two-pair, and high-card hands.
    /// ⚡ Bolt Optimization: Delegate 5-card evaluation to `FastHandEvaluator` using integer
    /// card encoding. This bypasses all array allocations, closures, and dictionary groupings.
    public static func evaluate(cards: [PlayingCard], wildcardRank: Rank? = nil) -> HandResult {
        guard cards.count == 5 else { return .noWin }
        precondition(
            wildcardRank == nil || wildcardRank == .two,
            "HandResult only supports wildcardRank == .two (Deuces Wild).",
        )

        @inline(__always)
        func suitIndex(_ suit: Suit) -> Int {
            switch suit {
            case .spades: 0
            case .hearts: 1
            case .diamonds: 2
            case .clubs: 3
            }
        }

        let c0 = ((cards[0].rank.rawValue - 2) << 2) | suitIndex(cards[0].suit)
        let c1 = ((cards[1].rank.rawValue - 2) << 2) | suitIndex(cards[1].suit)
        let c2 = ((cards[2].rank.rawValue - 2) << 2) | suitIndex(cards[2].suit)
        let c3 = ((cards[3].rank.rawValue - 2) << 2) | suitIndex(cards[3].suit)
        let c4 = ((cards[4].rank.rawValue - 2) << 2) | suitIndex(cards[4].suit)

        let rawCode = wildcardRank != nil
            ? FastHandEvaluator.deucesWildCode(c0, c1, c2, c3, c4)
            : FastHandEvaluator.standardCode(c0, c1, c2, c3, c4)

        return HandResult(rawValue: rawCode) ?? .noWin
    }
}

/// A video poker pay table mapping hand results to coin multipliers.
public struct PayTable {
    /// Human-readable name, e.g. "Jacks or Better (9/6)".
    public let name: String

    private let multipliers: [HandResult: Int]

    /// When non-nil, cards of this rank act as wild cards during hand evaluation.
    ///
    /// Set to `.two` for Deuces Wild pay tables. The `handResult(for:)` and related
    /// methods automatically pass this to `HandResult.evaluate(cards:wildcardRank:)`.
    public let wildcardRank: Rank?

    public init(name: String, multipliers: [HandResult: Int], wildcardRank: Rank? = nil) {
        self.name = name
        self.multipliers = multipliers
        self.wildcardRank = wildcardRank
    }

    /// The payout multiplier for a given hand result.
    ///
    /// For royal flush, this returns the max-bet (5-coin) rate of 800. Use `payout(for:bet:)`
    /// when bet size varies, as it applies the correct 250x rate for bets 1-4.
    public func multiplier(for result: HandResult) -> Int {
        multipliers[result] ?? 0
    }

    /// Evaluates the cards and returns their `HandResult`.
    ///
    /// Uses wildcard evaluation when `wildcardRank` is set.
    public func handResult(for cards: [PlayingCard]) -> HandResult {
        HandResult.evaluate(cards: cards, wildcardRank: wildcardRank)
    }

    /// Whether `card` acts as a wild card under this pay table.
    ///
    /// Always `false` for pay tables with no `wildcardRank` (e.g. Jacks or Better). For
    /// Deuces Wild, returns `true` for any card ranked `.two` regardless of suit.
    public func isWild(_ card: PlayingCard) -> Bool {
        wildcardRank == card.rank
    }

    /// Total coins returned for the given bet. `bet` must be 1-5.
    ///
    /// Royal flush (`.royalFlush` or `.naturalRoyalFlush`) pays 800x at bet=5 (4000 total)
    /// and 250x at bet 1-4.
    public func payout(for cards: [PlayingCard], bet: Int = 5) -> Int {
        precondition((1 ... 5).contains(bet), "bet must be between 1 and 5")
        let result = handResult(for: cards)
        if result == .royalFlush || result == .naturalRoyalFlush, bet != 5 {
            return 250 * bet
        }
        return multiplier(for: result) * bet
    }

    /// Net coins won or lost: `payout - bet`. `bet` must be 1-5.
    public func netPayout(for cards: [PlayingCard], bet: Int = 5) -> Int {
        precondition((1 ... 5).contains(bet), "bet must be between 1 and 5")
        return payout(for: cards, bet: bet) - bet
    }

    // MARK: - Static pay tables

    /// Full-pay 9/6 Jacks or Better. Returns 99.54% with optimal play.
    ///
    /// Named for the full house (9) and flush (6) payouts that define this variant.
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

    /// 9/5 Jacks or Better (flush pays 5 instead of 6). Returns 98.45% with optimal play.
    public static let jacksOrBetter95 = PayTable(
        name: "Jacks or Better (9/5)",
        multipliers: [
            .royalFlush: 800,
            .straightFlush: 50,
            .fourOfAKind: 25,
            .fullHouse: 9,
            .flush: 5,
            .straight: 4,
            .threeOfAKind: 3,
            .twoPair: 2,
            .jacksOrBetter: 1,
            .noWin: 0,
        ],
    )

    /// 8/6 Jacks or Better (full house pays 8 instead of 9). Returns 98.39% with optimal play.
    public static let jacksOrBetter86 = PayTable(
        name: "Jacks or Better (8/6)",
        multipliers: [
            .royalFlush: 800,
            .straightFlush: 50,
            .fourOfAKind: 25,
            .fullHouse: 8,
            .flush: 6,
            .straight: 4,
            .threeOfAKind: 3,
            .twoPair: 2,
            .jacksOrBetter: 1,
            .noWin: 0,
        ],
    )

    /// Full-pay Deuces Wild. Returns 100.76% with optimal play.
    ///
    /// All 2s are wild. Pairs and two-pair do not pay. Minimum winning hand is three of a kind.
    /// Natural royal flush pays 800x (same bonus convention as Jacks or Better at max bet).
    public static let deucesWild = PayTable(
        name: "Deuces Wild (Full Pay)",
        multipliers: [
            .naturalRoyalFlush: 800,
            .fourDeuces: 200,
            .wildRoyalFlush: 25,
            .fiveOfAKind: 15,
            .straightFlush: 9,
            .fourOfAKind: 5,
            .fullHouse: 3,
            .flush: 2,
            .straight: 2,
            .threeOfAKind: 1,
            .noWin: 0,
        ],
        wildcardRank: .two,
    )
}
