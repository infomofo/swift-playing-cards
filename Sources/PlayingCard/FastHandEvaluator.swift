/// Integer-encoded, allocation-free hand evaluators shared by `OptimalPlay`'s live
/// per-hand hot loop and `HandOutcomeArrays`' one-time full-deck build pass.
///
/// Extracted from `OptimalPlay` so both consumers score a hand with exactly one
/// implementation instead of duplicating this logic. Card encoding throughout:
/// `(rank_index << 2) | suit_index`, where rank_index is 0 (two) through 12 (ace) and
/// suit_index is 0–3.
enum FastHandEvaluator {
    // swiftlint:disable identifier_name cyclomatic_complexity function_body_length

    /// Evaluates a 5-card hand encoded as integers and returns the `HandResult.rawValue`.
    ///
    /// Encoding per card: `(rank_index << 2) | suit_index`
    /// where rank_index is 0 (two) through 12 (ace) and suit_index is 0–3.
    @inline(__always)
    static func standardCode(_ c0: Int, _ c1: Int, _ c2: Int, _ c3: Int, _ c4: Int) -> Int {
        let rank0 = c0 >> 2, rank1 = c1 >> 2, rank2 = c2 >> 2, rank3 = c3 >> 2, rank4 = c4 >> 2
        let suit0 = c0 & 3, suit1 = c1 & 3, suit2 = c2 & 3, suit3 = c3 & 3, suit4 = c4 & 3

        let flush = suit0 == suit1 && suit1 == suit2 && suit2 == suit3 && suit3 == suit4

        // ⚡ Bolt Optimization: Use the optimal 5-element sorting network (Bose-Nelson algorithm).
        // It uses exactly 9 comparisons in a flat, branch-friendly layout instead of a deeply
        // nested insertion sort, significantly improving pipeline efficiency and CPI.
        var s0 = rank0, s1 = rank1, s2 = rank2, s3 = rank3, s4 = rank4
        var t = 0

        if s0 > s3 {
            t = s0; s0 = s3; s3 = t
        }
        if s1 > s4 {
            t = s1; s1 = s4; s4 = t
        }

        if s0 > s2 {
            t = s0; s0 = s2; s2 = t
        }
        if s1 > s3 {
            t = s1; s1 = s3; s3 = t
        }

        if s0 > s1 {
            t = s0; s0 = s1; s1 = t
        }
        if s2 > s4 {
            t = s2; s2 = s4; s4 = t
        }

        if s1 > s2 {
            t = s1; s1 = s2; s2 = t
        }
        if s3 > s4 {
            t = s3; s3 = s4; s4 = t
        }

        if s2 > s3 {
            t = s2; s2 = s3; s3 = t
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

    /// Deuces Wild hand evaluator. Treats rank_index 0 (the physical 2) as a wildcard that
    /// substitutes for any card (any rank and suit).
    ///
    /// Evaluation priority: naturalRoyalFlush > fourDeuces > wildRoyalFlush > fiveOfAKind >
    /// straightFlush > fourOfAKind > fullHouse > flush > straight > threeOfAKind > noWin.
    ///
    /// For k=0, delegates to `standardCode` and remaps the result to DW conventions
    /// (royal flush → naturalRoyalFlush; pair/two-pair → noWin).
    @inline(__always)
    static func deucesWildCode(
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
            let base = standardCode(c0, c1, c2, c3, c4)
            if base == HandResult.royalFlush.rawValue {
                return HandResult.naturalRoyalFlush.rawValue
            }
            // Pair (jacksOrBetter=1) and two-pair (2) don't pay in DW.
            return base <= 2 ? HandResult.noWin.rawValue : base
        }

        // k = 1, 2, or 3: extract natural (non-wild) cards into fixed slots.
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
                if Self.dwCanFormStraightWindow(na0, na1, na2, na3, n: n) {
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
            if Self.dwCanFormStraightWindow(na0, na1, na2, na3, n: n) {
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
    static func dwCanFormStraightWindow(
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
                Self.dwAllInWheelRange(na0, na1, na2, na3, n: n, lo: lo)
            if nonAceOK {
                return true
            }
        }
        return false
    }

    /// Returns true when all non-ace natural ranks (rank_idx != 12) are in [1, 3].
    @inline(__always)
    static func dwAllInWheelRange(
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
