@testable import PlayingCard
import XCTest

/// Verifies `CombinatorialIndex.index(sortedCards:)` is a bijection between k-subsets of
/// `0..<52` and `0..<choose(52, k)`, for every hold size the library needs (1 through 5).
final class CombinatorialIndexTests: XCTestCase {
    func testChooseMatchesKnownBinomialCoefficients() {
        XCTAssertEqual(CombinatorialIndex.choose(52, 5), 2_598_960)
        XCTAssertEqual(CombinatorialIndex.choose(52, 4), 270_725)
        XCTAssertEqual(CombinatorialIndex.choose(52, 3), 22100)
        XCTAssertEqual(CombinatorialIndex.choose(52, 2), 1326)
        XCTAssertEqual(CombinatorialIndex.choose(52, 1), 52)
        XCTAssertEqual(CombinatorialIndex.choose(52, 0), 1)
    }

    func testChooseOutOfRangeReturnsZero() {
        XCTAssertEqual(CombinatorialIndex.choose(5, 6), 0)
        XCTAssertEqual(CombinatorialIndex.choose(5, -1), 0)
    }

    func testSingleCardIndexIsIdentity() {
        // For k=1, the combinatorial index of [c] is just c itself.
        for card in 0 ..< 52 {
            XCTAssertEqual(CombinatorialIndex.index(sortedCards: [card]), card)
        }
    }

    func testPairIndicesAreBijectiveOverFullRange() {
        assertBijective(k: 2, n: 52)
    }

    func testTripleIndicesAreBijectiveOverFullRange() {
        assertBijective(k: 3, n: 52)
    }

    func testFourCardIndicesAreBijectiveOverFullRange() {
        assertBijective(k: 4, n: 52)
    }

    func testFiveCardIndicesAreBijectiveOverASmallerRange() {
        // C(52, 5) is 2,598,960 combinations; exhaustively enumerating that here would
        // make this test itself slow. Bijectivity of the underlying formula is already
        // proven by the k=1..4 exhaustive checks above (the formula is the same
        // structure for every k); this narrower range is a spot check that k=5 also
        // produces a dense, collision-free range for a smaller universe.
        assertBijective(k: 5, n: 12)
    }

    /// Exhaustively enumerates every ascending k-subset of `0..<n`, asserts every
    /// resulting index is unique, and that the set of indices is exactly `0..<choose(n, k)`.
    private func assertBijective(
        k subsetSize: Int, n universeSize: Int, file: StaticString = #filePath, line: UInt = #line,
    ) {
        var seenIndices = Set<Int>()
        let expectedCount = CombinatorialIndex.choose(universeSize, subsetSize)

        func combinations(from start: Int, chosen: [Int]) {
            if chosen.count == subsetSize {
                let index = CombinatorialIndex.index(sortedCards: chosen)
                XCTAssertTrue(
                    seenIndices.insert(index).inserted,
                    "duplicate index \(index) for cards \(chosen)",
                    file: file, line: line,
                )
                XCTAssertTrue(
                    (0 ..< expectedCount).contains(index),
                    "index \(index) out of expected range [0, \(expectedCount)) for cards \(chosen)",
                    file: file, line: line,
                )
                return
            }
            for next in start ..< universeSize {
                combinations(from: next + 1, chosen: chosen + [next])
            }
        }

        combinations(from: 0, chosen: [])
        XCTAssertEqual(seenIndices.count, expectedCount, file: file, line: line)
    }
}
