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
            // Generate compact version description
            let compactDescription = generateCardDescription(card: card, displayMode: "compact")
            let compactURL = outputURL.appendingPathComponent("\(filename)_compact.txt")
            try compactDescription.write(to: compactURL, atomically: true, encoding: .utf8)
            generatedFiles.append("\(filename)_compact.txt")
            
            // Generate large version description
            let largeDescription = generateCardDescription(card: card, displayMode: "large")
            let largeURL = outputURL.appendingPathComponent("\(filename)_large.txt")
            try largeDescription.write(to: largeURL, atomically: true, encoding: .utf8)
            generatedFiles.append("\(filename)_large.txt")
        }
        
        // Create manifest file
        let manifestContent = generatedFiles.joined(separator: "\n")
        let manifestURL = outputURL.appendingPathComponent("manifest.txt")
        try manifestContent.write(to: manifestURL, atomically: true, encoding: .utf8)
        
        // Verify files were created
        XCTAssertTrue(FileManager.default.fileExists(atPath: manifestURL.path))
        XCTAssertGreaterThan(generatedFiles.count, 0)
        
        print("Generated \(generatedFiles.count) card representation files in card-images/ directory")
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

                // Generate compact version description
                let compactDescription = generateCardDescription(card: card, displayMode: "compact")
                let compactURL = outputURL.appendingPathComponent("\(filename)_compact.txt")
                try compactDescription.write(to: compactURL, atomically: true, encoding: .utf8)
                generatedFiles.append("\(filename)_compact.txt")

                // Generate large version description
                let largeDescription = generateCardDescription(card: card, displayMode: "large")
                let largeURL = outputURL.appendingPathComponent("\(filename)_large.txt")
                try largeDescription.write(to: largeURL, atomically: true, encoding: .utf8)
                generatedFiles.append("\(filename)_large.txt")
            }
        }

        // Create manifest file
        let manifestContent = generatedFiles.joined(separator: "\n")
        let manifestURL = outputURL.appendingPathComponent("manifest.txt")
        try manifestContent.write(to: manifestURL, atomically: true, encoding: .utf8)

        // Verify files were created
        XCTAssertTrue(FileManager.default.fileExists(atPath: manifestURL.path))
        XCTAssertEqual(generatedFiles.count, 52 * 2)

        print("Generated \(generatedFiles.count) card representation files in card-images/ directory")
    }
    
    private func generateCardDescription(card: PlayingCard, displayMode: String) -> String {
        let modeDescription = displayMode == "compact" ? "COMPACT" : "LARGE"
        let suitName = card.suit.rawValue.capitalized
        let rankName = card.rank.name
        
        var description = """
        Card: \(rankName) of \(suitName)
        Display Mode: \(modeDescription)
        Rank Symbol: \(card.rank.description)
        Suit Symbol: \(card.suit.description)
        Color: \(card.suit == .hearts || card.suit == .diamonds ? "Red" : "Black")
        
        """
        
        if displayMode == "compact" {
            description += """
            Compact Layout:
            - Size: 28x36 pixels (fits 5 cards wide on Apple Watch)
            - Rank: \(card.rank.compactDescription) (top, bold, \(card.suit == .hearts || card.suit == .diamonds ? "red" : "black"))
            - Suit: \(card.suit.description) (bottom, larger)
            """
        } else {
            description += """
            Large Layout:
            - Size: 120x168 pixels (suitable for iPhone/iPad)
            - Corner indicators: \(card.rank.description) and \(card.suit.description) in corners
            """
            
            switch card.rank {
            case .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten:
                description += "\n- Center: \(card.rank.description) \(card.suit.description) symbols arranged in grid"
            case .ace, .jack:
                description += "\n- Center: Large '\(card.rank.description)' with \(card.suit.description) below"
            case .queen:
                let emoji = getQueenEmoji(for: card.suit)
                description += "\n- Center: \(emoji) emoji with \(card.suit.description) below"
            case .king:
                let emoji = getKingEmoji(for: card.suit)
                description += "\n- Center: \(emoji) emoji with \(card.suit.description) below"
            }
        }
        
        return description
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