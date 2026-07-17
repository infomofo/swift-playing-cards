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
        playerEV: Double? = nil
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
/// Performance: cards are encoded as integers before the inner loop to eliminate Swift
/// object allocation in the tight path. Typical call time on Apple Watch hardware
/// is well under 1 second in a release build.
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
    public func evaluate(hand: [PlayingCard], playerHeld: Set<Int>? = nil) -> OptimalPlayResult {
        precondition(hand.count == 5, "OptimalPlay requires exactly 5 dealt cards")
        if let playerHeld {
            precondition(
                playerHeld.allSatisfy { (0 ..< 5).contains($0) },
                "playerHeld indices must be in 0...4"
            )
        }

        // Encode hand and remaining deck as integers for the tight inner loop.
        // Encoding: rank_index * 4 + suit_index
        // rank_index = rank.rawValue - 2 (so two=0, ..., ace=12)
        // suit_index = allCases index (spades=0, hearts=1, diamonds=2, clubs=3)
        let suitOrder: [Suit: Int] = [.spades: 0, .hearts: 1, .diamonds: 2, .clubs: 3]
        let handCodes = hand.map { (($0.rank.rawValue - 2) << 2) | suitOrder[$0.suit]! }
        let handSet = Set(handCodes)
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

        var bestEV = -Double.infinity
        var bestHeld = Set<Int>()
        var bestHeldCount = -1

        for mask in 0 ..< 32 {
            let heldIndices = (0 ..< 5).filter { mask & (1 << $0) != 0 }
            let heldCodes = heldIndices.map { handCodes[$0] }
            let expectedValue = fastEV(held: heldCodes, remaining: remaining)
            let count = heldIndices.count
            // Prefer strictly higher EV; break ties by holding more cards.
            if expectedValue > bestEV || (expectedValue == bestEV && count > bestHeldCount) {
                bestEV = expectedValue
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
            playerEV: playerEV
        )
    }

    // MARK: - Fast Inner Loop

    /// Computes expected payout by iterating all C(remaining.count, drawCount) completions.
    ///
    /// All arithmetic is on plain integers; no Swift objects are created per iteration.
    private func fastEV(held: [Int], remaining: [Int]) -> Double {
        let drawCount = 5 - held.count
        if drawCount == 0 {
            return Double(multiplierTable[handResultCode(held)])
        }

        let deckSize = remaining.count
        var indices = Array(0 ..< drawCount)
        var total = 0
        var comboCount = 0
        var buf = held + Array(repeating: 0, count: drawCount)

        while true {
            for idx in 0 ..< drawCount {
                buf[held.count + idx] = remaining[indices[idx]]
            }
            total += multiplierTable[handResultCode(buf)]
            comboCount += 1

            var pos = drawCount - 1
            while pos >= 0, indices[pos] == deckSize - drawCount + pos {
                pos -= 1
            }
            guard pos >= 0 else { break }
            indices[pos] += 1
            for jdx in (pos + 1) ..< drawCount {
                indices[jdx] = indices[jdx - 1] + 1
            }
        }

        return Double(total) / Double(comboCount)
    }

    /// Evaluates a 5-card hand encoded as integers and returns the `HandResult.rawValue`.
    ///
    /// Encoding per card: `(rank_index << 2) | suit_index`
    /// where rank_index is 0 (two) through 12 (ace) and suit_index is 0–3.
    private func handResultCode(_ codes: [Int]) -> Int {
        let rank0 = codes[0] >> 2, rank1 = codes[1] >> 2, rank2 = codes[2] >> 2,
            rank3 = codes[3] >> 2, rank4 = codes[4] >> 2
        let suit0 = codes[0] & 3, suit1 = codes[1] & 3, suit2 = codes[2] & 3,
            suit3 = codes[3] & 3, suit4 = codes[4] & 3

        let flush = suit0 == suit1 && suit1 == suit2 && suit2 == suit3 && suit3 == suit4
        let (maxFreq, secondFreq, pairHighRank) = rankFrequencies(
            rank0, rank1, rank2, rank3, rank4
        )
        let (isStraight, isRoyal) = checkStraight(
            rank0, rank1, rank2, rank3, rank4, maxFreq: maxFreq
        )
        return resultCode(
            flush: flush, isStraight: isStraight, isRoyal: isRoyal,
            maxFreq: maxFreq, secondFreq: secondFreq, pairHighRank: pairHighRank
        )
    }

    /// Returns (maxFreq, secondFreq, highestPairRank) from five rank indices.
    private func rankFrequencies(
        _ rank0: Int, _ rank1: Int, _ rank2: Int, _ rank3: Int, _ rank4: Int
    ) -> (Int, Int, Int) {
        var freq = [Int](repeating: 0, count: 13)
        freq[rank0] += 1; freq[rank1] += 1; freq[rank2] += 1
        freq[rank3] += 1; freq[rank4] += 1
        var maxFreq = 0, secondFreq = 0, pairHighRank = -1
        for rank in 0 ..< 13 {
            let cnt = freq[rank]
            if cnt > maxFreq {
                secondFreq = maxFreq; maxFreq = cnt
            } else if cnt > secondFreq {
                secondFreq = cnt
            }
            if cnt == 2 {
                pairHighRank = rank
            }
        }
        return (maxFreq, secondFreq, pairHighRank)
    }

    /// Returns (isStraight, isRoyal) for five rank indices.
    ///
    /// isRoyal is true when the hand is a straight with sorted ranks [8,9,10,11,12]
    /// (T-J-Q-K-A), which combined with flush gives a royal flush.
    private func checkStraight(
        _ rank0: Int, _ rank1: Int, _ rank2: Int, _ rank3: Int, _ rank4: Int, maxFreq: Int
    ) -> (Bool, Bool) {
        guard maxFreq == 1 else { return (false, false) }
        var sorted = [rank0, rank1, rank2, rank3, rank4]
        for idx in 1 ..< 5 {
            let key = sorted[idx]; var jdx = idx - 1
            while jdx >= 0, sorted[jdx] > key {
                sorted[jdx + 1] = sorted[jdx]; jdx -= 1
            }
            sorted[jdx + 1] = key
        }
        let isContiguous = sorted[4] - sorted[0] == 4
        let isWheel = sorted[0] == 0 && sorted[1] == 1 && sorted[2] == 2
            && sorted[3] == 3 && sorted[4] == 12
        let isStraight = isContiguous || isWheel
        // Royal: A-K-Q-J-T; sorted ranks 8,9,10,11,12.
        let isRoyal = isContiguous && sorted[3] == 11 && sorted[4] == 12
        return (isStraight, isRoyal)
    }

    /// Maps hand attributes to a `HandResult.rawValue` index.
    private func resultCode(
        flush: Bool, isStraight: Bool, isRoyal: Bool,
        maxFreq: Int, secondFreq: Int, pairHighRank: Int
    ) -> Int {
        if flush && isRoyal {
            return HandResult.royalFlush.rawValue
        }
        if flush && isStraight {
            return HandResult.straightFlush.rawValue
        }
        if maxFreq == 4 {
            return HandResult.fourOfAKind.rawValue
        }
        if maxFreq == 3 && secondFreq == 2 {
            return HandResult.fullHouse.rawValue
        }
        if flush {
            return HandResult.flush.rawValue
        }
        if isStraight {
            return HandResult.straight.rawValue
        }
        if maxFreq == 3 {
            return HandResult.threeOfAKind.rawValue
        }
        if maxFreq == 2 && secondFreq == 2 {
            return HandResult.twoPair.rawValue
        }
        if maxFreq == 2 {
            // Jacks or better: pair rank_index >= 9 (J=9, Q=10, K=11, A=12).
            return pairHighRank >= 9 ? HandResult.jacksOrBetter.rawValue : HandResult.noWin.rawValue
        }
        return HandResult.noWin.rawValue
    }
}
