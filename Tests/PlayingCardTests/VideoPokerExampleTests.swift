import XCTest
@testable import PlayingCard

final class VideoPokerExampleTests: XCTestCase {
    
    func testPlayExampleHand() {
        let output = VideoPokerExample.playExampleHand()
        
        // Should contain key elements of a video poker game
        XCTAssertTrue(output.contains("Video Poker Game Example"))
        XCTAssertTrue(output.contains("Initial 5-card hand dealt"))
        XCTAssertTrue(output.contains("Final hand evaluation"))
        XCTAssertTrue(output.contains("payout"))
        
        // Should be a substantial output (more than just a few characters)
        XCTAssertGreaterThan(output.count, 200)
    }
    
    func testHandComparison() {
        let output = VideoPokerExample.demonstrateHandComparison()
        
        XCTAssertTrue(output.contains("Hand Comparison Example"))
        XCTAssertTrue(output.contains("Royal Flush"))
        XCTAssertTrue(output.contains("Ranking from best to worst"))
        
        // Should properly rank hands
        XCTAssertTrue(output.contains("1. Royal Flush"))
    }
    
    func testProbabilities() {
        let output = VideoPokerExample.demonstrateProbabilities()
        
        XCTAssertTrue(output.contains("Probability Analysis"))
        XCTAssertTrue(output.contains("Royal Flush"))
        XCTAssertTrue(output.contains("1 in"))
    }
    
    func testMultipleHands() {
        let output = VideoPokerExample.runMultipleHands(count: 2)
        
        XCTAssertTrue(output.contains("HAND #1"))
        XCTAssertTrue(output.contains("HAND #2"))
        XCTAssertFalse(output.contains("HAND #3"))
    }
}