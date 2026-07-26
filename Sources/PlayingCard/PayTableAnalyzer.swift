/// Computes exact return-to-player percentages for a `PayTable` under optimal play.
///
/// Implements the "One Second Program" technique described at
/// https://wizardofodds.com/games/video-poker/methodology/, applied end to end: every
/// one of the `C(52, 5) = 2,598,960` possible 5-card starting hands is evaluated, and
/// for each, all 32 possible hold subsets are scored via `HandOutcomeArrays`'s
/// precomputed outcome-count arrays via a Möbius (subset-sum) transform (no
/// draw-completion enumeration, no per-hold or per-subset heap allocation). The best-EV
/// hold for each starting hand is exactly the play a perfect-strategy player would
/// make; averaging that best EV across all starting hands gives the pay table's exact
/// overall return. Matches WoO's claimed timing: ~1.5s in a Release build.
///
/// This exists to compute the return percentage of a pay table the app doesn't already
/// know the answer for, such as a user-entered custom pay table in the planned iPhone
/// pay table editor, without falling back to a much slower Monte Carlo estimate.
/// `PayTableAnalyzerTests` cross-checks its output against the published return
/// percentages for this library's existing pay tables.
public enum PayTableAnalyzer {
    /// Number of possible draw completions for holding exactly `k` cards, indexed by
    /// `k` (0...5): `C(47, 5 - k)`, since the draw pool always excludes the 5 originally
    /// dealt cards regardless of which of them are held.
    private static let completionsForHoldSize: [Int] = (0 ... 5).map { CombinatorialIndex.choose(47, 5 - $0) }

    /// The overall return to player for `payTable` under exact optimal play, as a
    /// fraction of the amount bet (for example `0.995439` for 99.5439%).
    ///
    /// This is a one-time, relatively expensive pass, see `PayTableAnalyzerTests` for
    /// measured timing. It builds a fresh `HandOutcomeArrays` for `payTable`'s
    /// wildcard mode internally; computing returns for many pay tables that share a
    /// wildcard mode currently repeats that build per call, since `HandOutcomeArrays`
    /// is an internal implementation detail of this library, not part of its public
    /// API.
    public static func overallReturn(payTable: PayTable) -> Double {
        precondition(
            payTable.wildcardRank == nil || payTable.wildcardRank == .two,
            "PayTableAnalyzer only supports wildcardRank == .two (Deuces Wild). "
                + "The fast evaluator hard-codes rank-index 0 for wild detection.",
        )
        let arrays = HandOutcomeArrays.build(wildcardRank: payTable.wildcardRank)
        let multipliers = HandResult.allCases.map { Double(payTable.multiplier(for: $0)) }

        var totalEV = 0.0
        var handCount = 0

        // Scratch buffers reused across all 2,598,960 hands: `payoutOfSubset[mask]` is
        // the total payout for holding exactly the cards `mask` selects (before
        // correcting for the other 4 dealt cards), and `numeratorForHold[mask]` is the
        // inclusion-exclusion-corrected EV numerator for actually holding `mask`.
        // Allocating these once and mutating in place, instead of building fresh
        // arrays per hand, is most of what makes this loop fast: an earlier version
        // built on `HandOutcomeArrays.outcomeCounts` (which allocates per call)
        // measured roughly two orders of magnitude slower.
        var payoutOfSubset = [Double](repeating: 0, count: 32)
        var numeratorForHold = [Double](repeating: 0, count: 32)

        multipliers.withUnsafeBufferPointer { multipliersBuf in
            let multipliersPtr = multipliersBuf.baseAddress!
            payoutOfSubset.withUnsafeMutableBufferPointer { payoutBuf in
                let payoutPtr = payoutBuf.baseAddress!
                numeratorForHold.withUnsafeMutableBufferPointer { numeratorBuf in
                    let numeratorPtr = numeratorBuf.baseAddress!
                    CombinatorialIndex.withChooseTablePointer { choosePtr in
                        arrays.withUnsafePointers { scorePtr, counts4Ptr, counts3Ptr, counts2Ptr, counts1Ptr, counts0Ptr in
                            // swiftlint:disable identifier_name
                            for c0 in 0 ..< 52 {
                                for c1 in (c0 + 1) ..< 52 {
                                    for c2 in (c1 + 1) ..< 52 {
                                        for c3 in (c2 + 1) ..< 52 {
                                            for c4 in (c3 + 1) ..< 52 {
                                                let cards = (c0, c1, c2, c3, c4)
                                                totalEV += bestHoldEV(
                                                    cards: cards,
                                                    arrays: arrays,
                                                    multipliers: multipliersPtr,
                                                    chooseTablePtr: choosePtr,
                                                    scoreForFiveCardHandPtr: scorePtr,
                                                    countsForFourHeldPtr: counts4Ptr,
                                                    countsForThreeHeldPtr: counts3Ptr,
                                                    countsForTwoHeldPtr: counts2Ptr,
                                                    countsForOneHeldPtr: counts1Ptr,
                                                    countsForNoneHeldPtr: counts0Ptr,
                                                    payoutOfSubset: payoutPtr,
                                                    numeratorForHold: numeratorPtr,
                                                )
                                                handCount += 1
                                            }
                                        }
                                    }
                                }
                            }
                            // swiftlint:enable identifier_name
                        }
                    }
                }
            }
        }

        return totalEV / Double(handCount)
    }

