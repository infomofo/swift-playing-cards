#if canImport(SwiftUI)
import SwiftUI

/// An interactive playing card that can be selected and animated.
/// Useful for video poker where players need to choose which cards to hold.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct InteractiveCard: View {
    @State private var isSelected: Bool = false
    @State private var rotationDegrees: Double = 0
    @State private var card: PlayingCard
    
    let onSelectionChanged: ((Bool) -> Void)?
    
    public init(card: PlayingCard, onSelectionChanged: ((Bool) -> Void)? = nil) {
        self._card = State(initialValue: card)
        self.onSelectionChanged = onSelectionChanged
    }
    
    public var body: some View {
        Button(action: toggleSelection) {
            DisplayCard(card: card, displayMode: .large)
                .overlay(
                    selectionOverlay,
                    alignment: .topTrailing
                )
                .rotation3DEffect(
                    .degrees(rotationDegrees),
                    axis: (x: 0, y: 1, z: 0)
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                .animation(.easeInOut(duration: 0.6), value: rotationDegrees)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var selectionOverlay: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
                .background(Color.white.clipShape(Circle()))
                .offset(x: 8, y: -8)
        }
    }
    
    private func toggleSelection() {
        withAnimation {
            isSelected.toggle()
            // Add a subtle flip animation when selected
            rotationDegrees += isSelected ? 10 : -10
        }
        
        onSelectionChanged?(isSelected)
    }
    
    /// Programmatically set the selection state
    public func setSelected(_ selected: Bool) {
        withAnimation {
            isSelected = selected
        }
    }
    
    /// Replace this card with a new card (with animation)
    public func replace(with newCard: PlayingCard) {
        withAnimation(.easeInOut(duration: 0.6)) {
            rotationDegrees += 180
        }
        
        // Update the card after half the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) {
                card = newCard
                rotationDegrees += 180
            }
        }
    }
}

// MARK: - Hashable & Equatable

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension InteractiveCard: Hashable, Equatable {
    public static func == (lhs: InteractiveCard, rhs: InteractiveCard) -> Bool {
        return lhs.card == rhs.card
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(card)
    }
}

// MARK: - Preview

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
struct InteractiveCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HStack {
                InteractiveCard(card: PlayingCard(rank: .ace, suit: .spades)) { selected in
                    print("Ace of Spades selected: \(selected)")
                }
                InteractiveCard(card: PlayingCard(rank: .king, suit: .hearts)) { selected in
                    print("King of Hearts selected: \(selected)")
                }
            }
            .previewDisplayName("Interactive Cards")
            
            // Video poker hand example
            VideoPokerHandView()
                .previewDisplayName("Video Poker Hand")
        }
    }
}

/// Example of how to use InteractiveCard in a video poker interface
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
private struct VideoPokerHandView: View {
    @State private var selectedCards: Set<Int> = []
    
    let hand = [
        PlayingCard(rank: .ace, suit: .spades),
        PlayingCard(rank: .ace, suit: .hearts),
        PlayingCard(rank: .king, suit: .diamonds),
        PlayingCard(rank: .queen, suit: .clubs),
        PlayingCard(rank: .jack, suit: .spades)
    ]
    
    var body: some View {
        VStack {
            Text("Select cards to hold")
                .font(.headline)
                .padding()
            
            HStack(spacing: 10) {
                ForEach(0..<hand.count, id: \.self) { index in
                    InteractiveCard(card: hand[index]) { isSelected in
                        if isSelected {
                            selectedCards.insert(index)
                        } else {
                            selectedCards.remove(index)
                        }
                    }
                }
            }
            .padding()
            
            if !selectedCards.isEmpty {
                Text("Holding cards: \(selectedCards.map { $0 + 1 }.sorted().map(String.init).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#endif