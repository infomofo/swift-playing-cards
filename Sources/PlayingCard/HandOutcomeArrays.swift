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
    /// Stride of the flattened choose table, matching `CombinatorialIndex`'s
    /// `maxK + 1` layout.
    private static let chooseTableStride = 6

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
    /// This is a one-time, relatively expensive pass, see `HandOutcomeArraysTests`
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

        // ⚡ Bolt Optimization: Wrap mutating arrays in UnsafeMutableBufferPointer closures
        // and extract their raw base address pointers. This completely bypasses all array
        // bounds checking overhead (83 million writes) inside the tight 5-nested loops.
        scoreForFiveCardHand.withUnsafeMutableBufferPointer { scoreBuf in
            let scorePtr = scoreBuf.baseAddress!
            countsForFourHeld.withUnsafeMutableBufferPointer { c4Buf in
                let c4Ptr = c4Buf.baseAddress!
                countsForThreeHeld.withUnsafeMutableBufferPointer { c3Buf in
                    let c3Ptr = c3Buf.baseAddress!
                    countsForTwoHeld.withUnsafeMutableBufferPointer { c2Buf in
                        let c2Ptr = c2Buf.baseAddress!
                        countsForOneHeld.withUnsafeMutableBufferPointer { c1Buf in
                            let c1Ptr = c1Buf.baseAddress!
                            countsForNoneHeld.withUnsafeMutableBufferPointer { c0Buf in
                                let c0Ptr = c0Buf.baseAddress!
                                CombinatorialIndex.withChooseTablePointer { choosePtr in
                                    for c0 in 0 ..< 52 {
                                        let chooseC0_1 = choosePtr[c0 * Self.chooseTableStride + 1]
                                        let c0_n_mul = chooseC0_1 * n
                                        let c0_mul_n = c0 * n
                                        for c1 in (c0 + 1) ..< 52 {
                                            let chooseC1_1 = choosePtr[c1 * Self.chooseTableStride + 1]
                                            let chooseC1_2 = choosePtr[c1 * Self.chooseTableStride + 2]
                                            let c1_n_mul = chooseC1_1 * n
                                            let c1_mul_n = c1 * n
                                            let pair_0_1 = (chooseC0_1 + chooseC1_2) * n
                                            for c2 in (c1 + 1) ..< 52 {
                                                let chooseC2_1 = choosePtr[c2 * Self.chooseTableStride + 1]
                                                let chooseC2_2 = choosePtr[c2 * Self.chooseTableStride + 2]
                                                let chooseC2_3 = choosePtr[c2 * Self.chooseTableStride + 3]
                                                let c2_n_mul = chooseC2_1 * n
                                                let c2_mul_n = c2 * n
                                                let pair_0_2 = (chooseC0_1 + chooseC2_2) * n
                                                let pair_1_2 = (chooseC1_1 + chooseC2_2) * n
                                                let triple_0_1_2 = (chooseC0_1 + chooseC1_2 + chooseC2_3) * n
                                                for c3 in (c2 + 1) ..< 52 {
                                                    let chooseC3_1 = choosePtr[c3 * Self.chooseTableStride + 1]
                                                    let chooseC3_2 = choosePtr[c3 * Self.chooseTableStride + 2]
                                                    let chooseC3_3 = choosePtr[c3 * Self.chooseTableStride + 3]
                                                    let chooseC3_4 = choosePtr[c3 * Self.chooseTableStride + 4]
                                                    let c3_n_mul = chooseC3_1 * n
                                                    let c3_mul_n = c3 * n
                                                    let pair_0_3 = (chooseC0_1 + chooseC3_2) * n
                                                    let pair_1_3 = (chooseC1_1 + chooseC3_2) * n
                                                    let pair_2_3 = (chooseC2_1 + chooseC3_2) * n
                                                    let triple_0_1_3 = (chooseC0_1 + chooseC1_2 +
                                                        chooseC3_3) * n
                                                    let triple_0_2_3 = (chooseC0_1 + chooseC2_2 +
                                                        chooseC3_3) * n
                                                    let triple_1_2_3 = (chooseC1_1 + chooseC2_2 +
                                                        chooseC3_3) * n
                                                    let idx4_4_mul_n = (chooseC0_1 + chooseC1_2 +
                                                        chooseC2_3 + chooseC3_4) * n
                                                    let sum_c0_c1_c2_c3_5 = chooseC0_1 + chooseC1_2 +
                                                        chooseC2_3 + chooseC3_4
                                                    for c4 in (c3 + 1) ..< 52 {
                                                        let score = isWild
                                                            ? FastHandEvaluator.deucesWildCode(c0, c1, c2, c3, c4)
                                                            : FastHandEvaluator.standardCode(c0, c1, c2, c3, c4)

                                                        let chooseC4_2 = choosePtr[c4 * Self.chooseTableStride + 2]
                                                        let chooseC4_3 = choosePtr[c4 * Self.chooseTableStride + 3]
                                                        let chooseC4_4 = choosePtr[c4 * Self.chooseTableStride + 4]
                                                        let chooseC4_5 = choosePtr[c4 * Self.chooseTableStride + 5]

                                                        let index5 = sum_c0_c1_c2_c3_5 + chooseC4_5
                                                        scorePtr[index5] = UInt8(score)
                                                        c0Ptr[score] += 1

                                                        let chooseC4_4_mul_n = chooseC4_4 * n

                                                        // countsForFourHeld (exclude exactly one card)
                                                        // Exclude c0: c1, c2, c3, c4
                                                        c4Ptr[triple_1_2_3 + chooseC4_4_mul_n + score] += 1

                                                        // Exclude c1: c0, c2, c3, c4
                                                        c4Ptr[triple_0_2_3 + chooseC4_4_mul_n + score] += 1

                                                        // Exclude c2: c0, c1, c3, c4
                                                        c4Ptr[triple_0_1_3 + chooseC4_4_mul_n + score] += 1

                                                        // Exclude c3: c0, c1, c2, c4
                                                        c4Ptr[triple_0_1_2 + chooseC4_4_mul_n + score] += 1

                                                        // Exclude c4: c0, c1, c2, c3
                                                        c4Ptr[idx4_4_mul_n + score] += 1

                                                        let chooseC4_2_mul_n = chooseC4_2 * n

                                                        // countsForTwoHeld (all 10 pairs)
                                                        c2Ptr[pair_0_1 + score] += 1
                                                        c2Ptr[pair_0_2 + score] += 1
                                                        c2Ptr[pair_0_3 + score] += 1
                                                        c2Ptr[c0_n_mul + chooseC4_2_mul_n + score] += 1
                                                        c2Ptr[pair_1_2 + score] += 1
                                                        c2Ptr[pair_1_3 + score] += 1
                                                        c2Ptr[c1_n_mul + chooseC4_2_mul_n + score] += 1
                                                        c2Ptr[pair_2_3 + score] += 1
                                                        c2Ptr[c2_n_mul + chooseC4_2_mul_n + score] += 1
                                                        c2Ptr[c3_n_mul + chooseC4_2_mul_n + score] += 1

                                                        let chooseC4_3_mul_n = chooseC4_3 * n

                                                        // countsForThreeHeld (all 10 triples)
                                                        c3Ptr[triple_0_1_2 + score] += 1
                                                        c3Ptr[triple_0_1_3 + score] += 1
                                                        c3Ptr[pair_0_1 + chooseC4_3_mul_n + score] += 1
                                                        c3Ptr[triple_0_2_3 + score] += 1
                                                        c3Ptr[pair_0_2 + chooseC4_3_mul_n + score] += 1
                                                        c3Ptr[pair_0_3 + chooseC4_3_mul_n + score] += 1
                                                        c3Ptr[triple_1_2_3 + score] += 1
                                                        c3Ptr[pair_1_2 + chooseC4_3_mul_n + score] += 1
                                                        c3Ptr[pair_1_3 + chooseC4_3_mul_n + score] += 1
                                                        c3Ptr[pair_2_3 + chooseC4_3_mul_n + score] += 1

                                                        // countsForOneHeld
                                                        c1Ptr[c0_mul_n + score] += 1
                                                        c1Ptr[c1_mul_n + score] += 1
                                                        c1Ptr[c2_mul_n + score] += 1
                                                        c1Ptr[c3_mul_n + score] += 1
                                                        c1Ptr[c4 * n + score] += 1
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
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
        let combined = Set(held + discarded)
        precondition(
            combined.count == held.count + discarded.count,
            "held and discarded must be disjoint and each contain no duplicate cards",
        )
        precondition(combined.allSatisfy { (0 ..< 52).contains($0) }, "held and discarded must contain valid card codes (0..<52)")
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

    // swiftlint:disable large_tuple cyclomatic_complexity
    /// Returns the total payout (`Σ count * multiplier`) for the count row addressed by
    /// a specific subset of a 5-card hand, without materializing an intermediate row
    /// array or a subset-cards array.
    ///
    /// `mask`'s bit `i` selects `cards`'s element `i` (`cards.0` for bit 0, `cards.4`
    /// for bit 4); `cards` must be in ascending order, matching every other
    /// subset-index computation in this type. `multipliers` must have `resultCount`
    /// entries, indexed by `HandResult.rawValue`.
    ///
    /// This is the hot-path counterpart to `outcomeCounts`/`rowCounts`:
    /// `PayTableAnalyzer` calls this on the order of a few hundred million times per
    /// pay table (2,598,960 hands times up to 32 subsets each), so avoiding per-call
    /// heap allocation is what makes that computation tractable. A first
    /// implementation built on `outcomeCounts` directly measured at roughly two orders
    /// of magnitude slower, entirely from Array allocation/ARC overhead, not from the
    /// combinatorial-index arithmetic itself.
    func payout(forSubsetMask mask: Int, cards: (Int, Int, Int, Int, Int), multipliers: [Double]) -> Double {
        var index = 0
        var position = 0
        if mask & 0b00001 != 0 {
            position += 1; index += CombinatorialIndex.choose(cards.0, position)
        }
        if mask & 0b00010 != 0 {
            position += 1; index += CombinatorialIndex.choose(cards.1, position)
        }
        if mask & 0b00100 != 0 {
            position += 1; index += CombinatorialIndex.choose(cards.2, position)
        }
        if mask & 0b01000 != 0 {
            position += 1; index += CombinatorialIndex.choose(cards.3, position)
        }
        if mask & 0b10000 != 0 {
            position += 1; index += CombinatorialIndex.choose(cards.4, position)
        }

        switch position {
        case 5: return multipliers[Int(scoreForFiveCardHand[index])]
        case 4: return dotProduct(countsForFourHeld, rowIndex: index, multipliers: multipliers)
        case 3: return dotProduct(countsForThreeHeld, rowIndex: index, multipliers: multipliers)
        case 2: return dotProduct(countsForTwoHeld, rowIndex: index, multipliers: multipliers)
        case 1: return dotProduct(countsForOneHeld, rowIndex: index, multipliers: multipliers)
        default: return dotProduct(countsForNoneHeld, rowIndex: 0, multipliers: multipliers)
        }
    }

    // swiftlint:enable large_tuple cyclomatic_complexity

    private func dotProduct(_ flat: [Int32], rowIndex: Int, multipliers: [Double]) -> Double {
        let start = rowIndex * Self.resultCount
        if Self.resultCount == 14 {
            return Double(flat[start + 0]) * multipliers[0]
                + Double(flat[start + 1]) * multipliers[1]
                + Double(flat[start + 2]) * multipliers[2]
                + Double(flat[start + 3]) * multipliers[3]
                + Double(flat[start + 4]) * multipliers[4]
                + Double(flat[start + 5]) * multipliers[5]
                + Double(flat[start + 6]) * multipliers[6]
                + Double(flat[start + 7]) * multipliers[7]
                + Double(flat[start + 8]) * multipliers[8]
                + Double(flat[start + 9]) * multipliers[9]
                + Double(flat[start + 10]) * multipliers[10]
                + Double(flat[start + 11]) * multipliers[11]
                + Double(flat[start + 12]) * multipliers[12]
                + Double(flat[start + 13]) * multipliers[13]
        } else {
            var sum = 0.0
            for resultIndex in 0 ..< Self.resultCount {
                sum += Double(flat[start + resultIndex]) * multipliers[resultIndex]
            }
            return sum
        }
    }

    // swiftformat:disable trailingCommas
    // swiftlint:disable identifier_name
    /// Exposes underlying array buffers as raw unsafe pointers in a flat monadic scope
    /// to avoid nesting buffer pointer lookups in tight loops.
    func withUnsafePointers<R>(
        _ body: (
            _ scoreForFiveCardHandPtr: UnsafePointer<UInt8>,
            _ countsForFourHeldPtr: UnsafePointer<Int32>,
            _ countsForThreeHeldPtr: UnsafePointer<Int32>,
            _ countsForTwoHeldPtr: UnsafePointer<Int32>,
            _ countsForOneHeldPtr: UnsafePointer<Int32>,
            _ countsForNoneHeldPtr: UnsafePointer<Int32>
        ) -> R
    ) -> R {
        scoreForFiveCardHand.withUnsafeBufferPointer { b5 in
            countsForFourHeld.withUnsafeBufferPointer { b4 in
                countsForThreeHeld.withUnsafeBufferPointer { b3 in
                    countsForTwoHeld.withUnsafeBufferPointer { b2 in
                        countsForOneHeld.withUnsafeBufferPointer { b1 in
                            countsForNoneHeld.withUnsafeBufferPointer { b0 in
                                body(
                                    b5.baseAddress!,
                                    b4.baseAddress!,
                                    b3.baseAddress!,
                                    b2.baseAddress!,
                                    b1.baseAddress!,
                                    b0.baseAddress!
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // swiftlint:enable identifier_name

    // swiftlint:disable large_tuple cyclomatic_complexity function_parameter_count
    /// High-performance overload of payout that uses UnsafePointers to avoid array bounds checking.
    @inline(__always)
    func payout(
        forSubsetMask mask: Int,
        cards: (Int, Int, Int, Int, Int),
        multipliers: UnsafePointer<Double>,
        chooseTablePtr: UnsafePointer<Int>,
        scoreForFiveCardHandPtr: UnsafePointer<UInt8>,
        countsForFourHeldPtr: UnsafePointer<Int32>,
        countsForThreeHeldPtr: UnsafePointer<Int32>,
        countsForTwoHeldPtr: UnsafePointer<Int32>,
        countsForOneHeldPtr: UnsafePointer<Int32>,
        countsForNoneHeldPtr: UnsafePointer<Int32>
    ) -> Double {
        // swiftformat:enable trailingCommas
        var index = 0
        var position = 0
        if mask & 0b00001 != 0 {
            position += 1; index += chooseTablePtr[cards.0 * Self.chooseTableStride + position]
        }
        if mask & 0b00010 != 0 {
            position += 1; index += chooseTablePtr[cards.1 * Self.chooseTableStride + position]
        }
        if mask & 0b00100 != 0 {
            position += 1; index += chooseTablePtr[cards.2 * Self.chooseTableStride + position]
        }
        if mask & 0b01000 != 0 {
            position += 1; index += chooseTablePtr[cards.3 * Self.chooseTableStride + position]
        }
        if mask & 0b10000 != 0 {
            position += 1; index += chooseTablePtr[cards.4 * Self.chooseTableStride + position]
        }

        switch position {
        case 5: return multipliers[Int(scoreForFiveCardHandPtr[index])]
        case 4: return dotProduct(countsForFourHeldPtr, rowIndex: index, multipliers: multipliers)
        case 3: return dotProduct(countsForThreeHeldPtr, rowIndex: index, multipliers: multipliers)
        case 2: return dotProduct(countsForTwoHeldPtr, rowIndex: index, multipliers: multipliers)
        case 1: return dotProduct(countsForOneHeldPtr, rowIndex: index, multipliers: multipliers)
        default: return dotProduct(countsForNoneHeldPtr, rowIndex: 0, multipliers: multipliers)
        }
    }

    // swiftlint:enable large_tuple cyclomatic_complexity

    @inline(__always)
    private func dotProduct(_ flat: UnsafePointer<Int32>, rowIndex: Int, multipliers: UnsafePointer<Double>) -> Double {
        let start = rowIndex * Self.resultCount
        if Self.resultCount == 14 {
            return Double(flat[start + 0]) * multipliers[0]
                + Double(flat[start + 1]) * multipliers[1]
                + Double(flat[start + 2]) * multipliers[2]
                + Double(flat[start + 3]) * multipliers[3]
                + Double(flat[start + 4]) * multipliers[4]
                + Double(flat[start + 5]) * multipliers[5]
                + Double(flat[start + 6]) * multipliers[6]
                + Double(flat[start + 7]) * multipliers[7]
                + Double(flat[start + 8]) * multipliers[8]
                + Double(flat[start + 9]) * multipliers[9]
                + Double(flat[start + 10]) * multipliers[10]
                + Double(flat[start + 11]) * multipliers[11]
                + Double(flat[start + 12]) * multipliers[12]
                + Double(flat[start + 13]) * multipliers[13]
        } else {
            var sum = 0.0
            for resultIndex in 0 ..< Self.resultCount {
                sum += Double(flat[start + resultIndex]) * multipliers[resultIndex]
            }
            return sum
        }
    }
}
