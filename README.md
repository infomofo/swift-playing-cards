# PlayingCard Swift Package

A comprehensive Swift library for representing playing cards, designed for video poker games and other card game applications. This library provides robust poker hand evaluation, deck management, and SwiftUI display components optimized for iOS devices including Apple Watch.

## Features

### Core Data Models
- **PlayingCard**: Represents a single playing card with rank and suit
- **Suit**: Four standard suits (♠️ Spades, ♥️ Hearts, ♦️ Diamonds, ♣️ Clubs) with proper color coding
- **Rank**: Thirteen standard ranks (2-10, J, Q, K, A) with proper poker ordering
- **Deck**: Standard 52-card deck with cryptographically secure shuffling and dealing
- **Hand**: Collection of cards with comprehensive poker hand evaluation

### Poker Hand Evaluation
Complete poker hand evaluation supporting:
- High Card, Pair, Two Pair, Three of a Kind
- Straight (including A-2-3-4-5 wheel), Flush, Full House
- Four of a Kind, Straight Flush, Royal Flush
- Support for 5+ card hands (Texas Hold'em style)
- Proper hand comparison and ranking

### SwiftUI Display Components
- **Compact Mode**: Optimized for Apple Watch (28×36px, fits 5 cards wide)
- **Large Mode**: Optimized for iPhone/iPad (120×168px)
- **Number Cards**: Suit icons arranged in mahjong-style grid layouts
- **Face Cards**: Custom emoji representations with proper skin tones per suit
  - Queens: 👸🏼♥️ 👸🏻♠️ 👸🏽♣️ 👸🏾♦️
  - Kings: 🤴🏼♥️ 🤴🏻♠️ 🤴🏽♣️ 🤴🏾♦️

## Installation

### Requirements
- **iOS**: 15.0+
- **macOS**: 12.0+
- **watchOS**: 8.0+
- **Swift**: 5.9+

### Swift Package Manager

Add this to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/infomofo/swift-playing-cards-2.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/infomofo/swift-playing-cards-2.git`

## Development Environment Setup

### macOS Development

1. **Install Swift**: Swift comes bundled with Xcode
   ```bash
   # Install Xcode from App Store or developer portal
   xcode-select --install
   
   # Verify Swift installation
   swift --version
   ```

2. **Clone and build**:
   ```bash
   git clone https://github.com/infomofo/swift-playing-cards-2.git
   cd swift-playing-cards-2
   swift build
   swift test
   ```

3. **Xcode development**:
   ```bash
   swift package generate-xcodeproj
   open PlayingCard.xcodeproj
   ```

### Ubuntu Development

1. **Install Swift**:
   ```bash
   # Ubuntu 20.04/22.04
   wget https://download.swift.org/swift-6.1.2-release/ubuntu2004/swift-6.1.2-RELEASE-ubuntu20.04.tar.gz
   tar xzf swift-6.1.2-RELEASE-ubuntu20.04.tar.gz
   sudo mv swift-6.1.2-RELEASE-ubuntu20.04 /opt/swift
   echo 'export PATH=/opt/swift/usr/bin:$PATH' >> ~/.bashrc
   source ~/.bashrc
   
   # Install dependencies
   sudo apt update
   sudo apt install clang libicu-dev pkg-config libssl-dev zlib1g-dev
   ```

2. **Clone and build**:
   ```bash
   git clone https://github.com/infomofo/swift-playing-cards-2.git
   cd swift-playing-cards-2
   swift build
   swift test
   ```

## Quick Start

### Basic Usage

```swift
import PlayingCard

// Create and shuffle a deck
var deck = Deck()
deck.shuffle()

// Deal a poker hand
var hand = Hand()
hand.addCards(deck.dealCards(5))

// Evaluate the hand
let handType = hand.evaluate()
print("You have: \(handType)")  // e.g., "You have: Pair"

// Individual card access
let card = PlayingCard(rank: .ace, suit: .spades)
print(card)  // "♠️ A"
```

### SwiftUI Display

```swift
import SwiftUI
import PlayingCard

struct ContentView: View {
    let hand = [
        PlayingCard(rank: .ace, suit: .spades),
        PlayingCard(rank: .king, suit: .hearts),
        PlayingCard(rank: .queen, suit: .diamonds),
        PlayingCard(rank: .jack, suit: .clubs),
        PlayingCard(rank: .ten, suit: .spades)
    ]
    
    var body: some View {
        // Large cards for iPhone/iPad
        HStack {
            ForEach(hand, id: \.description) { card in
                DisplayCard(card: card, displayMode: .large)
            }
        }
        
        // Compact cards for Apple Watch
        HStack {
            ForEach(hand, id: \.description) { card in
                DisplayCard(card: card, displayMode: .compact)
            }
        }
    }
}
```

### Video Poker Example

```swift
import PlayingCard

// Video poker draw scenario
var deck = Deck()
deck.shuffle()

var hand = Hand()
hand.addCards(deck.dealCards(5))

print("Initial hand: \(hand.handCards)")
print("Hand type: \(hand.evaluate())")

// Replace specific cards (e.g., discard indices 1 and 3)
let discardIndices = [1, 3]
let newCards = deck.dealCards(discardIndices.count)
hand.replaceCards(at: discardIndices, with: newCards)

print("Final hand: \(hand.handCards)")
print("Final hand type: \(hand.evaluate())")
```

## Testing

Run the comprehensive test suite:

```bash
swift test                          # Run all tests
swift test --filter HandTests      # Run specific test class
swift test --parallel              # Run tests in parallel
```

Generate sample card representations:
```bash
swift test --filter testGenerateSampleCardImages
ls card-images/                     # View generated card descriptions
```

## Architecture

The library is designed with clear separation of concerns:

- **Core Models** (`Suit`, `Rank`, `PlayingCard`): Immutable value types with proper `Comparable` and `Hashable` conformance
- **Game Logic** (`Deck`, `Hand`): Mutable reference types for game state management  
- **UI Components** (`DisplayCard`): SwiftUI views with conditional compilation for platform availability
- **Algorithms**: Efficient poker hand evaluation using bit manipulation and combinatorics

## Performance

- **Deck shuffling**: O(n) Fisher-Yates algorithm with cryptographically secure randomization
- **Hand evaluation**: O(1) for 5-card hands, O(C(n,5)) for larger hands using combination generation
- **Memory usage**: Optimized for watchOS constraints (< 1MB typical usage)
- **UI rendering**: Hardware-accelerated SwiftUI with efficient layout calculations

## Contributing

See [AGENTS.md](./AGENTS.md) for development guidelines and automation instructions.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Agentic Coding

For agentic coding instructions and automation guidelines, see [AGENTS.md](./AGENTS.md).
