#if canImport(SwiftUI)
import XCTest
import SwiftUI
@testable import PlayingCard

final class DisplayCardSnapshotTests: XCTestCase {
    func testGenerateDisplayCardImage() throws {
        let card = PlayingCard(rank: .four, suit: .hearts)
        let view = DisplayCard(card: card)
        let renderer = ImageRenderer(content: view.frame(width: 100, height: 140))
        guard let image = renderer.nsImage else {
            // Skip test if image rendering fails (e.g., in headless CI)
            throw XCTSkip("Image rendering not available in this environment")
        }
        guard let imageData = image.tiffRepresentation else {
            throw XCTSkip("Failed to get image data")
        }
        let url = URL(fileURLWithPath: "Tests/PlayingCardTests/DisplayCardSnapshot.png")
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
