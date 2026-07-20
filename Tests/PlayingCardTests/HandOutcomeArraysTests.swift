@testable import PlayingCard
import XCTest

/// Validates `HandOutcomeArrays`, the precomputed count-array building block for
/// `PayTableAnalyzer`, against direct brute-force enumeration using the same
/// `FastHandEvaluator` `OptimalPlay` itself uses. This is the correctness gate for the
/// inclusion-exclusion arithmetic described in `HandOutcomeArrays.outcomeCounts`: a
/// sign error there would silently corrupt every derived RTP number, so every hold size
/// (0 through 5) is cross-checked against ground truth for both wildcard modes.
///
/// Skipped by default (opt in with `RUN_SLOW_TESTS=1`): building `HandOutcomeArrays`
/// scores all 2,598,960 possible 5-card hands, which takes ~0.6s per wildcard mode in a
/// Release build but ~70s per mode in the unoptimized Debug build `swift test` uses by
/// default in CI — the same Debug-vs-Release gap documented for `OptimalPlay`'s hot
/// loop. Run locally with `RUN_SLOW_TESTS=1 swift test --filter HandOutcomeArraysTests`,
/// or `swift test -c release --filter HandOutcomeArraysTests` for the fast path.
final class HandOutcomeArraysTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["RUN_SLOW_TESTS"] == "1",
            "Builds all 2,598,960 possible 5-card hands per wildcard mode; opt in with "
                + "RUN_SLOW_TESTS=1 to keep default CI runs fast. See class doc comment.",
        )
    }

    // Building HandOutcomeArrays is a one-time, relatively expensive pass (scores all
    // 2,598,960 possible 5-card hands). Cache one build per wildcard mode and reuse it
    // across every test in this file, instead of rebuilding per test.
    private static let standardArrays = HandOutcomeArrays.build(wildcardRank: nil)
    private static let deucesWildArrays = HandOutcomeArrays.build(wildcardRank: .two)

    // MARK: - Build sanity checks

    func testStandardArraysBuildAndCoverAllHands() {
        let arrays = Self.standardArrays
        XCTAssertEqual(arrays.scoreForFiveCardHand.count, CombinatorialIndex.choose(52, 5))

        let totalHands = arrays.countsForNoneHeld.reduce(0, +)
        XCTAssertEqual(Int(totalHands), CombinatorialIndex.choose(52, 5))
    }

    func testDeucesWildArraysBuildAndCoverAllHands() {
        let arrays = Self.deucesWildArrays
        let totalHands = arrays.countsForNoneHeld.reduce(0, +)
        XCTAssertEqual(Int(totalHands), CombinatorialIndex.choose(52, 5))
    }

    // MARK: - Cross-checks against brute-force enumeration (standard evaluation)

    func testOutcomeCountsMatchesBruteForceForPatHand() {
        assertMatchesBruteForce(
            handCodes: royalFlushCodes,
            heldPositions: [0, 1, 2, 3, 4],
            wildcardRank: nil,
        )
    }

    func testOutcomeCountsMatchesBruteForceForDiscardOne() {
        assertMatchesBruteForce(
            handCodes: royalFlushCodes,
            heldPositions: [0, 1, 2, 3],
            wildcardRank: nil,
        )
    }

    func testOutcomeCountsMatchesBruteForceForDiscardTwo() {
        assertMatchesBruteForce(
            handCodes: twoPairCodes,
            heldPositions: [0, 1, 2],
            wildcardRank: nil,
        )
    }

    func testOutcomeCountsMatchesBruteForceForDiscardThree() {
        assertMatchesBruteForce(
            handCodes: twoPairCodes,
            heldPositions: [0, 1],
            wildcardRank: nil,
        )
    }

    func testOutcomeCountsSumMatchesExpectedComboCountForDiscardFour() {
        assertOutcomeCountsSumMatchesExpectedCombos(
            handCodes: highCardCodes,
            heldPositions: [0],
            wildcardRank: nil,
        )
    }

    func testOutcomeCountsSumMatchesExpectedComboCountForDiscardFive() {
        assertOutcomeCountsSumMatchesExpectedCombos(
            handCodes: highCardCodes,
            heldPositions: [],
            wildcardRank: nil,
        )
    }

    // MARK: - Cross-checks against brute-force enumeration (Deuces Wild evaluation)

    func testOutcomeCountsMatchesBruteForceForPatHandDeucesWild() {
        assertMatchesBruteForce(
            handCodes: deucesWildFourOfAKindCodes,
            heldPositions: [0, 1, 2, 3, 4],
            wildcardRank: .two,
        )
    }

    func testOutcomeCountsMatchesBruteForceForDiscardOneDeucesWild() {
        assertMatchesBruteForce(
            handCodes: deucesWildFourOfAKindCodes,
            heldPositions: [0, 1, 2, 3],
            wildcardRank: .two,
        )
    }

    func testOutcomeCountsMatchesBruteForceForDiscardTwoDeucesWild() {
        assertMatchesBruteForce(
            handCodes: deucesWildFourOfAKindCodes,
            heldPositions: [0, 1, 2],
            wildcardRank: .two,
        )
    }

    func testOutcomeCountsMatchesBruteForceForDiscardThreeDeucesWild() {
        assertMatchesBruteForce(
            handCodes: deucesWildFourOfAKindCodes,
            heldPositions: [0, 1],
            wildcardRank: .two,
        )
    }

    // MARK: - Helpers

    /// A♠ K♠ Q♠ J♠ T♠ — royal flush, encoded as `(rank_index << 2) | suit_index`.
    private var royalFlushCodes: [Int] {
        [(12 << 2) | 0, (11 << 2) | 0, (10 << 2) | 0, (9 << 2) | 0, (8 << 2) | 0]
    }

    /// 5♠ 5♥ 8♠ 8♥ 2♣ — two pair (fives and eights) plus an unrelated deuce kicker,
    /// using a real, non-wild-context deuce so the standard evaluator treats it as a
    /// plain low card.
    private var twoPairCodes: [Int] {
        [(3 << 2) | 0, (3 << 2) | 1, (6 << 2) | 0, (6 << 2) | 1, (0 << 2) | 3]
    }

    /// 2♠ 7♥ 9♦ J♣ K♠ — no pair, no straight, no flush.
    private var highCardCodes: [Int] {
        [(0 << 2) | 0, (5 << 2) | 1, (7 << 2) | 2, (9 << 2) | 3, (11 << 2) | 0]
    }

    /// 8♠ 8♥ 8♦ 8♣ 2♠ — four of a kind with a wild deuce kicker, so the Deuces Wild
    /// evaluator has a wild card in play even for the "hold everything" case.
    private var deucesWildFourOfAKindCodes: [Int] {
        [(6 << 2) | 0, (6 << 2) | 1, (6 << 2) | 2, (6 << 2) | 3, (0 << 2) | 0]
    }

    /// Compares `HandOutcomeArrays.outcomeCounts` against a direct brute-force count
    /// obtained by enumerating every possible draw completion with `FastHandEvaluator`,
    /// the same evaluator `OptimalPlay` uses live. A mismatch here means the
    /// inclusion-exclusion arithmetic in `HandOutcomeArrays` is wrong.
    private func assertMatchesBruteForce(
        handCodes: [Int],
        heldPositions: Set<Int>,
        wildcardRank: Rank?,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) {
        let heldCodes = heldPositions.sorted().map { handCodes[$0] }
        let discardedCodes = (0 ..< 5).filter { !heldPositions.contains($0) }.map { handCodes[$0] }

        let arrays = wildcardRank == nil ? Self.standardArrays : Self.deucesWildArrays
        let derived = arrays.outcomeCounts(held: heldCodes, discarded: discardedCodes)
        let expected = bruteForceOutcomeCounts(
            handCodes: handCodes, heldCodes: heldCodes, discardedCodes: discardedCodes, isWild: wildcardRank != nil,
        )

        XCTAssertEqual(derived, expected, file: file, line: line)
    }

    /// Cheaper sanity check for the larger discard sizes (4 and 5), where brute force
    /// would be expensive: only verifies the total outcome count across all
    /// `HandResult` buckets matches the known combination count, without checking the
    /// per-bucket breakdown.
    private func assertOutcomeCountsSumMatchesExpectedCombos(
        handCodes: [Int],
        heldPositions: Set<Int>,
        wildcardRank: Rank?,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) {
        let heldCodes = heldPositions.sorted().map { handCodes[$0] }
        let discardedCodes = (0 ..< 5).filter { !heldPositions.contains($0) }.map { handCodes[$0] }

        let arrays = wildcardRank == nil ? Self.standardArrays : Self.deucesWildArrays
        let derived = arrays.outcomeCounts(held: heldCodes, discarded: discardedCodes)
        let expectedTotal = CombinatorialIndex.choose(47, discardedCodes.count)

        XCTAssertEqual(derived.reduce(0, +), expectedTotal, file: file, line: line)
    }

    /// Direct brute-force reference: enumerates every possible way to complete the hand
    /// by drawing replacements for `discardedCodes` from the 47 undealt cards, scores
    /// each completion with `FastHandEvaluator`, and buckets the results.
    private func bruteForceOutcomeCounts(
        handCodes: [Int], heldCodes: [Int], discardedCodes: [Int], isWild: Bool,
    ) -> [Int] {
        var totals = [Int](repeating: 0, count: HandResult.allCases.count)
        let handSet = Set(handCodes)
        let remaining = (0 ..< 52).filter { !handSet.contains($0) }

        func score(_ cards: [Int]) -> Int {
            isWild
                ? FastHandEvaluator.deucesWildCode(cards[0], cards[1], cards[2], cards[3], cards[4])
                : FastHandEvaluator.standardCode(cards[0], cards[1], cards[2], cards[3], cards[4])
        }

        if discardedCodes.isEmpty {
            totals[score(heldCodes)] += 1
            return totals
        }

        for draw in combinations(of: remaining, choose: discardedCodes.count) {
            totals[score(heldCodes + draw)] += 1
        }
        return totals
    }

    /// Every `choose`-sized combination of `elements`, in no particular order.
    private func combinations(of elements: [Int], choose count: Int) -> [[Int]] {
        guard count > 0 else { return [[]] }
        guard elements.count >= count else { return [] }
        if count == elements.count {
            return [elements]
        }

        var results: [[Int]] = []
        func recurse(_ start: Int, _ chosen: [Int]) {
            if chosen.count == count {
                results.append(chosen)
                return
            }
            let remainingSlots = count - chosen.count
            guard elements.count - start >= remainingSlots else { return }
            for index in start ..< elements.count {
                recurse(index + 1, chosen + [elements[index]])
            }
        }
        recurse(0, [])
        return results
    }
}
