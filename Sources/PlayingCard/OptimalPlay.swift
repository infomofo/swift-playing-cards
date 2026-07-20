/// The result of evaluating optimal hold strategy for a dealt video poker hand.
///
/// ## Usage
///
/// ```swift
/// let engine = OptimalPlay(payTable: .jacksOrBetter96)
/// let result = engine.evaluate(hand: dealtCards, playerHeld: [0, 1])
/// if let diff = result.evDifference, diff > 0 {
///     print("Suboptimal by \(diff) EV")
/// }
/// ```
public struct OptimalPlayResult {
    /// Indices (0–4) into the dealt hand that maximize expected payout per coin bet.
    public let optimalHeld: Set<Int>
    /// Expected payout multiplier for the optimal hold, averaged over all possible draws.
    public let optimalEV: Double
    /// Indices the player held. Nil when no player hold was provided.
    public let playerHeld: Set<Int>?
    /// Expected payout multiplier for the player's hold. Nil when playerHeld is nil.
    public let playerEV: Double?

    public init(
        optimalHeld: Set<Int>,
        optimalEV: Double,
        playerHeld: Set<Int>? = nil,
        playerEV: Double? = nil,
    ) {
        self.optimalHeld = optimalHeld
        self.optimalEV = optimalEV
        self.playerHeld = playerHeld
        self.playerEV = playerEV
    }

    /// How much EV the player left on the table. Positive = player was suboptimal.
    /// Nil when no player hold was provided.
    public var evDifference: Double? {
        guard let playerEV else { return nil }
        return optimalEV - playerEV
    }

    /// True when the player's hold set matches the optimal hold set.
    /// Nil when no player hold was provided.
    ///
    /// Compares hold sets, not EVs. Returns nil (not false) when `playerHeld` is nil,
    /// consistent with `playerEV`. Can be false even when `evDifference == 0` if the
    /// player held a different set with equal EV.
    public var wasOptimal: Bool? {
        guard let playerHeld else { return nil }
        return playerHeld == optimalHeld
    }
}

/// Computes the mathematically optimal hold strategy for a 5-card video poker hand.
///
/// Uses brute-force enumeration: all 32 possible hold combinations (2^5), and for each,
/// iterates every possible draw completion from the remaining 47 cards to compute the
/// exact expected payout multiplier. The hold set with the highest EV is returned.
///
/// Performance: all 32 hold combinations are evaluated concurrently via `withTaskGroup`,
/// distributing work across available cores. Cards are encoded as integers before the
/// inner loop so no `PlayingCard` objects are accessed during draw enumeration.
///
/// Tie-breaking: when multiple hold sets have identical EV, the one holding more
/// cards wins (conventional: do not draw from a pat hand unless strictly better).
///
/// Wildcard support: only `wildcardRank == .two` (Deuces Wild) is supported. The fast
/// inner-loop evaluator hard-codes rank-index 0 for wildcard detection. Passing a pay
/// table with any other `wildcardRank` will trap at init time.
///
/// ## Usage
///
/// ```swift
/// let engine = OptimalPlay(payTable: .jacksOrBetter96)
/// let result = engine.evaluate(hand: cards, playerHeld: [2, 3])
/// ```
// swiftlint:disable:next type_body_length
public struct OptimalPlay {
    public let payTable: PayTable

    /// Payout multipliers indexed by HandResult.rawValue (0–13). Cached for fast access.
    private let multiplierTable: [Int]

    /// True when the pay table uses wildcard evaluation (e.g. Deuces Wild).
    private let isWild: Bool

    public init(payTable: PayTable = .jacksOrBetter96) {
        precondition(
            payTable.wildcardRank == nil || payTable.wildcardRank == .two,
            "OptimalPlay only supports wildcardRank == .two (Deuces Wild). "
                + "The fast evaluator hard-codes rank-index 0 for wild detection.",
        )
        self.payTable = payTable
        // allCases is declared in rawValue order (0–13), so array index == rawValue.
        multiplierTable = HandResult.allCases.map { payTable.multiplier(for: $0) }
        isWild = payTable.wildcardRank != nil
    }

