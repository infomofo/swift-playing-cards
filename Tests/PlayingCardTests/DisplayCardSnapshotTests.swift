import XCTest
@testable import PlayingCard
import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

final class DisplayCardSnapshotTests: XCTestCase {

    func testGenerateSampleCardImages() throws {
        // Create output directory
        let outputURL = URL(fileURLWithPath: "card-images")
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)

        // Test cards specified in the requirements
        let testCards = [
            ("2_of_spades", PlayingCard(rank: .two, suit: .spades)),
            ("ace_of_clubs", PlayingCard(rank: .ace, suit: .clubs)),
            ("king_of_hearts", PlayingCard(rank: .king, suit: .hearts)),
            ("9_of_diamonds", PlayingCard(rank: .nine, suit: .diamonds))
        ]

        var generatedFiles: [String] = []

        for (filename, card) in testCards {
            // Generate compact version SVG
            let compactSVG = generateCardSVG(card: card, displayMode: .compact)
            let compactURL = outputURL.appendingPathComponent("\(filename)_compact.svg")
            try compactSVG.write(to: compactURL, atomically: true, encoding: .utf8)
            generatedFiles.append("\(filename)_compact.svg")

            // Generate large version SVG
            let largeSVG = generateCardSVG(card: card, displayMode: .large)
            let largeURL = outputURL.appendingPathComponent("\(filename)_large.svg")
            try largeSVG.write(to: largeURL, atomically: true, encoding: .utf8)
            generatedFiles.append("\(filename)_large.svg")
        }

        // Create manifest file
        let manifestContent = generatedFiles.joined(separator: "\n")
        let manifestURL = outputURL.appendingPathComponent("manifest.txt")
        try manifestContent.write(to: manifestURL, atomically: true, encoding: .utf8)

        // Verify files were created
        XCTAssertTrue(FileManager.default.fileExists(atPath: manifestURL.path))
        XCTAssertGreaterThan(generatedFiles.count, 0)

