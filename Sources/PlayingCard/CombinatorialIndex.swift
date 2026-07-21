/// Combinatorial-number-system helpers used to translate a set of card indices into a
/// dense array index, and back again. This is the indexing scheme described in the
/// "One Second Program" section of
/// https://wizardofodds.com/games/video-poker/methodology/: scoring every possible
/// 5-card hand once and storing outcome counts in arrays keyed by the held cards'
/// combinatorial index, rather than re-enumerating draw completions for every dealt
/// hand.
enum CombinatorialIndex {
    // swiftlint:disable identifier_name
    /// Maximum subset size this library ever indexes (holds are at most 5 cards).
    private static let maxK = 5

    /// Precomputed `choose(n, k)` for every `n` in `0...52` and `k` in `0...maxK`,
    /// built once on first access.
    ///
    /// `PayTableAnalyzer.overallReturn` calls `index(sortedCards:)` (and therefore
    /// `choose`) on the order of a few billion times per pay table (2,598,960 hands,
    /// up to 32 hold subsets each, up to 32 discard subsets per hold); a naive
    /// multiplicative recomputation per call was measured to make that computation
    /// roughly two orders of magnitude slower than it needed to be, so a lookup table
    /// replaces the O(k) multiplicative loop with an O(1) array read.
    private static let chooseTable: [[Int]] = (0 ... 52).map { n in
        (0 ... maxK).map { k in computeChoose(n, k) }
    }

    /// The multiplicative binomial-coefficient computation `choose` uses to build
    /// `chooseTable`. Not used directly outside table construction; see `choose`.
    private static func computeChoose(_ n: Int, _ k: Int) -> Int {
        guard k >= 0, k <= n else { return 0 }
        if k == 0 || k == n {
            return 1
        }
        var result = 1
        for i in 0 ..< k {
            result = result * (n - i) / (i + 1)
        }
        return result
    }

    /// Returns `n choose k` (the binomial coefficient), or 0 when `k` is out of range.
    ///
    /// Cards are encoded as small integers (0..<52 in this library), and holds are at
    /// most 5 cards, so this is always a lookup into `chooseTable`; falls back to a
    /// direct computation for any `n`/`k` outside that table's range.
    static func choose(_ n: Int, _ k: Int) -> Int {
        guard k >= 0, k <= n else { return 0 }
        guard n <= 52, k <= maxK else { return computeChoose(n, k) }
        return chooseTable[n][k]
    }

    // swiftlint:enable identifier_name

    /// Returns the 0-based combinatorial-number-system index of an ascending, unique
    /// set of card indices, among all `choose(52, cards.count)` possible combinations.
    ///
    /// For sorted `c(0) < c(1) < ... < c(k-1)`, the index is
    /// `sum(choose(c(i), i + 1))` for `i` in `0..<k`. This is a standard bijection
    /// between k-subsets of `0..<n` and `0..<choose(n, k)`; see
    /// `CombinatorialIndexTests` for the exhaustive bijection check.
    ///
    /// - Parameter sortedCards: Card indices in strictly ascending order. Any range of
    ///   distinct non-negative integers works; this library uses `0..<52`.
    static func index(sortedCards: [Int]) -> Int {
        var index = 0
        for (position, card) in sortedCards.enumerated() {
            index += choose(card, position + 1)
        }
        return index
    }
}