    // swiftlint:disable large_tuple function_parameter_count
    /// Evaluates all 32 possible hold subsets of a dealt hand and returns the highest
    /// expected value: the return-per-unit-bet a perfect-strategy player would get by
    /// holding whichever subset maximizes EV.
    ///
    /// Uses the same inclusion-exclusion identity as `HandOutcomeArrays.outcomeCounts`
    /// (for held set `H`, `EV(H) = Σ_{T ⊇ H} (-1)^|T∖H| * payout(T) / completions(H)`),
    /// but restructured as a single subset-sum (Möbius) transform over all 32 subsets
    /// of the 5 dealt cards, computed with fixed-size scratch buffers instead of
    /// per-hold, per-discard-subset array allocation.
    private static func bestHoldEV(
        cards: (Int, Int, Int, Int, Int),
        arrays: HandOutcomeArrays,
        multipliers: UnsafePointer<Double>,
        chooseTablePtr: UnsafePointer<Int>,
        scoreForFiveCardHandPtr: UnsafePointer<UInt8>,
        countsForFourHeldPtr: UnsafePointer<Int32>,
        countsForThreeHeldPtr: UnsafePointer<Int32>,
        countsForTwoHeldPtr: UnsafePointer<Int32>,
        countsForOneHeldPtr: UnsafePointer<Int32>,
        countsForNoneHeldPtr: UnsafePointer<Int32>,
        payoutOfSubset: UnsafeMutablePointer<Double>,
        numeratorForHold: UnsafeMutablePointer<Double>,
    ) -> Double {
        for mask in 0 ..< 32 {
            payoutOfSubset[mask] = arrays.payout(
                forSubsetMask: mask,
                cards: cards,
                multipliers: multipliers,
                chooseTablePtr: chooseTablePtr,
                scoreForFiveCardHandPtr: scoreForFiveCardHandPtr,
                countsForFourHeldPtr: countsForFourHeldPtr,
                countsForThreeHeldPtr: countsForThreeHeldPtr,
                countsForTwoHeldPtr: countsForTwoHeldPtr,
                countsForOneHeldPtr: countsForOneHeldPtr,
                countsForNoneHeldPtr: countsForNoneHeldPtr,
            )
            numeratorForHold[mask] = 0
        }

        // For every pair (hold, superset) with hold ⊆ superset, the superset's raw
        // payout contributes to the hold's EV numerator with sign (-1)^|superset∖hold|.
        // Enumerating subsets of each superset via the standard `(s - 1) & superset`
        // bit trick visits exactly the 3^5 = 243 such pairs, with no allocation.
        for supersetMask in 0 ..< 32 {
            let payout = payoutOfSubset[supersetMask]
            var holdMask = supersetMask
            while true {
                let discardedFromSuperset = (supersetMask & ~holdMask).nonzeroBitCount
                let sign = discardedFromSuperset.isMultiple(of: 2) ? 1.0 : -1.0
                numeratorForHold[holdMask] += sign * payout
                if holdMask == 0 {
                    break
                }
                holdMask = (holdMask - 1) & supersetMask
            }
        }

        var best = 0.0
        for holdMask in 0 ..< 32 {
            let completions = completionsForHoldSize[holdMask.nonzeroBitCount]
            best = max(best, numeratorForHold[holdMask] / Double(completions))
        }
        return best
    }

    // swiftlint:enable large_tuple
}
