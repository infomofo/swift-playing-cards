/// Combinatorial-number-system helpers used to translate a set of card indices into a
/// dense array index, and back again. This is the indexing scheme described in the
/// "One Second Program" section of
/// https://wizardofodds.com/games/video-poker/methodology/: scoring every possible
/// 5-card hand once and storing outcome counts in arrays keyed by the held cards'
/// combinatorial index, rather than re-enumerating draw completions for every dealt
/// hand.
enum CombinatorialIndex {
    // swiftlint:disable identifier_name
    /// Returns `n choose k` (the binomial coefficient), or 0 when `k` is out of range.
    ///
    /// Cards are encoded as small integers (0..<52 in this library), and holds are at
    /// most 5 cards, so `k` never exceeds single digits; a direct multiplicative
    /// computation is simpler and cheap enough here that a precomputed lookup table
    /// would be premature.
    static func choose(_ n: Int, _ k: Int) -> Int {
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
