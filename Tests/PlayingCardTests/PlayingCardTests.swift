import XCTest
@testable import PlayingCard

final class PlayingCardTests: XCTestCase {

    func testCardCreation() {
        let card = PlayingCard(rank: .ace, suit: .spades)
        XCTAssertEqual(card.rank, .ace)
        XCTAssertEqual(card.suit, .spades)
    }

    func testCardComparison() {
        let aceSpades = PlayingCard(rank: .ace, suit: .spades)
        let kingHearts = PlayingCard(rank: .king, suit: .hearts)

        XCTAssertGreaterThan(aceSpades, kingHearts)
    }

    func testCardDescription() {
        let card = PlayingCard(rank: .ace, suit: .spades)
        XCTAssertEqual(card.description, "♠️ A")
    }

    func testSuitDescription() {
        XCTAssertEqual(Suit.spades.description, "♠️")
        XCTAssertEqual(Suit.hearts.description, "♥️")
        XCTAssertEqual(Suit.diamonds.description, "♦️")
        XCTAssertEqual(Suit.clubs.description, "♣️")
    }

    func testRankDescription() {
        XCTAssertEqual(Rank.ace.description, "A")
        XCTAssertEqual(Rank.king.description, "K")
        XCTAssertEqual(Rank.queen.description, "Q")
        XCTAssertEqual(Rank.jack.description, "J")
        XCTAssertEqual(Rank.ten.description, "10")
        XCTAssertEqual(Rank.two.description, "2")
    }
}
