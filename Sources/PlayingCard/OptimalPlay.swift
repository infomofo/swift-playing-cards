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
                let heldCodes = (0 ..< 5)
                    .filter { mask & (1 << $0) != 0 }
                    .map { handCodes[$0] }
                group.addTask {
                    let ev = isWild
                        ? fastEVWild(held: heldCodes, remaining: remaining)
                        : fastEV(held: heldCodes, remaining: remaining)
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
            let codes = indices.map { handCodes[$0] }
            return isWild
                ? fastEVWild(held: codes, remaining: remaining)
                : fastEV(held: codes, remaining: remaining)
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
        return isWild
            ? fastEVWild(held: heldCodes, remaining: remaining)
            : fastEV(held: heldCodes, remaining: remaining)
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

    // MARK: - Deuces Wild inner loop

    /// `fastEV` variant for Deuces Wild. Dispatches hand evaluation through
    /// `handResultCodeDeuces` which treats rank_index 0 (the 2) as a wildcard.
    private func fastEVWild(held: [Int], remaining: [Int]) -> Double {
        let drawCount = 5 - held.count
        let count = remaining.count
        var total = 0

        switch drawCount {
        case 0:
            return Double(
                multiplierTable[
                    handResultCodeDeuces(held[0], held[1], held[2], held[3], held[4]),
                ],
            )

        case 1:
            let h0 = held[0], h1 = held[1], h2 = held[2], h3 = held[3]
            for i in 0 ..< count {
                total += multiplierTable[handResultCodeDeuces(h0, h1, h2, h3, remaining[i])]
            }
            return Double(total) / Double(count)

        case 2:
            let h0 = held[0], h1 = held[1], h2 = held[2]
            for i in 0 ..< count - 1 {
                let card0 = remaining[i]
                for j in i + 1 ..< count {
                    total += multiplierTable[handResultCodeDeuces(h0, h1, h2, card0, remaining[j])]
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
                        total += multiplierTable[
                            handResultCodeDeuces(h0, h1, card0, card1, remaining[k]),
                        ]
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
                            total += multiplierTable[
                                handResultCodeDeuces(h0, card0, card1, card2, remaining[l]),
                            ]
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
                                total += multiplierTable[
                                    handResultCodeDeuces(card0, card1, card2, card3, remaining[m]),
                                ]
                            }
                        }
                    }
                }
            }
            let comboCount =
                (count * (count - 1) * (count - 2) * (count - 3) * (count - 4)) / 120
            return Double(total) / Double(comboCount)

        default:
            preconditionFailure("drawCount must be 0–5, got \(drawCount)")
        }
    }

    /// Deuces Wild hand evaluator. Treats rank_index 0 (the physical 2) as a wildcard that
    /// substitutes for any card (any rank and suit).
    ///
    /// Evaluation priority: naturalRoyalFlush > fourDeuces > wildRoyalFlush > fiveOfAKind >
    /// straightFlush > fourOfAKind > fullHouse > flush > straight > threeOfAKind > noWin.
    ///
    /// For k=0, delegates to `handResultCode` and remaps the result to DW conventions
    /// (royal flush → naturalRoyalFlush; pair/two-pair → noWin).
    @inline(__always)
    private func handResultCodeDeuces(
        _ c0: Int, _ c1: Int, _ c2: Int, _ c3: Int, _ c4: Int,
    ) -> Int {
        // rank_index 0 = deuce = wild.
        let r0 = c0 >> 2, r1 = c1 >> 2, r2 = c2 >> 2, r3 = c3 >> 2, r4 = c4 >> 2

        // Count wildcards.
        let k = (r0 == 0 ? 1 : 0) + (r1 == 0 ? 1 : 0) + (r2 == 0 ? 1 : 0)
            + (r3 == 0 ? 1 : 0) + (r4 == 0 ? 1 : 0)

        // k=4: Four Deuces.
        if k == 4 {
            return HandResult.fourDeuces.rawValue
        }

        // k=0: Standard JoB evaluation with DW remapping.
        if k == 0 {
            let base = handResultCode(c0, c1, c2, c3, c4)
            if base == HandResult.royalFlush.rawValue {
                return HandResult.naturalRoyalFlush.rawValue
            }
            // Pair (jacksOrBetter=1) and two-pair (2) don't pay in DW.
            return base <= 2 ? HandResult.noWin.rawValue : base
        }

        // k = 1, 2, or 3 — extract natural (non-wild) cards into fixed slots.
        // n = 5 - k  (guaranteed 2–4 naturals).
        // c0 is first: if r0 != 0, n is always 0 before this block.
        var na0 = 0, na1 = 0, na2 = 0, na3 = 0 // natural rank indices
        var ns0 = 0, ns1 = 0, ns2 = 0, ns3 = 0 // natural suit indices
        var n = 0

        if r0 != 0 {
            na0 = r0; ns0 = c0 & 3; n = 1
        }
        if r1 != 0 {
            switch n {
            case 0: na0 = r1; ns0 = c1 & 3
            case 1: na1 = r1; ns1 = c1 & 3
            default: na2 = r1; ns2 = c1 & 3
            }
            n += 1
        }
        if r2 != 0 {
            switch n {
            case 0: na0 = r2; ns0 = c2 & 3
            case 1: na1 = r2; ns1 = c2 & 3
            case 2: na2 = r2; ns2 = c2 & 3
            default: na3 = r2; ns3 = c2 & 3
            }
            n += 1
        }
        if r3 != 0 {
            switch n {
            case 0: na0 = r3; ns0 = c3 & 3
            case 1: na1 = r3; ns1 = c3 & 3
            case 2: na2 = r3; ns2 = c3 & 3
            default: na3 = r3; ns3 = c3 & 3
            }
            n += 1
        }
        if r4 != 0 {
            switch n {
            case 0: na0 = r4; ns0 = c4 & 3
            case 1: na1 = r4; ns1 = c4 & 3
            case 2: na2 = r4; ns2 = c4 & 3
            default: na3 = r4; ns3 = c4 & 3
            }
            n += 1
        }

        // Compute per-rank frequencies and distinct-rank count without allocation.
        // Slots d0–d3 hold distinct rank values; f0–f3 hold their frequencies.
        var d0 = -1, d1 = -1, d2 = -1, d3 = -1
        var f0 = 0, f1 = 0, f2 = 0, f3 = 0
        var dCount = 0

        func countRank(_ r: Int) {
            if r == d0 {
                f0 += 1; return
            }
            if d0 == -1 {
                d0 = r; f0 = 1; dCount = 1; return
            }
            if r == d1 {
                f1 += 1; return
            }
            if d1 == -1 {
                d1 = r; f1 = 1; dCount = 2; return
            }
            if r == d2 {
                f2 += 1; return
            }
            if d2 == -1 {
                d2 = r; f2 = 1; dCount = 3; return
            }
            if r == d3 {
                f3 += 1; return
            }
            if d3 == -1 {
                d3 = r; f3 = 1; dCount = 4; return
            }
        }

        countRank(na0)
        countRank(na1)
        if n > 2 {
            countRank(na2)
        }
        if n > 3 {
            countRank(na3)
        }

        let maxFreq = max(f0, max(f1, max(f2, f3)))

        // Wild Royal Flush: all naturals are royal (rank_idx 8–12 = T through A),
        // all same suit, all distinct ranks. Wildcards fill remaining royal slots.
        // n + k = 5 always, so wilds always fill exactly the missing royal positions.
        if maxFreq == 1 { // distinct check shortcut: if all freqs are 1, ranks are distinct
            let allRoyal = na0 >= 8 && na1 >= 8 && (n < 3 || na2 >= 8) && (n < 4 || na3 >= 8)
            if allRoyal {
                let suit = ns0
                let allSameSuit =
                    ns1 == suit && (n < 3 || ns2 == suit) && (n < 4 || ns3 == suit)
                if allSameSuit {
                    return HandResult.wildRoyalFlush.rawValue
                }
            }
        }

        // Five of a Kind: most-frequent rank + wildcards ≥ 5.
        if maxFreq + k >= 5 {
            return HandResult.fiveOfAKind.rawValue
        }

        // Straight Flush: all naturals share a suit, distinct ranks, fit in a 5-card window.
        let sfSuit = ns0
        let allSameSuit =
            ns1 == sfSuit && (n < 3 || ns2 == sfSuit) && (n < 4 || ns3 == sfSuit)
        if allSameSuit {
            // distinct means dCount == n (all different ranks).
            let rankDistinct = dCount == n
            if rankDistinct {
                if dwCanFormStraightWindow(na0, na1, na2, na3, n: n) {
                    return HandResult.straightFlush.rawValue
                }
            }
        }

        // Four of a Kind.
        if maxFreq + k >= 4 {
            return HandResult.fourOfAKind.rawValue
        }

        // Full House: at most 2 distinct natural ranks, wilds fill the gaps.
        if dCount <= 2 {
            var sortF1 = f0, sortF2 = f1
            if dCount == 1 {
                sortF2 = 0
            }
            if sortF1 < sortF2 {
                let t = sortF1; sortF1 = sortF2; sortF2 = t
            }
            let wildsA = max(0, 3 - sortF1) + max(0, 2 - sortF2)
            let wildsB = max(0, 2 - sortF1) + max(0, 3 - sortF2)
            if min(wildsA, wildsB) <= k {
                return HandResult.fullHouse.rawValue
            }
        }

        // Flush: all naturals same suit (SF already failed, so no straight window).
        if allSameSuit {
            return HandResult.flush.rawValue
        }

        // Straight: distinct natural ranks fit in a 5-card window (suit-agnostic).
        if dCount == n { // all distinct
            if dwCanFormStraightWindow(na0, na1, na2, na3, n: n) {
                return HandResult.straight.rawValue
            }
        }

        // Three of a Kind: most-frequent rank + wildcards ≥ 3.
        if maxFreq + k >= 3 {
            return HandResult.threeOfAKind.rawValue
        }

        return HandResult.noWin.rawValue
    }

    /// Returns true when `n` natural rank indices (na0…na(n-1)) fit inside a 5-card
    /// straight window using wildcards to fill the remaining positions.
    ///
    /// Handles both the standard case (span ≤ 4) and the wheel A-2-3-4-5
    /// (rank_index 12 = Ace, with the 2 being wild and naturals in {1,2,3} = ranks 3,4,5).
    @inline(__always)
    private func dwCanFormStraightWindow(
        _ na0: Int, _ na1: Int, _ na2: Int, _ na3: Int, n: Int,
    ) -> Bool {
        var lo = na0, hi = na0
        if na1 < lo {
            lo = na1
        } else if na1 > hi {
            hi = na1
        }
        if n > 2 {
            if na2 < lo {
                lo = na2
            } else if na2 > hi {
                hi = na2
            }
        }
        if n > 3 {
            if na3 < lo {
                lo = na3
            } else if na3 > hi {
                hi = na3
            }
        }

        let span = hi - lo
        if span <= 4 {
            return true
        }

        // Wheel: Ace (rank_index 12) + naturals in {1, 2, 3} (actual ranks 3–5).
        // The 2 (rank_index 0) is always wild, so naturals can't contribute rank_index 0.
        if hi == 12 { // ace present
            let nonAceOK =
                dwAllInWheelRange(na0, na1, na2, na3, n: n, lo: lo)
            if nonAceOK {
                return true
            }
        }
        return false
    }

    /// Returns true when all non-ace natural ranks (rank_idx != 12) are in [1, 3].
    @inline(__always)
    private func dwAllInWheelRange(
        _ na0: Int, _ na1: Int, _ na2: Int, _ na3: Int, n: Int, lo: Int,
    ) -> Bool {
        /// lo is the minimum rank_index; if lo == 12 all cards are aces (impossible for n>1).
        func inRange(_ r: Int) -> Bool {
            r == 12 || (r >= 1 && r <= 3)
        }
        if !inRange(na0) || !inRange(na1) {
            return false
        }
        if n > 2, !inRange(na2) {
            return false
        }
        if n > 3, !inRange(na3) {
            return false
        }
        _ = lo
        return true
    }

    // swiftlint:enable identifier_name cyclomatic_complexity function_body_length
}
