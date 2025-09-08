# Agentic Coding Instructions

This repository is prepared for agentic coding and automation using GitHub Actions and similar tools. Please follow these guidelines when contributing or automating tasks for the Swift playing cards library, specifically designed for video poker games on iOS devices.

## Purpose & Scope

This package is specifically designed to support **video poker games** on **iOS devices** (iPhone, iPad, Apple Watch). All features and enhancements should be evaluated through this lens.

### Core Requirements for Video Poker
- Standard 52-card deck management
- Complete poker hand evaluation (high card through royal flush)
- Card dealing and replacement mechanisms
- Hand comparison and ranking
- SwiftUI display components for cards optimized for different screen sizes

## Conventions

- All code changes should be documented with concise commit messages.
- Use clear, descriptive comments for all public APIs and exported functions.
- Prefer small, focused pull requests.
- Follow Swift naming conventions and idiomatic patterns.
- Maintain backward compatibility within major versions.

## Documentation

- Update `README.md` with any new features or changes.
- Document public types and methods using Swift's doc comment syntax (`///`).
- Add usage examples for new APIs, especially poker-specific functionality.
- Include code examples that demonstrate video poker use cases.

## Testing Strategy

### Core Testing Requirements
- Comprehensive unit tests for all poker hand evaluations
- Test edge cases (wheel straights, ace-high straights, etc.)
- Performance tests for deck shuffling and hand evaluation
- UI component tests (when SwiftUI is available)
- Integration tests for common poker game scenarios

### Platform-Specific Testing

#### SwiftUI Component Testing
When testing SwiftUI components in CI environments:

**⚠️ CRITICAL: CI Testing Reality Check**
- **Headless environments**: Linux/Windows CI runners don't have display servers, making SwiftUI image rendering unavailable
- **Platform availability**: SwiftUI features vary significantly between iOS/macOS/watchOS versions
- **Conditional compilation**: Tests may be excluded on platforms without SwiftUI support

**Best Practices for UI Tests in CI:**

1. **Test component instantiation, not rendering**:
   ```swift
   func testDisplayCardCreation() {
       let card = PlayingCard(rank: .ace, suit: .spades)
       let view = DisplayCard(card: card)
       XCTAssertNotNil(view) // This works reliably
   }
   ```

2. **Use fallback content generation**:
   ```swift
   func testGenerateCardRepresentations() throws {
       let cards = [/* test cards */]
       
       for card in cards {
           let description = generateCardDescription(card: card)
           try description.write(to: outputURL, atomically: true, encoding: .utf8)
       }
       
       // Verify text representations were created
       XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
   }
   ```

3. **Design for CI limitations**:
   - Don't require pixel-perfect image comparisons in CI
   - Focus on testing that components can be created and configured correctly
   - Use text-based representations for cross-platform compatibility
   - Add comprehensive logging to debug CI issues

#### Test Discovery and Execution

**CRITICAL: Test your CI scenario locally before committing**

Before submitting changes that involve CI workflows, especially those with SwiftUI or platform-specific code:

1. **Test the exact same commands CI will run**:
   ```bash
   # Run the same test filter CI uses
   swift test --filter PlayingCardTests.DisplayCardTests
   
   # Check if your test creates the expected output files
   ls -la card-images/
   ```

2. **Verify cross-platform compatibility**:
   ```bash
   # Test on Linux if targeting Linux CI
   docker run --rm -v $(pwd):/workspace swift:5.9 bash -c "cd /workspace && swift test"
   ```

3. **Verify file system expectations**:
   ```bash
   # Your workflow expects these paths to exist
   ls -la card-images/
   cat card-images/manifest.txt
   ```

## Platform Considerations

### Primary Targets
- **iOS** 15.0+ (iPhone, iPad)
- **watchOS** 8.0+ (Apple Watch) 
- **macOS** 12.0+ (for development and testing)
- **Linux** (for CI/CD and server deployments)

### SwiftUI Components
- SwiftUI components may not be available in all build environments
- Core poker functionality must work independently of UI components
- Use availability checks for platform-specific features:
  ```swift
  #if canImport(SwiftUI)
  // SwiftUI code here
  #endif
  ```

### Development Environment Setup

#### Required Tools
- **Swift** 5.9+
- **Xcode** 15.0+ (for iOS/macOS development)
- **Git** for version control

