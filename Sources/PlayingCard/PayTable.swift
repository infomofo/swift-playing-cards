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
        case .noWin: return "No Win"
        case .jacksOrBetter: return "Jacks or Better"
        case .twoPair: return "Two Pair"
        case .threeOfAKind: return "Three of a Kind"
        case .straight: return "Straight"
        case .flush: return "Flush"
        case .fullHouse: return "Full House"
        case .fourOfAKind: return "Four of a Kind"
        case .straightFlush: return "Straight Flush"
        case .royalFlush: return "Royal Flush"
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
            let rankCounts = Dictionary(grouping: cards.map { $0.rank }, by: { $0 })
                .mapValues { $0.count }
            if let pairRank = rankCounts.first(where: { $0.value == 2 })?.key,
               pairRank >= .jack
            {
                return .jacksOrBetter
            }
            return .noWin
        case .highCard:
            return .noWin
        }
    }
}

/// A video poker pay table mapping hand results to coin multipliers.
///
/// Usage:
/// ```swift
/// let table = PayTable.jacksOrBetter96
/// let result = table.handResult(for: cards)     // HandResult
/// let net = table.netPayout(for: cards, bet: 5) // e.g. +10 for two pair, -5 for no win
/// ```
public struct PayTable {
    /// Human-readable name, e.g. "Jacks or Better (9/6)".
    public let name: String

    private let multipliers: [HandResult: Int]

    public init(name: String, multipliers: [HandResult: Int]) {
        self.name = name
        self.multipliers = multipliers
    }

    /// The payout multiplier for a given hand result (e.g. 9 for full house).
    public func multiplier(for result: HandResult) -> Int {
        multipliers[result] ?? 0
    }

    /// Evaluates the cards and returns their `HandResult`.
    public func handResult(for cards: [PlayingCard]) -> HandResult {
        HandResult.evaluate(cards: cards)
    }

    /// Total coins returned for the given bet (bet is not included in the return).
    ///
    /// For example, a two pair with a 5-coin bet returns 10 coins (2x multiplier).
    public func payout(for cards: [PlayingCard], bet: Int = 5) -> Int {
        multiplier(for: handResult(for: cards)) * bet
    }

    /// Net coins won or lost: `payout - bet`.
    ///
    /// - Two pair, bet 5: +5
    /// - Jacks or Better, bet 5: 0 (push — bet returned)
    /// - No win, bet 5: -5
    public func netPayout(for cards: [PlayingCard], bet: Int = 5) -> Int {
        payout(for: cards, bet: bet) - bet
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
        ]
    )
}
