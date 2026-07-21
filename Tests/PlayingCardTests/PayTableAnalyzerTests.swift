@testable import PlayingCard
import XCTest

/// Cross-checks `PayTableAnalyzer.overallReturn(payTable:)` against the published
/// return-to-player percentages for this library's existing pay tables. This is the
/// end-to-end correctness gate for the whole `HandOutcomeArrays` / `PayTableAnalyzer`
/// stack: a bug anywhere in the inclusion-exclusion arithmetic, the combinatorial
/// indexing, or the best-hold selection would show up here as a return percentage that
/// doesn't match the well-documented value for these pay tables.
///
/// Published values (verified against Wizard of Odds, https://wizardofodds.com):
/// - Full-pay 9/6 Jacks or Better: 99.5439%
/// - 9/5 Jacks or Better: 98.45%
/// - 8/6 Jacks or Better: 98.39%
/// - Full-pay Deuces Wild: 100.762%
///
/// Each `overallReturn` call exhaustively evaluates all 2,598,960 possible starting
/// hands times up to 32 hold subsets each (~1.5s per pay table in a Release build,
/// ~160s per pay table in the unoptimized Debug build). CI runs the whole suite with
/// `-c release` for this reason (see `.github/workflows/test.yml`).
final class PayTableAnalyzerTests: XCTestCase {
    func testFullPayJacksOrBetterReturn() {
        let returnPercent = PayTableAnalyzer.overallReturn(payTable: .jacksOrBetter96) * 100
        XCTAssertEqual(returnPercent, 99.5439, accuracy: 0.0005)
    }

    func testNineFiveJacksOrBetterReturn() {
        let returnPercent = PayTableAnalyzer.overallReturn(payTable: .jacksOrBetter95) * 100
        XCTAssertEqual(returnPercent, 98.45, accuracy: 0.01)
    }

    func testEightSixJacksOrBetterReturn() {
        let returnPercent = PayTableAnalyzer.overallReturn(payTable: .jacksOrBetter86) * 100
        XCTAssertEqual(returnPercent, 98.39, accuracy: 0.01)
    }

    func testFullPayDeucesWildReturn() {
        let returnPercent = PayTableAnalyzer.overallReturn(payTable: .deucesWild) * 100
        XCTAssertEqual(returnPercent, 100.762, accuracy: 0.001)
    }
}