#### macOS Development
```bash
# Verify Xcode command line tools
xcode-select --install

# Clone and setup
git clone <repo-url>
cd swift-playing-cards-2
swift build
swift test
```

#### Ubuntu Development  
```bash
# Install Swift (example for Ubuntu 20.04)
wget https://download.swift.org/swift-6.1.2-release/ubuntu2004/swift-6.1.2-RELEASE-ubuntu20.04.tar.gz
tar xzf swift-6.1.2-RELEASE-ubuntu20.04.tar.gz
sudo mv swift-6.1.2-RELEASE-ubuntu20.04 /opt/swift
echo 'export PATH=/opt/swift/usr/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Install dependencies
sudo apt update
sudo apt install clang libicu-dev pkg-config libssl-dev zlib1g-dev

# Build and test
swift build
swift test
```

## Automation & CI/CD

### GitHub Actions Best Practices

**Keep CI workflows simple for Swift packages:**

```yaml
name: Build and Test
on: [push, pull_request]

permissions:
  contents: read

jobs:
  test:
    runs-on: macos-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: swift build
      - name: Test
        run: swift test
```

**Key principles:**
- Use built-in Swift on macOS runners (don't add unnecessary setup actions)
- Set reasonable timeouts (10-15 minutes for simple packages)
- Only add complexity when you have evidence it's needed
- Test locally with the same commands CI uses

### Common Anti-Patterns to Avoid

1. **Over-engineering CI for simple projects**: Adding complex caching, matrix builds, or setup actions when not needed
2. **Platform-specific assumptions**: Writing tests that only work on macOS but expecting them to run on Linux
3. **Image generation in headless CI**: Attempting SwiftUI rendering in environments without display servers
4. **Missing error handling**: Not providing fallbacks when platform-specific features are unavailable

## Poker-Specific Development

### Hand Evaluation Priority
1. **Correctness** over performance (but both are important)
2. Support for 5+ card evaluation (Texas Hold'em style)
3. Proper handling of edge cases (wheel straights, etc.)
4. Clear ranking system for tie-breaking

### UI Component Guidelines
- Cards should be easily readable on small screens (Apple Watch)
- Interactive components should support touch gestures
- Animations should be smooth but not distracting
- Consider accessibility (VoiceOver support)
- Optimize for different screen sizes and orientations

## Performance Considerations

- **Deck shuffling**: Use cryptographically secure randomization (Fisher-Yates algorithm)
- **Hand evaluation**: Optimize for repeated calls, consider caching for identical hands
- **Memory usage**: Minimize for watchOS compatibility
- **SwiftUI rendering**: Use efficient layouts and avoid unnecessary recomputations

## Useful Commands

### Development
```bash
swift build                    # Build the project
swift test                     # Run all tests
swift test --filter TestName   # Run specific tests
swift test --parallel          # Parallel test execution
```

### Package Management
```bash
swift package reset           # Clean build artifacts
swift package generate-xcodeproj  # Generate Xcode project
swift package dump-package    # Show package configuration
```

### Testing & Validation
```bash
# Generate sample card representations
swift test --filter testGenerateSampleCardImages

# Verify all poker hands evaluate correctly
swift test --filter HandTests

# Check SwiftUI component creation
swift test --filter DisplayCardTests
```

## Code Style & Standards

### Swift Conventions
- Use `camelCase` for variables and functions
- Use `PascalCase` for types and protocols  
- Prefer `struct` over `class` for value types
- Use explicit access control (`public`, `internal`, `private`)
- Follow Swift API Design Guidelines

### Documentation
```swift
/// Brief description of the function's purpose.
///
/// Longer description with details about behavior,
/// edge cases, and usage examples.
///
/// - Parameters:
///   - parameter1: Description of first parameter
///   - parameter2: Description of second parameter
/// - Returns: Description of return value
/// - Throws: Description of possible errors
public func exampleFunction(parameter1: Int, parameter2: String) throws -> Bool {
    // Implementation
}
```

### Error Handling
- Use Swift's `throws` and `Result` types appropriately
- Provide meaningful error messages
- Handle edge cases gracefully
- Document possible failure scenarios

## Contact & Support

For questions about agentic development or contributions:
- Open an issue for bugs or feature requests
- Use discussions for questions and suggestions
- Follow the contribution guidelines in pull requests

## Version Compatibility

- **Major versions**: Breaking changes allowed
- **Minor versions**: New features, backward compatible
- **Patch versions**: Bug fixes only
- Follow semantic versioning (semver) principles