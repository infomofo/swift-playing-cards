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
    /// Precomputed reciprocals of completion counts indexed directly by `holdMask` (0...31)
    /// to eliminate `nonzeroBitCount` instruction calls in hot EV loops.
    private static let reciprocalForHoldMask: [Double] = (0 ..< 32).map {
        1.0 / Double(CombinatorialIndex.choose(47, 5 - $0.nonzeroBitCount))
    }

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
        // correcting for the other 4 dealt cards).
        // Allocating this once and mutating in place, instead of building fresh
        // arrays per hand, is most of what makes this loop fast: an earlier version
        // built on `HandOutcomeArrays.outcomeCounts` (which allocates per call)
        // measured roughly two orders of magnitude slower.
        var payoutOfSubset = [Double](repeating: 0, count: 32)

        reciprocalForHoldMask.withUnsafeBufferPointer { reciprocalBuf in
            let reciprocalPtr = reciprocalBuf.baseAddress!
            multipliers.withUnsafeBufferPointer { multipliersBuf in
                let multipliersPtr = multipliersBuf.baseAddress!
                payoutOfSubset.withUnsafeMutableBufferPointer { payoutBuf in
                    let payoutPtr = payoutBuf.baseAddress!
                    CombinatorialIndex.withChooseTablePointer { choosePtr in
                        arrays.withUnsafePointers { scorePtr, counts4Ptr, counts3Ptr, counts2Ptr, counts1Ptr, counts0Ptr in
                            let stride = HandOutcomeArrays.chooseTableStride
                            // swiftlint:disable identifier_name
                            for c0 in 0 ..< 52 {
                                let r0 = choosePtr + c0 * stride
                                for c1 in (c0 + 1) ..< 52 {
                                    let r1 = choosePtr + c1 * stride
                                    for c2 in (c1 + 1) ..< 52 {
                                        let r2 = choosePtr + c2 * stride
                                        for c3 in (c2 + 1) ..< 52 {
                                            let r3 = choosePtr + c3 * stride
                                            for c4 in (c3 + 1) ..< 52 {
                                                let r4 = choosePtr + c4 * stride
                                                let cardRows = (r0, r1, r2, r3, r4)
                                                totalEV += bestHoldEV(
                                                    cardRows: cardRows,
                                                    arrays: arrays,
                                                    multipliers: multipliersPtr,
                                                    scoreForFiveCardHandPtr: scorePtr,
                                                    countsForFourHeldPtr: counts4Ptr,
                                                    countsForThreeHeldPtr: counts3Ptr,
                                                    countsForTwoHeldPtr: counts2Ptr,
                                                    countsForOneHeldPtr: counts1Ptr,
                                                    countsForNoneHeldPtr: counts0Ptr,
                                                    payoutOfSubset: payoutPtr,
                                                    reciprocalPtr: reciprocalPtr,
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
    /// Restructured as a single subset-sum Fast Möbius Transform (FMT) over all 32 subsets
    /// of the 5 dealt cards, computed in-place with a single fixed-size scratch buffer.
    /// This reduces complexity from O(3^N) (243 loops) to O(N 2^N) (80 subtractions),
    /// completely bypassing the second scratch buffer and redundant writes.
    @inline(__always)
    private static func bestHoldEV(
        cardRows: (UnsafePointer<Int>, UnsafePointer<Int>, UnsafePointer<Int>, UnsafePointer<Int>, UnsafePointer<Int>),
        arrays: HandOutcomeArrays,
        multipliers: UnsafePointer<Double>,
        scoreForFiveCardHandPtr: UnsafePointer<UInt8>,
        countsForFourHeldPtr: UnsafePointer<Int32>,
        countsForThreeHeldPtr: UnsafePointer<Int32>,
        countsForTwoHeldPtr: UnsafePointer<Int32>,
        countsForOneHeldPtr: UnsafePointer<Int32>,
        countsForNoneHeldPtr: UnsafePointer<Int32>,
        payoutOfSubset: UnsafeMutablePointer<Double>,
        reciprocalPtr: UnsafePointer<Double>,
    ) -> Double {
        for mask in 0 ..< 32 {
            payoutOfSubset[mask] = arrays.payout(
                forSubsetMask: mask,
                cardRows: cardRows,
                multipliers: multipliers,
                scoreForFiveCardHandPtr: scoreForFiveCardHandPtr,
                countsForFourHeldPtr: countsForFourHeldPtr,
                countsForThreeHeldPtr: countsForThreeHeldPtr,
                countsForTwoHeldPtr: countsForTwoHeldPtr,
                countsForOneHeldPtr: countsForOneHeldPtr,
                countsForNoneHeldPtr: countsForNoneHeldPtr,
            )
        }

        // Fast Möbius Transform (FMT) unrolled:
        // Step 0: stepSize 1
        payoutOfSubset[0] -= payoutOfSubset[1]
        payoutOfSubset[2] -= payoutOfSubset[3]
        payoutOfSubset[4] -= payoutOfSubset[5]
        payoutOfSubset[6] -= payoutOfSubset[7]
        payoutOfSubset[8] -= payoutOfSubset[9]
        payoutOfSubset[10] -= payoutOfSubset[11]
        payoutOfSubset[12] -= payoutOfSubset[13]
        payoutOfSubset[14] -= payoutOfSubset[15]
        payoutOfSubset[16] -= payoutOfSubset[17]
        payoutOfSubset[18] -= payoutOfSubset[19]
        payoutOfSubset[20] -= payoutOfSubset[21]
        payoutOfSubset[22] -= payoutOfSubset[23]
        payoutOfSubset[24] -= payoutOfSubset[25]
        payoutOfSubset[26] -= payoutOfSubset[27]
        payoutOfSubset[28] -= payoutOfSubset[29]
        payoutOfSubset[30] -= payoutOfSubset[31]

        // Step 1: stepSize 2
        for baseIdx in stride(from: 0, to: 32, by: 4) {
            payoutOfSubset[baseIdx] -= payoutOfSubset[baseIdx + 2]
            payoutOfSubset[baseIdx + 1] -= payoutOfSubset[baseIdx + 3]
        }

        // Step 2: stepSize 4
        for baseIdx in stride(from: 0, to: 32, by: 8) {
            payoutOfSubset[baseIdx] -= payoutOfSubset[baseIdx + 4]
            payoutOfSubset[baseIdx + 1] -= payoutOfSubset[baseIdx + 5]
            payoutOfSubset[baseIdx + 2] -= payoutOfSubset[baseIdx + 6]
            payoutOfSubset[baseIdx + 3] -= payoutOfSubset[baseIdx + 7]
        }

        // Step 3: stepSize 8
        for baseIdx in stride(from: 0, to: 32, by: 16) {
            for offset in 0 ..< 8 {
                payoutOfSubset[baseIdx + offset] -= payoutOfSubset[baseIdx + 8 + offset]
            }
        }

        // Step 4: stepSize 16
        for offset in 0 ..< 16 {
            payoutOfSubset[offset] -= payoutOfSubset[16 + offset]
        }

        var best = 0.0
        for holdMask in 0 ..< 32 {
            let completionsRecip = reciprocalPtr[holdMask]
            best = max(best, payoutOfSubset[holdMask] * completionsRecip)
        }
        return best
    }

    // swiftlint:enable large_tuple
}
