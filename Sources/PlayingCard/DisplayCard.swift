#if canImport(SwiftUI)
import SwiftUI

/// A SwiftUI view that displays a playing card with different size options.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct DisplayCard: View {
    let card: PlayingCard
    let displayMode: DisplayMode

    public enum DisplayMode {
        case compact  // For Apple Watch - small size to fit 5 cards wide
        case large    // For iPhone/iPad - larger detailed view
    }

    public init(card: PlayingCard, displayMode: DisplayMode = .large) {
        self.card = card
        self.displayMode = displayMode
    }

    public var body: some View {
        switch displayMode {
        case .compact:
            compactView
        case .large:
            largeView
        }
    }

    // MARK: - Compact View (Apple Watch)

    private var compactView: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(card.rank.compactDescription)
                .font(.caption2)
                .bold()
                .foregroundColor(suitColor)

            Text(card.suit.description)
                .font(.caption)
        }
        .frame(width: 28, height: 36)
        .background(Color.white)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black, lineWidth: 1)
        )
    }

    // MARK: - Large View (iPhone/iPad)

    private var largeView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 2)
                )

            VStack {
                HStack {
                    topLeftCorner
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.leading, 8)

                Spacer()

                // Card center content
                cardCenterContent

                Spacer()

                HStack {
                    Spacer()
                    bottomRightCorner
                }
                .padding(.bottom, 8)
                .padding(.trailing, 8)
            }
        }
        .frame(width: 120, height: 168)
    }

    // MARK: - Corner Views

    @ViewBuilder
    private var topLeftCorner: some View {
        VStack {
            Text(card.rank.description)
                .font(.title2)
                .bold()
                .foregroundColor(suitColor)

            // Only show suit icon for face cards and Ace
            if !isNumberCard {
                Text(card.suit.description)
                    .font(.caption)
            }
        }
    }
    @ViewBuilder
    private var bottomRightCorner: some View {
        VStack {
            // Only show suit icon for face cards and Ace
            if !isNumberCard {
                Text(card.suit.description)
                    .font(.caption)
                    .rotationEffect(.degrees(180))
            }

            Text(card.rank.description)
                .font(.title2)
                .bold()
                .foregroundColor(suitColor)
                .rotationEffect(.degrees(180))
        }
    }

    // MARK: - Card Center Content

    @ViewBuilder
    private var cardCenterContent: some View {
        switch card.rank {
        case .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten:
            // Number cards: suit icons arranged like mahjong tiles
            numberCardLayout

        case .ace, .jack:
            // Ace and Jack: large letter with centered suit
            VStack {
                Text(card.rank.description)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(suitColor)
                Text(card.suit.description)
                    .font(.title)
            }

        case .queen:
            // Queen: emoji + suit
            VStack(spacing: 4) {
                Text(queenEmoji)
                    .font(.largeTitle)
                Text(card.suit.description)
                    .font(.title2)
            }

        case .king:
            // King: emoji + suit
            VStack(spacing: 4) {
                Text(kingEmoji)
                    .font(.largeTitle)
                Text(card.suit.description)
                    .font(.title2)
            }
        }
    }

    // MARK: - Number Card Layout

    private var numberCardLayout: some View {
        let suitCount = card.rank.rawValue
        return suitIconGrid(count: suitCount)
    }

    private func suitIconGrid(count: Int) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: gridColumnCount(for: count))

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0..<count, id: \.self) { _ in
                Text(card.suit.description)
                    .font(.body)
            }
        }
        .frame(maxWidth: 80)
    }

    private func gridColumnCount(for suitCount: Int) -> Int {
        switch suitCount {
        case 2, 3: return 1
        case 4, 5, 6: return 2
        case 7, 8, 9: return 3
        case 10: return 2
        default: return 1
        }
    }

    // MARK: - Computed Properties

    private var isNumberCard: Bool {
        switch card.rank {
        case .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten:
            return true
        case .ace, .jack, .queen, .king:
            return false
        }
    }

    private var suitColor: Color {
        switch card.suit {
        case .hearts, .diamonds:
            return .red
        case .spades, .clubs:
            return .black
        }
    }

    private var queenEmoji: String {
        switch card.suit {
        case .hearts: return "👸🏼"
        case .spades: return "👸🏻"
        case .clubs: return "👸🏽"
        case .diamonds: return "👸🏾"
        }
    }

    private var kingEmoji: String {
        switch card.suit {
        case .hearts: return "🤴🏼"
        case .spades: return "🤴🏻"
        case .clubs: return "🤴🏽"
        case .diamonds: return "🤴🏾"
        }
    }
}

// MARK: - Preview

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
struct DisplayCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Large view examples
            HStack {
                DisplayCard(card: PlayingCard(rank: .ace, suit: .spades), displayMode: .large)
                DisplayCard(card: PlayingCard(rank: .king, suit: .hearts), displayMode: .large)
                DisplayCard(card: PlayingCard(rank: .queen, suit: .diamonds), displayMode: .large)
                DisplayCard(card: PlayingCard(rank: .nine, suit: .clubs), displayMode: .large)
            }
            .previewDisplayName("Large Cards")

            // Compact view examples
            HStack {
                ForEach([
                    PlayingCard(rank: .ace, suit: .spades),
                    PlayingCard(rank: .king, suit: .hearts),
                    PlayingCard(rank: .queen, suit: .diamonds),
                    PlayingCard(rank: .nine, suit: .clubs),
                    PlayingCard(rank: .two, suit: .spades)
                ], id: \.description) { card in
                    DisplayCard(card: card, displayMode: .compact)
                }
            }
            .previewDisplayName("Compact Cards (Apple Watch)")
        }
    }
}

#endif
