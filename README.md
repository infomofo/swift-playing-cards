# PlayingCard Swift Package

This is a package that has functions for working with playing cards, and decks.

Decks will have operations that allow you to shuffle, deal cards.

## Package Structure

This package is organized into two main products:

- **PlayingCard**: Core playing card functionality (suits, ranks, cards, hands) with no UI dependencies
- **PlayingCardUI**: SwiftUI components for displaying and interacting with cards

## Usage

For basic card functionality:
```swift
import PlayingCard

let card = PlayingCard(rank: .ace, suit: .spades)
let hand = Hand()
```

For SwiftUI components:
```swift
import PlayingCard
import PlayingCardUI // Optional UI components

DisplayCard(card: myCard)
InteractiveCard(card: myCard)
```

## CI/CD Optimization

The CI build system only builds the core PlayingCard library to prevent SwiftUI-related compilation hangs on headless macOS runners. The SwiftUI components remain available for local development and are built as a separate target when needed.

## Agentic Coding

For agentic coding instructions and automation guidelines, see [AGENTS.md](./AGENTS.md).
