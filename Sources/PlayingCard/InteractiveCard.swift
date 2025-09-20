#if canImport(SwiftUI)
import SwiftUI

/// An interactive playing card that can be selected and animated.
/// Useful for video poker where players need to choose which cards to hold.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct InteractiveCard: View {
    @State private var isSelected: Bool = false
    @State private var rotationDegrees: Double = 0
    @State private var card: PlayingCard
    @State private var isShowingBack: Bool = false

    let onSelectionChanged: ((Bool) -> Void)?

    public init(card: PlayingCard, onSelectionChanged: ((Bool) -> Void)? = nil) {
        self._card = State(initialValue: card)
        self.onSelectionChanged = onSelectionChanged
    }

    public var body: some View {
        Button(action: toggleSelection) {
            ZStack {
                if isShowingBack {
                    cardBackView
                } else {
                    DisplayCard(card: card, displayMode: .large)
                        .overlay(
                            selectionOverlay,
                            alignment: .topTrailing
                        )
                }
            }
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

    // MARK: - Card Back View

    private var cardBackView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 2)
            )
            .frame(width: 120, height: 168)
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
    /// Returns whether the card is currently selected
    public var isCardSelected: Bool {
        return isSelected
    }

    /// Replace this card with a new card (with animation)
    public func replace(with newCard: PlayingCard) {
        withAnimation(.easeInOut(duration: 0.3)) {
            rotationDegrees += 90
            isShowingBack = true
        }

        // Update the card and flip back after showing the back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            card = newCard
            withAnimation(.easeInOut(duration: 0.3)) {
                isShowingBack = false
                rotationDegrees += 90
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
    @State private var currentHand: [PlayingCard] = []
    @State private var deck = Deck()
    @State private var cardRefs: [InteractiveCard] = []

    init() {
        _deck = State(initialValue: {
            var deck = Deck()
            deck.shuffle()
            return deck
        }())

        _currentHand = State(initialValue: {
            var deck = Deck()
            deck.shuffle()
            return deck.dealCards(5)
        }())
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Video Poker - Select cards to hold")
                .font(.headline)
                .padding()

            HStack(spacing: 10) {
                ForEach(0..<currentHand.count, id: \.self) { index in
                    InteractiveCard(card: currentHand[index]) { isSelected in
                        if isSelected {
                            selectedCards.insert(index)
                        } else {
                            selectedCards.remove(index)
                        }
                    }
                }
            }
            .padding()

            VStack(spacing: 12) {
                if !selectedCards.isEmpty {
                    let selectedText = selectedCards.map { $0 + 1 }.sorted().map(String.init).joined(separator: ", ")
                    Text("Holding cards: \(selectedText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(action: redealCards) {
                    Text("Redeal Non-Selected Cards")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(selectedCards.count == 5) // Can't redeal if all cards are held

                Text("Current Hand: \(evaluateCurrentHand())")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.top)
            }
        }
        .padding()
    }
    private func redealCards() {
        let cardsToReplace = Set(0..<5).subtracting(selectedCards)

        guard !cardsToReplace.isEmpty else { return }

        // Deal new cards
        let newCards = deck.dealCards(cardsToReplace.count)
        var newCardIndex = 0

        // Replace cards with animation
        for cardIndex in cardsToReplace.sorted() where newCardIndex < newCards.count {
            // Update the hand immediately
            currentHand[cardIndex] = newCards[newCardIndex]
            newCardIndex += 1
        }

        // Reset selections after redeal
        selectedCards.removeAll()
    }
    private func evaluateCurrentHand() -> String {
        let hand = Hand(cards: currentHand)
        return hand.evaluate().description
    }
}

#endif
