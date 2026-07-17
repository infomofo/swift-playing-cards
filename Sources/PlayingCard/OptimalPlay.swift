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
/// ## Usage
///
/// ```swift
/// let engine = OptimalPlay(payTable: .jacksOrBetter96)
/// let result = engine.evaluate(hand: cards, playerHeld: [2, 3])
/// ```
public struct OptimalPlay {
    public let payTable: PayTable

    /// Payout multipliers indexed by HandResult.rawValue (0–9). Cached for fast access.
    private let multiplierTable: [Int]

    public init(payTable: PayTable = .jacksOrBetter96) {
        self.payTable = payTable
        multiplierTable = HandResult.allCases.map { payTable.multiplier(for: $0) }
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
                let heldCodes = (0 ..< 5)
                    .filter { mask & (1 << $0) != 0 }
                    .map { handCodes[$0] }
                group.addTask {
                    (mask: mask, ev: fastEV(held: heldCodes, remaining: remaining))
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
            let codes = indices.map { handCodes[$0] }
            return fastEV(held: codes, remaining: remaining)
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
        let heldCodes = holding.sorted().map { handCodes[$0] }
        return fastEV(held: heldCodes, remaining: remaining)
    }

    // MARK: - Fast Inner Loop

    // swiftlint:disable identifier_name cyclomatic_complexity function_body_length

    /// Computes expected payout by iterating all C(remaining.count, drawCount) completions.
    ///
    /// All arithmetic operates on plain integers; no `PlayingCard` objects are accessed
    /// during the combination loop.
    private func fastEV(held: [Int], remaining: [Int]) -> Double {
        let drawCount = 5 - held.count
        let count = remaining.count
        var total = 0

        switch drawCount {
        case 0:
            return Double(multiplierTable[handResultCode(held[0], held[1], held[2], held[3], held[4])])

        case 1:
            let h0 = held[0], h1 = held[1], h2 = held[2], h3 = held[3]
            for i in 0 ..< count {
                total += multiplierTable[handResultCode(h0, h1, h2, h3, remaining[i])]
            }
            return Double(total) / Double(count)

        case 2:
            let h0 = held[0], h1 = held[1], h2 = held[2]
            for i in 0 ..< count - 1 {
                let card0 = remaining[i]
                for j in i + 1 ..< count {
                    total += multiplierTable[handResultCode(h0, h1, h2, card0, remaining[j])]
                }
            }
            let comboCount = (count * (count - 1)) / 2
            return Double(total) / Double(comboCount)

        case 3:
            let h0 = held[0], h1 = held[1]
            for i in 0 ..< count - 2 {
                let card0 = remaining[i]
                for j in i + 1 ..< count - 1 {
                    let card1 = remaining[j]
                    for k in j + 1 ..< count {
                        total += multiplierTable[handResultCode(h0, h1, card0, card1, remaining[k])]
                    }
                }
            }
            let comboCount = (count * (count - 1) * (count - 2)) / 6
            return Double(total) / Double(comboCount)

        case 4:
            let h0 = held[0]
            for i in 0 ..< count - 3 {
                let card0 = remaining[i]
                for j in i + 1 ..< count - 2 {
                    let card1 = remaining[j]
                    for k in j + 1 ..< count - 1 {
                        let card2 = remaining[k]
                        for l in k + 1 ..< count {
                            total += multiplierTable[handResultCode(h0, card0, card1, card2, remaining[l])]
                        }
                    }
                }
            }
            let comboCount = (count * (count - 1) * (count - 2) * (count - 3)) / 24
            return Double(total) / Double(comboCount)

        case 5:
            for i in 0 ..< count - 4 {
                let card0 = remaining[i]
                for j in i + 1 ..< count - 3 {
                    let card1 = remaining[j]
                    for k in j + 1 ..< count - 2 {
                        let card2 = remaining[k]
                        for l in k + 1 ..< count - 1 {
                            let card3 = remaining[l]
                            for m in l + 1 ..< count {
                                total += multiplierTable[handResultCode(card0, card1, card2, card3, remaining[m])]
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

    /// Evaluates a 5-card hand encoded as integers and returns the `HandResult.rawValue`.
    ///
    /// Encoding per card: `(rank_index << 2) | suit_index`
    /// where rank_index is 0 (two) through 12 (ace) and suit_index is 0–3.
    @inline(__always)
    private func handResultCode(_ c0: Int, _ c1: Int, _ c2: Int, _ c3: Int, _ c4: Int) -> Int {
        let rank0 = c0 >> 2, rank1 = c1 >> 2, rank2 = c2 >> 2, rank3 = c3 >> 2, rank4 = c4 >> 2
        let suit0 = c0 & 3, suit1 = c1 & 3, suit2 = c2 & 3, suit3 = c3 & 3, suit4 = c4 & 3

        let flush = suit0 == suit1 && suit1 == suit2 && suit2 == suit3 && suit3 == suit4

        // Inline insertion sort of the 5 ranks using stack-allocated registers
        var s0 = rank0, s1 = rank1, s2 = rank2, s3 = rank3, s4 = rank4
        var t = 0

        if s0 > s1 {
            t = s0; s0 = s1; s1 = t
        }

        if s1 > s2 {
            t = s1; s1 = s2; s2 = t
            if s0 > s1 {
                t = s0; s0 = s1; s1 = t
            }
        }

        if s2 > s3 {
            t = s2; s2 = s3; s3 = t
            if s1 > s2 {
                t = s1; s1 = s2; s2 = t
                if s0 > s1 {
                    t = s0; s0 = s1; s1 = t
                }
            }
        }

        if s3 > s4 {
            t = s3; s3 = s4; s4 = t
            if s2 > s3 {
                t = s2; s2 = s3; s3 = t
                if s1 > s2 {
                    t = s1; s1 = s2; s2 = t
                    if s0 > s1 {
                        t = s0; s0 = s1; s1 = t
                    }
                }
            }
        }

        // Distinct check for straight detection
        let isDistinct = s0 != s1 && s1 != s2 && s2 != s3 && s3 != s4
        var isStraight = false
        var isRoyal = false

        if isDistinct {
            if s4 - s0 == 4 {
                isStraight = true
                if s3 == 11, s4 == 12 {
                    isRoyal = true
                }
            } else if s0 == 0, s1 == 1, s2 == 2, s3 == 3, s4 == 12 {
                isStraight = true
            }
        }

        // Evaluate Hand Result in precedence order
        if flush && isStraight && isRoyal {
            return HandResult.royalFlush.rawValue
        }
        if flush && isStraight {
            return HandResult.straightFlush.rawValue
        }
        if s0 == s3 || s1 == s4 {
            return HandResult.fourOfAKind.rawValue
        }
        if (s0 == s2 && s3 == s4) || (s0 == s1 && s2 == s4) {
            return HandResult.fullHouse.rawValue
        }
        if flush {
            return HandResult.flush.rawValue
        }
        if isStraight {
            return HandResult.straight.rawValue
        }
        if s0 == s2 || s1 == s3 || s2 == s4 {
            return HandResult.threeOfAKind.rawValue
        }
        if (s0 == s1 && s2 == s3) || (s0 == s1 && s3 == s4) || (s1 == s2 && s3 == s4) {
            return HandResult.twoPair.rawValue
        }
        if s0 == s1 {
            return s1 >= 9 ? HandResult.jacksOrBetter.rawValue : HandResult.noWin.rawValue
        }
        if s1 == s2 {
            return s2 >= 9 ? HandResult.jacksOrBetter.rawValue : HandResult.noWin.rawValue
        }
        if s2 == s3 {
            return s3 >= 9 ? HandResult.jacksOrBetter.rawValue : HandResult.noWin.rawValue
        }
        if s3 == s4 {
            return s4 >= 9 ? HandResult.jacksOrBetter.rawValue : HandResult.noWin.rawValue
        }

        return HandResult.noWin.rawValue
    }

    // swiftlint:enable identifier_name cyclomatic_complexity function_body_length
}
