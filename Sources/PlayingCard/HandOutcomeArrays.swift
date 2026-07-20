/// Precomputed hand-outcome counts for one wildcard mode (standard/no-wild evaluation,
/// or Deuces-Wild-style evaluation), built once by scoring every one of the 2,598,960
/// possible 5-card hands exactly once.
///
/// Implements the "One Second Program" technique described at
/// https://wizardofodds.com/games/video-poker/methodology/: rather than re-enumerating
/// every possible draw completion for a specific dealt hand (as `OptimalPlay.fastEV`
/// does, looping up to `C(47, 5) = 1,533,939` times for the worst case), every one of
/// the 2,598,960 raw 5-card hands is scored exactly once here, and the draw-outcome
/// distribution for any specific hold on any specific dealt hand is later derived from
/// these arrays via inclusion-exclusion (`outcomeCounts(held:discarded:)`), with no
/// per-hand re-enumeration of draw completions.
///
/// This is a standalone building block: nothing in `OptimalPlay`'s live per-hand hot
/// path uses it yet. It exists to support `PayTableAnalyzer`'s exact whole-pay-table RTP
/// computation, and as a spike for a possible future `OptimalPlay` fast path once
/// benchmarked against the existing direct-enumeration approach.
struct HandOutcomeArrays {
    /// Number of distinct `HandResult` cases. Every count row has this many columns,
    /// indexed by `HandResult.rawValue`.
    static let resultCount = HandResult.allCases.count

    /// Hand-result score for each of the `C(52, 5)` possible 5-card hands, indexed by
    /// `CombinatorialIndex.index(sortedCards:)` of the 5 sorted card codes. One entry
    /// per hand, since holding all 5 cards has a single, deterministic outcome (no
    /// cards are drawn).
    let scoreForFiveCardHand: [UInt8]

    /// Flattened score-count table for held 4-card subsets. Row `i` (of `C(52, 4)` rows,
    /// stride `resultCount`) holds, for each `HandResult.rawValue`, how many of the 48
    /// cards not in that 4-card subset would produce that result as the 5th card.
    let countsForFourHeld: [Int32]

    /// Same shape as `countsForFourHeld`, for held 3-card subsets (`C(52, 3)` rows, over
    /// the `C(49, 2)` possible pairs completing the hand).
    let countsForThreeHeld: [Int32]

    /// Same shape, for held 2-card subsets (`C(52, 2)` rows, over `C(50, 3)` completions).
    let countsForTwoHeld: [Int32]

    /// Same shape, for held 1-card subsets (52 rows, over `C(51, 4)` completions).
    let countsForOneHeld: [Int32]

    /// Same shape, a single row: the score-count distribution over all `C(52, 5)` hands
    /// when holding no cards at all.
    let countsForNoneHeld: [Int32]

    // swiftlint:disable identifier_name function_body_length
    /// Scores every one of the `C(52, 5) = 2,598,960` possible 5-card hands exactly
    /// once, and buckets the result into the six count arrays above.
    ///
    /// This is a one-time, relatively expensive pass — see `HandOutcomeArraysTests`
    /// for measured timing. Callers should build once per wildcard mode and reuse the
    /// result rather than rebuilding per hand.
    ///
    /// - Parameter wildcardRank: `nil` for standard (Jacks-or-Better-style) evaluation,
    ///   or `.two` for Deuces-Wild-style evaluation. Matches the same restriction as
    ///   `OptimalPlay`, since the fast evaluators hard-code rank-index 0 for wild
    ///   detection.
    static func build(wildcardRank: Rank?) -> HandOutcomeArrays {
        precondition(
            wildcardRank == nil || wildcardRank == .two,
            "HandOutcomeArrays only supports wildcardRank == .two (Deuces Wild). "
                + "The fast evaluators hard-code rank-index 0 for wild detection.",
        )
        let isWild = wildcardRank != nil
        let n = resultCount

        var scoreForFiveCardHand = [UInt8](repeating: 0, count: CombinatorialIndex.choose(52, 5))
        var countsForFourHeld = [Int32](repeating: 0, count: CombinatorialIndex.choose(52, 4) * n)
        var countsForThreeHeld = [Int32](repeating: 0, count: CombinatorialIndex.choose(52, 3) * n)
        var countsForTwoHeld = [Int32](repeating: 0, count: CombinatorialIndex.choose(52, 2) * n)
        var countsForOneHeld = [Int32](repeating: 0, count: 52 * n)
        var countsForNoneHeld = [Int32](repeating: 0, count: n)

        for c0 in 0 ..< 52 {
            for c1 in (c0 + 1) ..< 52 {
                for c2 in (c1 + 1) ..< 52 {
                    for c3 in (c2 + 1) ..< 52 {
                        for c4 in (c3 + 1) ..< 52 {
                            let score = isWild
                                ? FastHandEvaluator.deucesWildCode(c0, c1, c2, c3, c4)
                                : FastHandEvaluator.standardCode(c0, c1, c2, c3, c4)

                            let cards = [c0, c1, c2, c3, c4]
                            let index5 = CombinatorialIndex.index(sortedCards: cards)
                            scoreForFiveCardHand[index5] = UInt8(score)
                            countsForNoneHeld[score] += 1

                            for excluded in 0 ..< 5 {
                                var four = cards
                                four.remove(at: excluded)
                                let idx4 = CombinatorialIndex.index(sortedCards: four)
                                countsForFourHeld[idx4 * n + score] += 1
                            }

                            for i in 0 ..< 5 {
                                for j in (i + 1) ..< 5 {
                                    let two = [cards[i], cards[j]]
                                    let idx2 = CombinatorialIndex.index(sortedCards: two)
                                    countsForTwoHeld[idx2 * n + score] += 1

                                    for k in (j + 1) ..< 5 {
                                        let three = [cards[i], cards[j], cards[k]]
                                        let idx3 = CombinatorialIndex.index(sortedCards: three)
                                        countsForThreeHeld[idx3 * n + score] += 1
                                    }
                                }
                            }

                            for card in cards {
                                countsForOneHeld[card * n + score] += 1
                            }
                        }
                    }
                }
            }
        }

        return HandOutcomeArrays(
            scoreForFiveCardHand: scoreForFiveCardHand,
            countsForFourHeld: countsForFourHeld,
            countsForThreeHeld: countsForThreeHeld,
            countsForTwoHeld: countsForTwoHeld,
            countsForOneHeld: countsForOneHeld,
            countsForNoneHeld: countsForNoneHeld,
        )
    }

