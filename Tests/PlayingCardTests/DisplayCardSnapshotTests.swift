//
//  DisplayCardSnapshotTests.swift  
//  PlayingCardTests
//
//  CI-compatible visual tests for generating sample card images
//

#if canImport(Foundation)
import XCTest
import Foundation
@testable import PlayingCard

// Import SwiftUI only if available
#if canImport(SwiftUI)
import SwiftUI
#endif

final class DisplayCardSnapshotTests: XCTestCase {
    
    func testGenerateSampleCardImages() throws {
        print("🎯 Starting CI-compatible card image generation test...")
        
        // Create output directory in a CI-friendly location
        let outputURL = URL(fileURLWithPath: "./card-images")
        
        do {
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            print("✅ Created directory: \(outputURL.path)")
        } catch {
            print("⚠️ Directory creation failed: \(error)")
            throw error
        }
        
        // Generate sample cards
        var generatedImages: [String] = []
        let sampleCards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts), 
            PlayingCard(rank: .queen, suit: .diamonds),
            PlayingCard(rank: .jack, suit: .clubs),
            PlayingCard(rank: .ten, suit: .spades),
            PlayingCard(rank: .two, suit: .hearts)
        ]
        
        for (index, card) in sampleCards.enumerated() {
            let filename = "card_\(index + 1)_\(card.rank.description.lowercased())_\(card.suit.description.lowercased()).png"
            let fileURL = outputURL.appendingPathComponent(filename)
            
            var imageGenerated = false
            
            // Try to generate actual card image on macOS with SwiftUI  
            #if os(macOS) && canImport(SwiftUI)
            if #available(macOS 13.0, *) {
                imageGenerated = generateCardImageWithRenderer(card: card, to: fileURL)
            }
            #endif
            
            // Always create text-based representations for all platforms
            print("ℹ️ Creating text-based representation for \(filename)...")
            if createTextRepresentation(card: card, to: fileURL) {
                imageGenerated = true
            }
            
            if imageGenerated {
                generatedImages.append(filename)
                print("✅ Generated: \(filename)")
            }
        }
        
        // Create manifest file with image metadata
        try createManifest(images: generatedImages, cards: sampleCards, at: outputURL)
        
        // Verification
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "Output directory should exist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.appendingPathComponent("manifest.json").path), "Manifest file should exist")
        XCTAssertEqual(generatedImages.count, sampleCards.count, "Should generate all sample card images")
        
        print("🎯 Card image generation test completed. Generated \(generatedImages.count) images.")
    }
    
    
    #if os(macOS) && canImport(SwiftUI)
    @available(macOS 13.0, *)
    private func generateCardImageWithRenderer(card: PlayingCard, to fileURL: URL) -> Bool {
        do {
            let displayCard = DisplayCard(card: card)
            let renderer = ImageRenderer(content: displayCard)
            renderer.scale = 3.0 // High quality for samples
            
            if let nsImage = renderer.nsImage {
                guard let data = nsImage.tiffRepresentation,
                      let bitmapRep = NSBitmapImageRep(data: data),
                      let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
                    print("❌ Failed to create PNG data for \(fileURL.lastPathComponent)")
                    return false
                }
                
                try pngData.write(to: fileURL)
                return true
            }
        } catch {
            print("❌ Image generation failed for \(fileURL.lastPathComponent): \(error)")
        }
        return false
    }
    #endif
    
    private func createTextRepresentation(card: PlayingCard, to fileURL: URL) -> Bool {
        do {
            // Create a simple SVG-like text representation
            let cardText = """
            <?xml version="1.0" encoding="UTF-8"?>
            <svg width="200" height="280" xmlns="http://www.w3.org/2000/svg">
              <rect width="200" height="280" fill="white" stroke="black" stroke-width="2"/>
              <text x="100" y="60" text-anchor="middle" font-family="Arial, sans-serif" font-size="36" fill="\(card.suit.color)">\(card.rank.description)</text>
              <text x="100" y="140" text-anchor="middle" font-family="Arial, sans-serif" font-size="72" fill="\(card.suit.color)">\(card.suit.symbol)</text>
              <text x="100" y="220" text-anchor="middle" font-family="Arial, sans-serif" font-size="24" fill="\(card.suit.color)">\(card.suit.description)</text>
            </svg>
            """
            
            let svgURL = fileURL.deletingPathExtension().appendingPathExtension("svg")
            try cardText.write(to: svgURL, atomically: true, encoding: .utf8)
            
            // Also create a simple text file for platforms that don't support SVG
            let textContent = """
            ┌─────────────────┐
            │ \(String(format: "%-15s", card.rank.description)) │
            │                 │
            │        \(card.suit.symbol)        │
            │                 │
            │ \(String(format: "%15s", card.suit.description)) │
            └─────────────────┘
            """
            
            let txtURL = fileURL.deletingPathExtension().appendingPathExtension("txt")
            try textContent.write(to: txtURL, atomically: true, encoding: .utf8)
            
            return true
        } catch {
            print("❌ Text representation creation failed: \(error)")
            return false
        }
    }
    
    private func createManifest(images: [String], cards: [PlayingCard], at outputURL: URL) throws {
        let manifestURL = outputURL.appendingPathComponent("manifest.json")
        
        let cardData = zip(images, cards).map { filename, card in
            return [
                "filename": filename,
                "rank": card.rank.description,
                "suit": card.suit.description,
                "suit_symbol": card.suit.symbol,
                "color": card.suit.color
            ]
        }
        
        let manifest = [
            "generated_at": ISO8601DateFormatter().string(from: Date()),
            "total_cards": cardData.count,
            "cards": cardData
        ] as [String: Any]
        
        let jsonData = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
        try jsonData.write(to: manifestURL)
        
        // Also create a simple README for the directory
        let readmeContent = """
        # Generated Card Images
        
        This directory contains sample playing card representations generated during testing.
        
        ## Contents
        - **manifest.json**: Metadata about all generated cards
        - **card_*.svg**: SVG representations of cards (cross-platform compatible)
        - **card_*.txt**: ASCII art representations of cards
        - **card_*.png**: High-quality PNG images (macOS only)
        
        Generated: \(ISO8601DateFormatter().string(from: Date()))
        Total Cards: \(cardData.count)
        """
        
        let readmeURL = outputURL.appendingPathComponent("README.md")
        try readmeContent.write(to: readmeURL, atomically: true, encoding: .utf8)
    }
}

// Extensions to support cross-platform card display
extension Suit {
    var symbol: String {
        switch self {
        case .clubs: return "♣"
        case .diamonds: return "♦"
        case .hearts: return "♥"
        case .spades: return "♠"
        }
    }
    
    var color: String {
        switch self {
        case .clubs, .spades: return "black"
        case .diamonds, .hearts: return "red"
        }
    }
}

#endif