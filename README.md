# PlayingCard Swift Package

[![CI](https://github.com/infomofo/swift-playing-cards/actions/workflows/test.yml/badge.svg)](https://github.com/infomofo/swift-playing-cards/actions/workflows/test.yml)

A comprehensive Swift package for implementing video poker games on iOS devices (iPhone, iPad, Apple Watch) and other Apple platforms.

This package provides all the essential functionality needed to build poker games, including card representation, deck management, hand evaluation, and SwiftUI display components.

## Features

### Core Functionality
- **Playing Cards**: Complete representation of playing cards with ranks (2-A) and suits (♠️♥️♦️♣️)
- **Deck Management**: Standard 52-card deck with shuffle and deal operations
- **Hand Evaluation**: Full poker hand analysis including:
  - High Card, Pair, Two Pair, Three of a Kind
  - Straight, Flush, Full House, Four of a Kind
  - Straight Flush, Royal Flush
- **Hand Comparison**: Complete poker hand ranking system

### UI Components
- **DisplayCard**: SwiftUI component for showing cards in a compact format
- **InteractiveCard**: SwiftUI component with selection and animation capabilities

### Platform Support
- iOS 15.0+
- macOS 12.0+
- watchOS 8.0+
- tvOS 15.0+

## Usage Examples

### Basic Card and Deck Operations
```swift
import PlayingCard

// Create a deck and shuffle
var deck = Deck()
deck.shuffle()

// Deal cards for a poker hand
var hand = Hand()
let cards = deck.dealCards(5)
hand.addCards(cards)

// Evaluate the hand
let handType = hand.evaluate()
print("You have: \(handType.description)")
```

### Poker Hand Evaluation
```swift
// Create a specific hand
let royalFlush = Hand(cards: [
    PlayingCard(rank: .ten, suit: .spades),
    PlayingCard(rank: .jack, suit: .spades),
    PlayingCard(rank: .queen, suit: .spades),
    PlayingCard(rank: .king, suit: .spades),
    PlayingCard(rank: .ace, suit: .spades)
])

print(royalFlush.evaluate()) // .royalFlush
```

### Card Replacement (Draw Poker)
```swift
var hand = Hand(cards: dealCards)

// Replace cards at positions 1 and 3 with new cards
let newCards = deck.dealCards(2)
hand.replaceCards(at: [1, 3], with: newCards)
```

## Video Poker Implementation

This library provides all components needed for video poker games:
- Deal initial 5-card hands
- Allow player to hold/discard cards
- Replace discarded cards with new ones from deck
- Evaluate final hands and determine payouts
- Display cards with interactive UI components

## Agentic Coding

For agentic coding instructions and automation guidelines, see [AGENTS.md](./AGENTS.md).

## Linting and Formatting

This project uses SwiftLint and swift-format to enforce code style and maintain consistent formatting.

### Running the linter

```bash
# Run linting checks
make lint

# Auto-fix linting issues
make lint-fix
```

### Running the formatter

```bash
# Check code formatting
make format-check

# Auto-format code
make format
```

### CI Integration

Code quality checks are automatically run in CI/CD pipelines. The workflow will:
1. Install SwiftLint and swift-format on macOS runners
2. Run linting checks with comprehensive rules
3. Verify consistent code formatting
4. Build the project
5. Run all tests

The build will fail if any linting or formatting issues are found.

### Linting Rules

The project uses a comprehensive set of SwiftLint rules focused on:
- Code quality and consistency
- Whitespace and formatting
- Swift best practices
- Complexity management
- Proper naming conventions

Configuration is stored in `.swiftlint.yml`.

### Formatting Rules

Code formatting is enforced using swift-format with configuration in `.swift-format`. The formatting rules ensure:
- Consistent indentation (2 spaces)
- Maximum line length of 120 characters
- Proper spacing and line breaks
- Consistent import ordering
- Swift naming conventions

### Running Tests
```bash
swift test --parallel
```

### Visual Component Testing
The package includes automated visual testing for SwiftUI components:
```bash
swift test --filter DisplayCardSnapshotTests
```

This test generates sample images of playing cards using the `DisplayCard` component, including:
- Individual cards (Ace of Spades, King of Hearts, etc.)
- Complete poker hands with evaluation labels
- Various card combinations for visual verification

Generated images are automatically uploaded as CI artifacts and posted as PR comments during the build process.

### Test Coverage
- **37 total tests** covering all poker functionality
- Complete hand evaluation testing for all 10 poker hand types
- Deck operations and shuffle verification  
- Edge cases like wheel straights (A-2-3-4-5)
- Visual component rendering tests

Run the test suite:
```bash
swift test --enable-test-discovery
```

## License

Licensed under Apache License v2.0 with Runtime Library Exception.
