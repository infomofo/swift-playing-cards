#if canImport(SwiftUI)
    import SwiftUI

    /// A card slot that animates between face-down and face-up using a Y-axis flip.
    ///
    /// Pass a `PlayingCard` to reveal it face-up; pass `nil` to show it face-down.
    /// Uses `.task(id: card)` so rapid or duplicate value changes cancel the previous
    /// animation rather than stacking flips.
    ///
    /// Example (video poker slot in compact watch layout):
    /// ```swift
    /// CardSlot(card: viewModel.slots[index])
    ///     .frame(width: 28, height: 36)
    /// ```
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public struct CardSlot: View {
        let card: PlayingCard?

        @State private var rotation: Double = 0
        @State private var showFront: Bool = false
        @State private var displayedCard: PlayingCard?

        private static let halfFlip: Double = 0.15

        public init(card: PlayingCard?) {
            self.card = card
        }

        public var body: some View {
            ZStack {
                CardBack()
                    .opacity(showFront ? 0 : 1)
                if let displayedCard {
                    DisplayCard(card: displayedCard, displayMode: .compact)
                        .opacity(showFront ? 1 : 0)
                }
            }
            .frame(width: 28, height: 36)
            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
            .task(id: card) {
                await handleCardChange(to: card)
            }
        }

        // MARK: - Animation

        private func handleCardChange(to newCard: PlayingCard?) async {
            if let newCard {
                displayedCard = newCard
                await flipUp()
            } else if displayedCard != nil {
                await flipDown()
                if !Task.isCancelled {
                    displayedCard = nil
                }
            }
        }

        private func flipUp() async {
            withAnimation(.easeIn(duration: Self.halfFlip)) { rotation = 90 }
            try? await Task.sleep(nanoseconds: nanos(Self.halfFlip))
            if Task.isCancelled {
                rotation = 0; return
            }
            showFront = true
            rotation = -90
            withAnimation(.easeOut(duration: Self.halfFlip)) { rotation = 0 }
            try? await Task.sleep(nanoseconds: nanos(Self.halfFlip))
        }

        private func flipDown() async {
            withAnimation(.easeIn(duration: Self.halfFlip)) { rotation = 90 }
            try? await Task.sleep(nanoseconds: nanos(Self.halfFlip))
            if Task.isCancelled {
                rotation = 0; return
            }
            showFront = false
            rotation = -90
            withAnimation(.easeOut(duration: Self.halfFlip)) { rotation = 0 }
            try? await Task.sleep(nanoseconds: nanos(Self.halfFlip))
        }

        private func nanos(_ seconds: Double) -> UInt64 {
            UInt64(seconds * 1_000_000_000)
        }
    }

    // MARK: - Card Back

    /// The back face of a playing card, shown when a slot is face-down.
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public struct CardBack: View {
        public init() {}

        public var body: some View {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.85), Color.indigo.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing,
                    ),
                )
                .frame(width: 28, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                        .padding(3),
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1),
                )
        }
    }

    // MARK: - Preview

    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    struct CardSlot_Previews: PreviewProvider {
        static var previews: some View {
            HStack(spacing: 4) {
                CardSlot(card: PlayingCard(rank: .ace, suit: .spades))
                CardSlot(card: PlayingCard(rank: .king, suit: .hearts))
                CardSlot(card: nil)
                CardSlot(card: PlayingCard(rank: .two, suit: .clubs))
                CardSlot(card: nil)
            }
            .padding()
            .previewDisplayName("Card Slots (compact)")
        }
    }
#endif