    // swiftlint:enable identifier_name function_body_length

    // swiftlint:disable identifier_name
    /// Derives the `HandResult`-bucketed outcome-count distribution for holding exactly
    /// `held` from a specific dealt hand, permanently discarding `discarded` (the
    /// other cards in that hand), via inclusion-exclusion over the discard set.
    ///
    /// `held` and `discarded` together must be exactly the 5 dealt cards (any card
    /// codes, in any order) with no overlap. The returned array has `resultCount`
    /// entries, indexed by `HandResult.rawValue`; entry `i` is the number of ways to
    /// complete the hand (by drawing replacements for `discarded` from the remaining
    /// 47-card deck) that produce `HandResult(rawValue: i)`.
    ///
    /// Uses the general inclusion-exclusion identity: for held set `H` and discard set
    /// `D`, the true outcome distribution for holding exactly `H` is
    /// `sum over subsets S of D of (-1)^|S| * rawCounts(H union S)`, where `rawCounts`
    /// looks up the precomputed array matching `|H union S|` (5, 4, 3, 2, 1, or 0 cards
    /// held). This generalizes the specific hold=4/3/2/1/0 formulas from the WoO
    /// methodology page into one recursive rule, since each precomputed array
    /// (`countsForFourHeld`, etc.) was built assuming no cards are excluded from the
    /// draw pool, and must have every specific discarded card's contribution subtracted
    /// (or added back, for even-sized subsets) to correct for that.
    func outcomeCounts(held: [Int], discarded: [Int]) -> [Int] {
        precondition(held.count + discarded.count == 5, "held and discarded must total 5 cards")
        var totals = [Int](repeating: 0, count: Self.resultCount)

        for subsetMask in 0 ..< (1 << discarded.count) {
            var subset: [Int] = []
            for bit in 0 ..< discarded.count where subsetMask & (1 << bit) != 0 {
                subset.append(discarded[bit])
            }
            let sign = subset.count.isMultiple(of: 2) ? 1 : -1
            let combined = (held + subset).sorted()
            let row = rowCounts(forSortedCards: combined)
            for i in 0 ..< Self.resultCount {
                totals[i] += sign * row[i]
            }
        }
        return totals
    }

    // swiftlint:enable identifier_name

    /// Returns the `resultCount`-wide count row for a specific sorted set of held
    /// cards, dispatching to whichever precomputed array matches its size.
    private func rowCounts(forSortedCards combined: [Int]) -> [Int] {
        switch combined.count {
        case 5:
            var row = [Int](repeating: 0, count: Self.resultCount)
            let index = CombinatorialIndex.index(sortedCards: combined)
            row[Int(scoreForFiveCardHand[index])] = 1
            return row
        case 4:
            return extractRow(countsForFourHeld, index: CombinatorialIndex.index(sortedCards: combined))
        case 3:
            return extractRow(countsForThreeHeld, index: CombinatorialIndex.index(sortedCards: combined))
        case 2:
            return extractRow(countsForTwoHeld, index: CombinatorialIndex.index(sortedCards: combined))
        case 1:
            return extractRow(countsForOneHeld, index: CombinatorialIndex.index(sortedCards: combined))
        case 0:
            return countsForNoneHeld.map(Int.init)
        default:
            preconditionFailure("combined held+subset count must be 0–5, got \(combined.count)")
        }
    }

    private func extractRow(_ flat: [Int32], index: Int) -> [Int] {
        let start = index * Self.resultCount
        return (0 ..< Self.resultCount).map { Int(flat[start + $0]) }
    }
}
