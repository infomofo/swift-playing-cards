#if canImport(SwiftUI)
import XCTest
import SwiftUI
@testable import PlayingCard

final class DisplayCardSnapshotTests: XCTestCase {
    func testGenerateDisplayCardImages() throws {
        // Create a variety of sample cards for demonstration
        let sampleCards: [(PlayingCard, String)] = [
            (PlayingCard(rank: .ace, suit: .spades), "ace_of_spades"),
            (PlayingCard(rank: .king, suit: .hearts), "king_of_hearts"),
            (PlayingCard(rank: .queen, suit: .diamonds), "queen_of_diamonds"),
            (PlayingCard(rank: .jack, suit: .clubs), "jack_of_clubs"),
            (PlayingCard(rank: .ten, suit: .hearts), "ten_of_hearts"),
            (PlayingCard(rank: .four, suit: .hearts), "four_of_hearts") // original test card
        ]
        
        // Generate images for each sample card
        for (card, filename) in sampleCards {
            let view = DisplayCard(card: card)
            let renderer = ImageRenderer(content: view.frame(width: 100, height: 140))
            guard let image = renderer.nsImage else {
                // Skip test if image rendering fails (e.g., in headless CI)
                throw XCTSkip("Image rendering not available in this environment")
            }
            guard let imageData = image.tiffRepresentation else {
                throw XCTSkip("Failed to get image data")
            }
            let url = URL(fileURLWithPath: "Tests/PlayingCardTests/\(filename).png")
            try imageData.write(to: url)
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
        
        // Also generate a poker hand example
        try generatePokerHandExample()
    }
    
    private func generatePokerHandExample() throws {
        let deck = Deck()
        let sampleHand = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .spades),
            PlayingCard(rank: .queen, suit: .spades),
            PlayingCard(rank: .jack, suit: .spades),
            PlayingCard(rank: .ten, suit: .spades)
        ]
        let hand = Hand(cards: sampleHand)
        let handType = hand.evaluate()
        
        // Create a horizontal layout of the poker hand
        let handView = HStack(spacing: 4) {
            ForEach(sampleHand, id: \.self) { card in
                DisplayCard(card: card)
                    .frame(width: 60, height: 84)
            }
        }
        .padding()
        .background(Color.green.opacity(0.3))
        .cornerRadius(10)
        .overlay(
            VStack {
                Spacer()
                Text(handType.description)
                    .font(.headline)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    .padding(.bottom, 8)
            }
        )
        
        let renderer = ImageRenderer(content: handView.frame(width: 340, height: 120))
        guard let image = renderer.nsImage else {
            throw XCTSkip("Image rendering not available in this environment")
        }
        guard let imageData = image.tiffRepresentation else {
            throw XCTSkip("Failed to get image data")
        }
        let url = URL(fileURLWithPath: "Tests/PlayingCardTests/poker_hand_example.png")
        try imageData.write(to: url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
}

// Utility for rendering SwiftUI views to NSImage (macOS 12+)
@available(macOS 12.0, *)
struct ImageRenderer<V: View> {
    let content: V
    var nsImage: NSImage? {
        let hosting = NSHostingView(rootView: content)
        let size = hosting.fittingSize
        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
            return nil
        }
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        let image = NSImage(size: size)
        image.addRepresentation(rep)
        return image
    }
}

#endif