        print("Generated \(generatedFiles.count) SVG card image files in card-images/ directory")
        print("Files: \(generatedFiles.joined(separator: ", "))")
    }

    func testGenerateAllCardImages() throws {
        // Create output directory
        let outputURL = URL(fileURLWithPath: "card-images")
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)

        var generatedFiles: [String] = []

        for suit in Suit.allCases {
            for rank in Rank.allCases {
                let card = PlayingCard(rank: rank, suit: suit)
                let filename = "\(rank.name)_of_\(suit.rawValue)"

                // Generate compact version SVG
                let compactSVG = generateCardSVG(card: card, displayMode: .compact)
                let compactURL = outputURL.appendingPathComponent("\(filename)_compact.svg")
                try compactSVG.write(to: compactURL, atomically: true, encoding: .utf8)
                generatedFiles.append("\(filename)_compact.svg")

                // Generate large version SVG
                let largeSVG = generateCardSVG(card: card, displayMode: .large)
                let largeURL = outputURL.appendingPathComponent("\(filename)_large.svg")
                try largeSVG.write(to: largeURL, atomically: true, encoding: .utf8)
                generatedFiles.append("\(filename)_large.svg")
            }
        }

        // Create manifest file
        let manifestContent = generatedFiles.joined(separator: "\n")
        let manifestURL = outputURL.appendingPathComponent("manifest.txt")
        try manifestContent.write(to: manifestURL, atomically: true, encoding: .utf8)

        // Verify files were created
        XCTAssertTrue(FileManager.default.fileExists(atPath: manifestURL.path))
        XCTAssertEqual(generatedFiles.count, 52 * 2)

        print("Generated \(generatedFiles.count) SVG card image files in card-images/ directory")
        print("Files include both compact (28x36) and large (120x168) versions of all 52 cards")
    }

    enum DisplayMode {
        case compact
        case large
    }

    private func generateCardSVG(card: PlayingCard, displayMode: DisplayMode) -> String {
        switch displayMode {
        case .compact:
            return generateCompactCardSVG(card: card)
        case .large:
            return generateLargeCardSVG(card: card)
        }
    }

    private func generateCompactCardSVG(card: PlayingCard) -> String {
        let color = (card.suit == .hearts || card.suit == .diamonds) ? "red" : "black"

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg width="28" height="36" viewBox="0 0 28 36" xmlns="http://www.w3.org/2000/svg">
          <!-- Card background -->
          <rect x="0" y="0" width="28" height="36" fill="white" stroke="black" stroke-width="1" rx="4"/>

          <!-- Rank -->
          <text x="14" y="15" text-anchor="middle" font-family="Arial, sans-serif"
                font-size="10" font-weight="bold" fill="\(color)">
            \(card.rank.compactDescription)
          </text>

          <!-- Suit -->
          <text x="14" y="30" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="\(color)">
            \(card.suit.description)
          </text>
        </svg>
        """
    }

    private func generateLargeCardSVG(card: PlayingCard) -> String {
        let color = (card.suit == .hearts || card.suit == .diamonds) ? "red" : "black"
        let isNumberCard = isNumberCard(card.rank)

        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg width="120" height="168" viewBox="0 0 120 168" xmlns="http://www.w3.org/2000/svg">
          <!-- Card background -->
          <rect x="0" y="0" width="120" height="168" fill="white" stroke="black" stroke-width="2" rx="8"/>

          <!-- Top left corner -->
          <text x="12" y="24" text-anchor="start" font-family="Arial, sans-serif"
                font-size="16" font-weight="bold" fill="\(color)">
            \(card.rank.description)
          </text>
        """

        // Only show suit in corner for face cards and Ace
        if !isNumberCard {
            svg += """
              <text x="12" y="38" text-anchor="start" font-family="Arial, sans-serif" font-size="10" fill="\(color)">
                \(card.suit.description)
              </text>
            """
        }

        // Bottom right corner (rotated)
        if !isNumberCard {
            svg += """
              <text x="108" y="144" text-anchor="end" font-family="Arial, sans-serif"
                    font-size="10" fill="\(color)" transform="rotate(180 108 144)">
                \(card.suit.description)
              </text>
            """
        }

        svg += """
          <text x="108" y="158" text-anchor="end" font-family="Arial, sans-serif"
                font-size="16" font-weight="bold" fill="\(color)" transform="rotate(180 108 158)">
            \(card.rank.description)
          </text>
        """

        // Center content
        svg += generateCenterContent(card: card, color: color)

        svg += """
        </svg>
        """

        return svg
    }

    private func generateCenterContent(card: PlayingCard, color: String) -> String {
        switch card.rank {
        case .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten:
            return generateNumberCardCenter(card: card, color: color)
        case .ace, .jack:
            return """
              <!-- Center: Large rank letter -->
              <text x="60" y="74" text-anchor="middle" font-family="Arial, sans-serif"
                    font-size="24" font-weight="bold" fill="\(color)">
                \(card.rank.description)
              </text>
              <text x="60" y="100" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" fill="\(color)">
                \(card.suit.description)
              </text>
            """
        case .queen:
            return """
              <!-- Center: Queen emoji -->
              <text x="60" y="84" text-anchor="middle" font-family="Arial, sans-serif" font-size="24">
                \(getQueenEmoji(for: card.suit))
              </text>
              <text x="60" y="104" text-anchor="middle" font-family="Arial, sans-serif" font-size="16" fill="\(color)">
                \(card.suit.description)
              </text>
            """
        case .king:
            return """
              <!-- Center: King emoji -->
              <text x="60" y="84" text-anchor="middle" font-family="Arial, sans-serif" font-size="24">
                \(getKingEmoji(for: card.suit))
              </text>
              <text x="60" y="104" text-anchor="middle" font-family="Arial, sans-serif" font-size="16" fill="\(color)">
                \(card.suit.description)
              </text>
            """
        }
    }

    private func generateNumberCardCenter(card: PlayingCard, color: String) -> String {
        let count = card.rank.rawValue
        let positions = getSuitPositions(for: count)

        var centerSVG = "  <!-- Center: Suit symbols arranged in grid -->\n"

        for (xPos, yPos) in positions {
            centerSVG += """
              <text x="\(xPos)" y="\(yPos)" text-anchor="middle" font-family="Arial, sans-serif"
                    font-size="14" fill="\(color)">
                \(card.suit.description)
              </text>

            """
        }

        return centerSVG
    }

    private func getSuitPositions(for count: Int) -> [(Int, Int)] {
        let centerX = 60
        let topY = 60
        let bottomY = 108
        let midY = 84

        switch count {
        case 2:
            return [(centerX, topY), (centerX, bottomY)]
        case 3:
            return [(centerX, topY), (centerX, midY), (centerX, bottomY)]
        case 4:
            return [(40, topY), (80, topY), (40, bottomY), (80, bottomY)]
        case 5:
            return [(40, topY), (80, topY), (centerX, midY), (40, bottomY), (80, bottomY)]
        case 6:
            return [(40, topY), (80, topY), (40, midY), (80, midY), (40, bottomY), (80, bottomY)]
        case 7:
            // 7: 2 top, 1 center top, 2 center bottom, 2 bottom - better spacing
            return [(40, topY), (80, topY), (40, 72), (60, midY), (80, 72), (40, bottomY), (80, bottomY)]
        case 8:
            // 8: 2 top, 2 center top, 2 center bottom, 2 bottom - even distribution
            return [(40, topY), (80, topY), (40, 72), (80, 72), (40, 96), (80, 96), (40, bottomY), (80, bottomY)]
        case 9:
            // 9: 3 top, 2 center, 3 center bottom, 1 bottom - improved spacing
            return [(40, topY), (60, topY), (80, topY), (40, 76), (80, 76),
                    (40, 88), (60, 88), (80, 88), (60, bottomY)]
        case 10:
            // 10: 2 top, 2 upper middle, 2 lower middle, 2 center bottom, 2 bottom - evenly distributed
            return [(40, topY), (80, topY), (40, 70), (80, 70), (40, 80), (80, 80),
                    (40, 90), (80, 90), (40, bottomY), (80, bottomY)]
        default:
            return [(centerX, midY)]
        }
    }

    private func isNumberCard(_ rank: Rank) -> Bool {
        switch rank {
        case .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten:
            return true
        case .ace, .jack, .queen, .king:
            return false
        }
    }

    private func getQueenEmoji(for suit: Suit) -> String {
        switch suit {
        case .hearts: return "👸🏼"
        case .spades: return "👸🏻"
        case .clubs: return "👸🏽"
        case .diamonds: return "👸🏾"
        }
    }

    private func getKingEmoji(for suit: Suit) -> String {
        switch suit {
        case .hearts: return "🤴🏼"
        case .spades: return "🤴🏻"
        case .clubs: return "🤴🏽"
        case .diamonds: return "🤴🏾"
        }
    }
}
