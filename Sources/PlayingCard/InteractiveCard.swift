#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
    @State private var isDealing = false
    @State private var flipDegrees: [Double] = Array(repeating: 0, count: 5)

    init() {
        _deck = State(initialValue: {
            var deck = Deck()
            deck.shuffle()
            return deck
        }())

        _currentHand = State(initialValue: [])
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Video Poker - Select cards to hold")
                .font(.headline)
                .padding()

            HStack(spacing: 10) {
                ForEach(0..<currentHand.count, id: \.self) { index in
                    let card = currentHand[index]
                    // Create a true 3D card with proper front and back positioning
                    ZStack {
                        // Front face of the card
                        InteractiveCard(card: card) { isSelected in
                            if isSelected {
                                selectedCards.insert(index)
                            } else {
                                selectedCards.remove(index)
                            }
                        }
                        .zIndex(1) // Ensure front is in front
                        
                        // Back face of the card positioned 180° behind front
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
                            .zIndex(0) // Ensure back is behind
                            .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                    }
                    .rotation3DEffect(.degrees(flipDegrees[index]), axis: (x: 1, y: 0, z: 0))
                    .id("card-\(index)-\(card.rank.rawValue)-\(card.suit.rawValue)-flip-\(flipDegrees[index])")
                    .transition(.identity)
                }
            }
            .perspective(800)
            .padding()

            VStack(spacing: 12) {
                if !selectedCards.isEmpty {
                    let selectedText = selectedCards.map { $0 + 1 }.sorted().map(String.init).joined(separator: ", ")
                    Text("Holding cards: \(selectedText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(action: redealCards) {
                    HStack(spacing: 8) {
                        if isDealing { ProgressView().progressViewStyle(.circular) }
                        Text(isDealing ? "Dealing…" : "Redeal Non-Selected Cards")
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(isDealing ? Color.gray : Color.blue)
                    .cornerRadius(8)
                }
                .disabled(isDealing || selectedCards.count == 5)

                Text("Current Hand: \(evaluateCurrentHand())")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.top)
            }
        }
        .padding()
        .onAppear {
            if currentHand.isEmpty {
                currentHand = deck.dealCards(5)
            }
        }
    }
    private func redealCards() {
        // Determine which indices are not held
        let cardsToReplace = Set(0..<currentHand.count).subtracting(selectedCards)
        guard !cardsToReplace.isEmpty else { return }

        isDealing = true

        let needed = cardsToReplace.count

        // First attempt to deal from the current deck
        var newCards = deck.dealCards(needed)

        // If we didn't get enough cards, reset/shuffle a fresh deck and deal again
        if newCards.count < needed {
            // Robust fallback: construct the full set of cards, exclude current hand, and draw from that pool
            var allCards: [PlayingCard] = []

            // Try to use top-level Suit/Rank allCases if available; otherwise fall back to hardcoded lists
            #if compiler(>=5.7)
            if let suitAllCases = (Suit.self as? any CaseIterable.Type) as? any Collection,
               let rankAllCases = (Rank.self as? any CaseIterable.Type) as? any Collection,
               let suits = suitAllCases as? [Suit],
               let ranks = rankAllCases as? [Rank] {
                for suit in suits {
                    for rank in ranks {
                        allCards.append(PlayingCard(rank: rank, suit: suit))
                    }
                }
            } else {
                let allSuits: [Suit] = [.clubs, .diamonds, .hearts, .spades]
                let allRanks: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten,
                                        .jack, .queen, .king, .ace]
                for suit in allSuits {
                    for rank in allRanks {
                        allCards.append(PlayingCard(rank: rank, suit: suit))
                    }
                }
            }
            #else
            let allSuits: [Suit] = [.clubs, .diamonds, .hearts, .spades]
            let allRanks: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten,
                                    .jack, .queen, .king, .ace]
            for suit in allSuits {
                for rank in allRanks {
                    allCards.append(PlayingCard(rank: rank, suit: suit))
                }
            }
            #endif

            // Exclude any cards currently in hand to prevent duplicates
            let pool = allCards.filter { !currentHand.contains($0) }.shuffled()
            newCards = Array(pool.prefix(needed))
        }

        guard newCards.count == needed else { isDealing = false; return }

        let indices = cardsToReplace.sorted()

        // Phase 1: flip to back (90 degrees) with ripple effect
        for (order, idx) in indices.enumerated() {
            let delay = Double(order) * 0.1 // 100ms delay between each card

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.18)) {
                    flipDegrees[idx] = 90
                }

                // After the first half flip completes, set new card and complete the flip
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.19) {
                    currentHand[idx] = newCards[order]

                    withAnimation(.easeIn(duration: 0.22)) {
                        flipDegrees[idx] = 180
                    }

                    // Reset rotation back to 0 (front) after the second half completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.23) {
                        flipDegrees[idx] = 0

                        // Only clear selections and end dealing after the last card is done
                        if order == indices.count - 1 {
                            selectedCards.removeAll()
                            isDealing = false
                        }
                    }
                }
            }
        }
    }
    private func evaluateCurrentHand() -> String {
        let hand = Hand(cards: currentHand)
        return hand.evaluate().description
    }
}

// MARK: - Perspective support for more realistic 3D flips
private struct CATransform3DPerspectiveModifier: ViewModifier {
    let distance: CGFloat

    func body(content: Content) -> some View {
        content.background(PlatformPerspectiveApplier(distance: distance))
    }

    #if canImport(UIKit)
    private struct PlatformPerspectiveApplier: UIViewRepresentable {
        let distance: CGFloat

        func makeUIView(context: Context) -> UIView { UIView() }
        func updateUIView(_ view: UIView, context: Context) {
            var transform = CATransform3DIdentity
            transform.m34 = -1 / max(distance, 0.001)
            view.superview?.layer.sublayerTransform = transform
        }
    }
    #elseif canImport(AppKit)
    private struct PlatformPerspectiveApplier: NSViewRepresentable {
        let distance: CGFloat

        func makeNSView(context: Context) -> NSView { NSView() }
        func updateNSView(_ view: NSView, context: Context) {
            var transform = CATransform3DIdentity
            transform.m34 = -1 / max(distance, 0.001)
            view.superview?.layer?.sublayerTransform = transform
        }
    }
    #endif
}

private extension View {
    func perspective(_ distance: CGFloat) -> some View {
        modifier(CATransform3DPerspectiveModifier(distance: distance))
    }
}

#endif