    /// Evaluates all 32 hold combinations and returns the one with maximum expected value.
    ///
    /// - Parameters:
    ///   - hand: Exactly 5 dealt cards.
    ///   - playerHeld: Optional indices the player chose to hold, for EV comparison.
    /// - Returns: `OptimalPlayResult` with the optimal hold and, if playerHeld was
    ///   provided, the player's EV for comparison.
    public func evaluate(hand: [PlayingCard], playerHeld: Set<Int>? = nil) async -> OptimalPlayResult {
        precondition(hand.count == 5, "OptimalPlay requires exactly 5 dealt cards")
        if let playerHeld {
            precondition(
                playerHeld.allSatisfy { (0 ..< 5).contains($0) },
                "playerHeld indices must be in 0...4",
            )
        }

        // Encode hand and remaining deck as integers for the tight inner loop.
        // Encoding: rank_index * 4 + suit_index
        // rank_index = rank.rawValue - 2 (so two=0, ..., ace=12)
        // suit_index = allCases index (spades=0, hearts=1, diamonds=2, clubs=3)
        let suitOrder: [Suit: Int] = [.spades: 0, .hearts: 1, .diamonds: 2, .clubs: 3]
        let handCodes = hand.map { (($0.rank.rawValue - 2) << 2) | suitOrder[$0.suit]! }
        let handSet = Set(handCodes)
        precondition(handSet.count == 5, "hand must contain 5 unique cards")
        var remaining: [Int] = []
        remaining.reserveCapacity(47)
        for suitIdx in 0 ..< 4 {
            for rankIdx in 0 ..< 13 {
                let code = (rankIdx << 2) | suitIdx
                if !handSet.contains(code) {
                    remaining.append(code)
                }
            }
        }

        // Evaluate all 32 hold combinations concurrently across available cores.
        let evByMask: [(mask: Int, ev: Double)] = await withTaskGroup(
            of: (mask: Int, ev: Double).self,
        ) { group in
            for mask in 0 ..< 32 {
                group.addTask {
                    let ev = isWild
                        ? fastEVWild(handCodes: handCodes, mask: mask, remaining: remaining)
                        : fastEV(handCodes: handCodes, mask: mask, remaining: remaining)
                    return (mask: mask, ev: ev)
                }
            }
            var collected: [(mask: Int, ev: Double)] = []
            collected.reserveCapacity(32)
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        var bestEV = -Double.infinity
        var bestHeld = Set<Int>()
        var bestHeldCount = -1
        for (mask, ev) in evByMask.sorted(by: { $0.mask < $1.mask }) {
            let heldIndices = (0 ..< 5).filter { mask & (1 << $0) != 0 }
            let count = heldIndices.count
            // Prefer strictly higher EV; break ties by holding more cards.
            if ev > bestEV || (ev == bestEV && count > bestHeldCount) {
                bestEV = ev
                bestHeld = Set(heldIndices)
                bestHeldCount = count
            }
        }

        let playerEV = playerHeld.map { indices -> Double in
            var mask = 0
            for idx in indices {
                mask |= (1 << idx)
            }
            return isWild
                ? fastEVWild(handCodes: handCodes, mask: mask, remaining: remaining)
                : fastEV(handCodes: handCodes, mask: mask, remaining: remaining)
        }

        return OptimalPlayResult(
            optimalHeld: bestHeld,
            optimalEV: bestEV,
            playerHeld: playerHeld,
            playerEV: playerEV,
        )
    }

    /// Returns the expected payout multiplier for one specific hold set, without
    /// evaluating all 32 combinations.
    ///
    /// Use this when the optimal hold is already known (e.g. precomputed during the
    /// deal phase) and you only need the player's EV for a specific set of held indices.
    ///
    /// - Parameters:
    ///   - hand: Exactly 5 dealt cards.
    ///   - holding: Indices (0–4) to hold; empty set means draw all 5.
    /// - Returns: Expected payout multiplier averaged over all possible draw completions.
    public func expectedValue(for hand: [PlayingCard], holding: Set<Int>) -> Double {
        precondition(hand.count == 5, "OptimalPlay requires exactly 5 dealt cards")
        precondition(
            holding.allSatisfy { (0 ..< 5).contains($0) },
            "holding indices must be in 0..<5",
        )
        let suitOrder: [Suit: Int] = [.spades: 0, .hearts: 1, .diamonds: 2, .clubs: 3]
        let handCodes = hand.map { (($0.rank.rawValue - 2) << 2) | suitOrder[$0.suit]! }
        let handSet = Set(handCodes)
        precondition(handSet.count == 5, "hand must contain 5 unique cards")
        var remaining: [Int] = []
        remaining.reserveCapacity(47)
        for suitIdx in 0 ..< 4 {
            for rankIdx in 0 ..< 13 {
                let code = (rankIdx << 2) | suitIdx
                if !handSet.contains(code) {
                    remaining.append(code)
                }
            }
        }
        var mask = 0
        for idx in holding {
            mask |= (1 << idx)
        }
        return isWild
            ? fastEVWild(handCodes: handCodes, mask: mask, remaining: remaining)
            : fastEV(handCodes: handCodes, mask: mask, remaining: remaining)
    }

    // MARK: - Fast Inner Loop

    // swiftlint:disable identifier_name cyclomatic_complexity function_body_length

    /// Computes expected payout by iterating all C(remaining.count, drawCount) completions.
    ///
    /// All arithmetic operates on plain integers; no `PlayingCard` objects are accessed
    /// during the combination loop.
    private func fastEV(handCodes: [Int], mask: Int, remaining: [Int]) -> Double {
        let c0 = handCodes[0], c1 = handCodes[1], c2 = handCodes[2], c3 = handCodes[3], c4 = handCodes[4]
        return multiplierTable.withUnsafeBufferPointer { multsBuf in
            let mults = multsBuf.baseAddress!
            return remaining.withUnsafeBufferPointer { remBuf in
                let rem = remBuf.baseAddress!
                let count = remBuf.count
                var total = 0

                // Extract held cards efficiently to local registers using bitwise mask operations.
                // This avoids heap-allocated array creation in the hot path.
                var h0 = 0, h1 = 0, h2 = 0, h3 = 0, h4 = 0
                var drawCount = 0

                if mask & (1 << 0) != 0 {
                    h0 = c0
                } else {
                    drawCount += 1
                }

                if mask & (1 << 1) != 0 {
                    switch drawCount {
                    case 0: h1 = c1
                    default: h0 = c1
                    }
                } else {
                    drawCount += 1
                }

                if mask & (1 << 2) != 0 {
                    switch drawCount {
                    case 0: h2 = c2
                    case 1: h1 = c2
                    default: h0 = c2
                    }
                } else {
                    drawCount += 1
                }

                if mask & (1 << 3) != 0 {
                    switch drawCount {
                    case 0: h3 = c3
                    case 1: h2 = c3
                    case 2: h1 = c3
                    default: h0 = c3
                    }
                } else {
                    drawCount += 1
                }

                if mask & (1 << 4) != 0 {
                    switch drawCount {
                    case 0: h4 = c4
                    case 1: h3 = c4
                    case 2: h2 = c4
                    case 3: h1 = c4
                    default: h0 = c4
                    }
                } else {
                    drawCount += 1
                }

                switch drawCount {
                case 0:
                    return Double(mults[FastHandEvaluator.standardCode(h0, h1, h2, h3, h4)])

                case 1:
                    for i in 0 ..< count {
                        total += mults[FastHandEvaluator.standardCode(h0, h1, h2, h3, rem[i])]
                    }
                    return Double(total) / Double(count)

                case 2:
                    for i in 0 ..< count - 1 {
                        let card0 = rem[i]
                        for j in i + 1 ..< count {
                            total += mults[FastHandEvaluator.standardCode(h0, h1, h2, card0, rem[j])]
                        }
                    }
                    let comboCount = (count * (count - 1)) / 2
                    return Double(total) / Double(comboCount)

                case 3:
                    for i in 0 ..< count - 2 {
                        let card0 = rem[i]
                        for j in i + 1 ..< count - 1 {
                            let card1 = rem[j]
                            for k in j + 1 ..< count {
                                total += mults[FastHandEvaluator.standardCode(h0, h1, card0, card1, rem[k])]
                            }
                        }
                    }
                    let comboCount = (count * (count - 1) * (count - 2)) / 6
                    return Double(total) / Double(comboCount)

                case 4:
                    for i in 0 ..< count - 3 {
                        let card0 = rem[i]
                        for j in i + 1 ..< count - 2 {
                            let card1 = rem[j]
                            for k in j + 1 ..< count - 1 {
                                let card2 = rem[k]
                                for l in k + 1 ..< count {
                                    total += mults[FastHandEvaluator.standardCode(h0, card0, card1, card2, rem[l])]
                                }
                            }
                        }
                    }
                    let comboCount = (count * (count - 1) * (count - 2) * (count - 3)) / 24
                    return Double(total) / Double(comboCount)

                case 5:
                    for i in 0 ..< count - 4 {
                        let card0 = rem[i]
                        for j in i + 1 ..< count - 3 {
                            let card1 = rem[j]
                            for k in j + 1 ..< count - 2 {
                                let card2 = rem[k]
                                for l in k + 1 ..< count - 1 {
                                    let card3 = rem[l]
                                    for m in l + 1 ..< count {
                                        total += mults[FastHandEvaluator.standardCode(card0, card1, card2, card3, rem[m])]
                                    }
                                }
                            }
                        }
                    }
                    let comboCount = (count * (count - 1) * (count - 2) * (count - 3) * (count - 4)) / 120
                    return Double(total) / Double(comboCount)

                default:
                    preconditionFailure("drawCount must be 0–5, got \(drawCount)")
                }
            }
        }
    }

    // MARK: - Deuces Wild inner loop

    /// `fastEV` variant for Deuces Wild. Dispatches hand evaluation through
    /// `FastHandEvaluator.deucesWildCode` which treats rank_index 0 (the 2) as a wildcard.
    private func fastEVWild(handCodes: [Int], mask: Int, remaining: [Int]) -> Double {
        let c0 = handCodes[0], c1 = handCodes[1], c2 = handCodes[2], c3 = handCodes[3], c4 = handCodes[4]
        return multiplierTable.withUnsafeBufferPointer { multsBuf in
            let mults = multsBuf.baseAddress!
            return remaining.withUnsafeBufferPointer { remBuf in
                let rem = remBuf.baseAddress!
                let count = remBuf.count
                var total = 0

                // Extract held cards efficiently to local registers using bitwise mask operations.
                // This avoids heap-allocated array creation in the hot path.
                var h0 = 0, h1 = 0, h2 = 0, h3 = 0, h4 = 0
                var drawCount = 0

                if mask & (1 << 0) != 0 {
                    h0 = c0
                } else {
                    drawCount += 1
                }

                if mask & (1 << 1) != 0 {
                    switch drawCount {
                    case 0: h1 = c1
                    default: h0 = c1
                    }
                } else {
                    drawCount += 1
                }

                if mask & (1 << 2) != 0 {
                    switch drawCount {
                    case 0: h2 = c2
                    case 1: h1 = c2
                    default: h0 = c2
                    }
                } else {
                    drawCount += 1
                }

                if mask & (1 << 3) != 0 {
                    switch drawCount {
                    case 0: h3 = c3
                    case 1: h2 = c3
                    case 2: h1 = c3
                    default: h0 = c3
                    }
                } else {
                    drawCount += 1
                }

                if mask & (1 << 4) != 0 {
                    switch drawCount {
                    case 0: h4 = c4
                    case 1: h3 = c4
                    case 2: h2 = c4
                    case 3: h1 = c4
                    default: h0 = c4
                    }
                } else {
                    drawCount += 1
                }

                switch drawCount {
                case 0:
                    return Double(mults[FastHandEvaluator.deucesWildCode(h0, h1, h2, h3, h4)])

                case 1:
                    for i in 0 ..< count {
                        total += mults[FastHandEvaluator.deucesWildCode(h0, h1, h2, h3, rem[i])]
                    }
                    return Double(total) / Double(count)

                case 2:
                    for i in 0 ..< count - 1 {
                        let card0 = rem[i]
                        for j in i + 1 ..< count {
                            total += mults[FastHandEvaluator.deucesWildCode(h0, h1, h2, card0, rem[j])]
                        }
                    }
                    let comboCount = (count * (count - 1)) / 2
                    return Double(total) / Double(comboCount)

                case 3:
                    for i in 0 ..< count - 2 {
                        let card0 = rem[i]
                        for j in i + 1 ..< count - 1 {
                            let card1 = rem[j]
                            for k in j + 1 ..< count {
                                total += mults[FastHandEvaluator.deucesWildCode(h0, h1, card0, card1, rem[k])]
                            }
                        }
                    }
                    let comboCount = (count * (count - 1) * (count - 2)) / 6
                    return Double(total) / Double(comboCount)

                case 4:
                    for i in 0 ..< count - 3 {
                        let card0 = rem[i]
                        for j in i + 1 ..< count - 2 {
                            let card1 = rem[j]
                            for k in j + 1 ..< count - 1 {
                                let card2 = rem[k]
                                for l in k + 1 ..< count {
                                    total += mults[FastHandEvaluator.deucesWildCode(h0, card0, card1, card2, rem[l])]
                                }
                            }
                        }
                    }
                    let comboCount = (count * (count - 1) * (count - 2) * (count - 3)) / 24
                    return Double(total) / Double(comboCount)

                case 5:
                    for i in 0 ..< count - 4 {
                        let card0 = rem[i]
                        for j in i + 1 ..< count - 3 {
                            let card1 = rem[j]
                            for k in j + 1 ..< count - 2 {
                                let card2 = rem[k]
                                for l in k + 1 ..< count - 1 {
                                    let card3 = rem[l]
                                    for m in l + 1 ..< count {
                                        total += mults[FastHandEvaluator.deucesWildCode(card0, card1, card2, card3, rem[m])]
                                    }
                                }
                            }
                        }
                    }
                    let comboCount = (count * (count - 1) * (count - 2) * (count - 3) * (count - 4)) / 120
                    return Double(total) / Double(comboCount)

                default:
                    preconditionFailure("drawCount must be 0–5, got \(drawCount)")
                }
            }
        }
    }

    // swiftlint:enable identifier_name cyclomatic_complexity function_body_length
}
