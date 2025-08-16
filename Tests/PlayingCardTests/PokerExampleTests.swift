/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

@testable import PlayingCard
import XCTest

class PokerExampleTests: XCTestCase {

    func testPlayExampleHand() {
        let output = VideoPokerExample.playExampleHand()

        // Verify the output contains expected elements
        XCTAssertTrue(output.contains("Video Poker Game Example"))
        XCTAssertTrue(output.contains("Initial 5-card hand dealt"))
        XCTAssertTrue(output.contains("Final hand evaluation"))
        XCTAssertTrue(output.contains("Payout"))

        // Should contain proper card representations
        XCTAssertTrue(output.contains("♠️") || output.contains("♥️") ||
                     output.contains("♦️") || output.contains("♣️"))

        print("Example game output:")
        print(output)
    }

    func testDemonstrateHandComparison() {
        let output = VideoPokerExample.demonstrateHandComparison()

        // Verify the output contains expected elements
        XCTAssertTrue(output.contains("Hand Comparison Example"))
        XCTAssertTrue(output.contains("Hand 1:"))
        XCTAssertTrue(output.contains("Hand 2:"))
        XCTAssertTrue(output.contains("wins!") || output.contains("tie!"))

        // Should show proper hand evaluations
        XCTAssertTrue(output.contains("Pair") || output.contains("Three of a Kind") ||
                     output.contains("High Card"))

        print("Hand comparison output:")
        print(output)
    }

    static var allTests = [
        ("testPlayExampleHand", testPlayExampleHand),
        ("testDemonstrateHandComparison", testDemonstrateHandComparison),
    ]
}
