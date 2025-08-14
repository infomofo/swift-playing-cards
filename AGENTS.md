# Agentic Coding Instructions

This repository is prepared for agentic coding and automation using GitHub Actions and Jules. Please follow these guidelines when contributing or automating tasks for the Swift playing cards library, specifically designed for video poker games on iOS devices.

## Purpose & Scope

This package is specifically designed to support **video poker games** on **iOS devices** (iPhone, iPad, Apple Watch). All features and enhancements should be evaluated through this lens.

### Core Requirements for Video Poker
- Standard 52-card deck management
- Complete poker hand evaluation (high card through royal flush)
- Card dealing and replacement mechanisms
- Hand comparison and ranking
- SwiftUI display components for cards

## Conventions

- All code changes should be documented with concise commit messages.
- Use clear, descriptive comments for all public APIs and exported functions.
- Prefer small, focused pull requests.
- Follow Swift naming conventions and idiomatic patterns.

## Documentation

- Update `README.md` with any new features or changes.
- Document public types and methods using Swift's doc comment syntax (`///`).
- Add usage examples for new APIs, especially poker-specific functionality.
- Include code examples that demonstrate video poker use cases.

## Testing Strategy

- Comprehensive unit tests for all poker hand evaluations
- Test edge cases (wheel straights, ace-high straights, etc.)
- Performance tests for deck shuffling and hand evaluation
- UI component tests (when SwiftUI is available)
- Integration tests for common poker game scenarios

## Platform Considerations

### Primary Targets
- iOS 15.0+ (iPhone, iPad)
- watchOS 8.0+ (Apple Watch)
- macOS 12.0+ (for development and testing)

### SwiftUI Components
- SwiftUI components may not be available in all build environments
- Core poker functionality must work independently of UI components
- Use availability checks for platform-specific features

## Automation

- Ensure all code passes tests (`make test` or `swift test --enable-test-discovery`) before merging.
- Use GitHub Actions for CI/CD. See `.github/workflows/` for workflow files.
- For agentic tasks, reference this file for process and standards.
- Test discovery should be enabled for comprehensive test coverage.

## Agentic Coding Guidelines

- Agents should use this file as the source of truth for coding standards and automation.
- Focus on poker game functionality when adding new features.
- Consider iOS platform limitations and capabilities.
- Prioritize performance for real-time game scenarios.
- For Jules integration, ensure workflows and scripts are idempotent and well-documented.

## Poker-Specific Development

### Hand Evaluation Priority
1. Correctness over performance (but both are important)
2. Support for 5+ card evaluation (Texas Hold'em style)
3. Proper handling of edge cases (wheel, etc.)
4. Clear ranking system for tie-breaking

### UI Component Guidelines
- Cards should be easily readable on small screens (Apple Watch)
- Interactive components should support touch gestures
- Animations should be smooth but not distracting
- Consider accessibility (VoiceOver support)

## Useful Commands

- `swift build` - Build the project.
- `swift test --enable-test-discovery` - Run all tests with discovery.
- `swift test --filter [TestName]` - Run specific tests.
- `make build` - Build the project (if Makefile exists).
- `make test` - Run all tests (if Makefile exists).
- `make release` - Build in release mode.
- `make clean` - Remove build artifacts.

## Performance Considerations

- Deck shuffling should use cryptographically secure randomization
- Hand evaluation should be optimized for repeated calls
- Memory usage should be minimal for watchOS compatibility
- Consider caching hand evaluations for repeated hands

## Contact

For questions, open an issue or contact the maintainers.
