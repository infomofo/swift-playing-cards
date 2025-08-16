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
- **Headless environments**: macOS CI runners don't have display servers, making image rendering unreliable
- **NSHostingView limitations**: Complex SwiftUI-to-image conversion often fails in headless CI
- **Platform availability**: SwiftUI features vary significantly between iOS/macOS versions

**Best Practices for UI Tests in CI:**

1. **Test component instantiation, not rendering**:
   ```swift
   func testDisplayCardCreation() {
       let card = PlayingCard(rank: .ace, suit: .spades)
       let view = DisplayCard(card: card)
       XCTAssertNotNil(view) // This works reliably
   }
   ```

2. **Use modern SwiftUI rendering APIs with fallbacks**:
   ```swift
   // Prefer SwiftUI.ImageRenderer (macOS 13+) over NSHostingView
   if #available(macOS 13.0, *) {
       let renderer = SwiftUI.ImageRenderer(content: view)
       // Handle nil gracefully - CI may not support rendering
   }
   ```

3. **Create robust tests that work in CI**:
   - Always provide fallback mechanisms for image generation failures
   - Test the component logic, not just visual output
   - Use placeholder content when actual rendering fails
   - Add comprehensive logging to debug CI issues

4. **Design for CI limitations**:
   - Don't require pixel-perfect image comparisons in CI
   - Focus on testing that components can be created and configured correctly
   - Use artifacts and manifest files to communicate results even when rendering fails

#### Test Discovery and Execution

**CRITICAL: Test your CI scenario locally before committing**

Before submitting changes that involve CI workflows, especially those with SwiftUI or platform-specific code:

1. **Test the exact same commands CI will run**:
   ```bash
   # Run the same test filter CI uses
   swift test --filter PlayingCardTests.DisplayCardSnapshotTests.testGenerateSampleCardImages
   
   # Check if your test creates the expected output files
   ls -la card-images/
   ```

2. **Simulate CI environment limitations**:
   - Test on the same platform as CI (macOS for SwiftUI tests)
   - Consider that CI runs in headless mode (no display)
   - Test with the same macOS version specified in your workflow

3. **Verify file system expectations**:
   ```bash
   # Your workflow expects these paths to exist
   ls -la card-images/
   cat card-images/manifest.txt
   ```

4. **Design tests to be bulletproof in CI**:
   - Always create expected directories and files, even when core functionality fails
   - Use multiple fallback layers for file creation
   - Log extensively to help debug CI failures
   - Test assertions should focus on what CI workflows need, not perfect functionality

5. **Embedding Images in PR Comments**:
   - Generate actual PNG files, not text placeholders, for embedding in PR comments
   - Commit images temporarily to repository for GitHub raw content URL access
   - Use GitHub's file URLs: `https://github.com/owner/repo/raw/branch/path/to/image.png`
   - Add cleanup workflows to remove images after PR closure
   - Consider image file sizes to avoid repository bloat

**CRITICAL: Common CI Test Failures and How to Prevent Them**

1. **Test Discovery Issues**:
   - Problem: `swift test --filter TestName` finds no tests
   - Cause: Conditional compilation (`#if canImport(SwiftUI)`) hides tests on incompatible platforms
   - Solution: Test locally on the same platform as CI (macOS for SwiftUI tests)

2. **SwiftUI Rendering Failures**:
   - Problem: `ImageRenderer` returns nil in headless CI environments  
   - Cause: No display server or graphics context in CI
   - Solution: Always provide fallback content creation

3. **File System Permission Issues**:
   - Problem: Cannot create directories or write files
   - Cause: Working directory assumptions or permission restrictions
   - Solution: Use relative paths, create directories with error handling

4. **Test Hanging or Timeout**:
   - Problem: Tests never complete or hit workflow timeouts
   - Cause: SwiftUI views trying to render in headless environment
   - Solution: Add timeouts, skip complex rendering, use XCTSkip for unsupported platforms

5. **Swift Concurrency (@MainActor) Issues**:
   - Problem: `main actor-isolated property 'X' can not be mutated from a nonisolated context`
   - Cause: SwiftUI.ImageRenderer properties require MainActor context in Swift 5.5+
   - Solution: Mark test functions with `@MainActor` or use `await MainActor.run { }`
   - Example:
     ```swift
     @available(macOS 12.0, *)
     @MainActor func testGenerateImages() throws {
         let renderer = SwiftUI.ImageRenderer(content: view)
         renderer.scale = 2.0  // This now works in MainActor context
         if let nsImage = renderer.nsImage { /* ... */ }
     }
     ```

**Prevention Strategy for Agents:**

```bash
# ALWAYS run these commands before committing CI changes:

# 1. Test discovery works
swift test --filter YourTestName
# Should find and run the test, not "No matching test cases"

# 2. Test creates expected artifacts
ls -la expected-output-directory/
# Should show files that CI workflow expects

# 3. Test the full CI command sequence locally
make lint && make build && make test
swift test --filter SpecificTestName
# Should complete without hanging or errors

# 4. Verify CI workflow will find your outputs
if [ -d "card-images" ]; then
  echo "✅ Directory exists"
  ls -la card-images/
else
  echo "❌ Directory missing - CI will fail"
fi
```

**Anti-pattern Example (what NOT to do):**
```swift
// This will hang in CI
func testGenerateImages() {
    let view = MySwiftUIView()
    let image = view.renderToImage() // Hangs in headless CI
    XCTAssertNotNil(image) // Never reaches this line
}
```

**Robust Pattern (what TO do):**
```swift
// This works reliably in CI
func testGenerateImages() {
    let view = MySwiftUIView()
    XCTAssertNotNil(view) // Test component creation
    
    // Try rendering with fallback
    var outputCreated = false
    if let image = tryRenderImage(view) {
        saveImage(image)
        outputCreated = true
    } else {
        savePlaceholder() // Always create expected output
        outputCreated = true
    }
    
    XCTAssertTrue(outputCreated)
    XCTAssertTrue(FileManager.default.fileExists(atPath: "expected-file.png"))
}
```

**Example of robust CI test design:**
```swift
// Always create the output directory
do {
    try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
} catch {
    // Continue anyway - maybe it exists
}

// Always create some output file, even if rendering fails
var fileCreated = false

// Try primary approach
if #available(macOS 13.0, *) {
    // Attempt SwiftUI rendering
    if let imageData = try? renderImage() {
        try imageData.write(to: fileURL)
        fileCreated = true
    }
}

// Fallback approach
if !fileCreated {
    // Create placeholder content
    let placeholder = createPlaceholderData()
    try placeholder.write(to: fileURL)
    fileCreated = true
}

// Last resort: empty file
if !fileCreated {
    try Data().write(to: fileURL)
}

// Test should pass if directory and files exist, regardless of content quality
XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
```

**Running Tests Locally vs CI:**
- Use the same commands locally that CI uses: `swift test --filter TestName`
- Test on the same platform as CI when possible (macOS for SwiftUI tests)
- Platform guards (`#if os(macOS)`) should match your CI environment

**Example CI-compatible test structure:**
```swift
@available(macOS 12.0, *)
func testGenerateCardRepresentations() throws {
    #if os(macOS)
    // Test component creation
    let card = PlayingCard(rank: .ace, suit: .spades)
    let view = DisplayCard(card: card)
    XCTAssertNotNil(view)
    
    // Attempt rendering with fallback
    var success = false
    if #available(macOS 13.0, *) {
        let renderer = SwiftUI.ImageRenderer(content: view)
        if renderer.nsImage != nil {
            success = true
        }
    }
    
    // Create output regardless (placeholder if needed)
    let outputData = success ? actualImageData : placeholderData
    try outputData.write(to: outputURL)
    
    // Test passes whether rendering worked or not
    XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    #else
    throw XCTSkip("SwiftUI testing requires macOS")
    #endif
}
```

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

## GitHub Actions Best Practices

### CRITICAL: Don't Overengineer CI for Simple Projects

**The biggest mistake agents make with Swift CI is overengineering.** Before adding complexity, research what successful projects actually do:

- **Alamofire** (42k stars): Uses direct `xcodebuild` with 10-minute timeouts, NO setup actions
- **Simple projects**: Use built-in Swift on macOS runners, NO setup actions
- **Key insight**: macOS runners already have Swift installed - don't try to "fix" what isn't broken

### For Simple Swift Package Projects (like this one):

```yaml
name: Build and test Swift
on:
  pull_request:
    branches: [ "main" ]

# CRITICAL: Add permissions when your workflow needs to interact with GitHub
permissions:
  contents: read
  pull-requests: write  # Required for PR comments
  issues: write        # Required for issue comments

jobs:
  test:
    runs-on: macos-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: swift build
      - name: Run tests
        run: swift test
```

**That's it.** Don't add:
- ❌ swift-actions/setup-swift (has known reliability issues)
- ❌ Complex caching for simple projects (adds overhead)
- ❌ Overly tight timeouts (causes false failures)
- ❌ Multiple step timeouts (job timeout is sufficient)

### When to Add Complexity

Only add complexity when you have evidence it's needed:
- **Multiple platforms**: Only if you actually need Linux/Windows builds
- **Caching**: Only for projects with heavy dependencies or long build times
- **Setup actions**: Only if you need a specific Swift version not available on runners

### Common Anti-Patterns to Avoid

1. **Using swift-actions/setup-swift unnecessarily**: macOS runners have Swift built-in
2. **Adding caching prematurely**: Simple projects build in seconds without it
3. **Setting multiple timeout layers**: Just use job-level timeout
4. **Cargo-cult configuration**: Copying complex CI from large projects to simple ones
5. **Missing GitHub Actions permissions**: When workflows interact with GitHub API

### GitHub Actions Permissions Issues

**Common error**: `Resource not accessible by integration`

This happens when your workflow tries to create PR comments, update issues, or interact with GitHub API without proper permissions.

**Fix**: Add the necessary permissions to your workflow:
```yaml
permissions:
  contents: read          # Always needed for checkout
  pull-requests: write    # For PR comments, labels, etc.
  issues: write          # For issue comments, labels, etc.
  actions: read          # For downloading artifacts, reading workflow runs
```

**When you need each permission**:
- `contents: read` - Required for `actions/checkout`
- `pull-requests: write` - Creating/updating PR comments, adding labels to PRs
- `issues: write` - Creating/updating issue comments, adding labels to issues  
- `actions: read` - Downloading artifacts, reading workflow run information
- `actions: write` - Canceling workflow runs, creating artifacts

**Test locally**: Use `gh` CLI to test GitHub API interactions:
```bash
# Test if you can create a comment (requires auth)
gh pr comment 123 --body "Test comment"
```

### Debugging Swift CI Issues

When Swift builds are slow/failing:
1. **First check**: Are you using unnecessary setup actions?
2. **Second check**: Are you overcomplicating a simple build?
3. **Research**: Look at how similar-sized successful Swift projects handle CI
4. **Simplify**: Remove complexity until you find the minimum viable solution

### Timeout Guidelines
- **Simple Swift packages**: 10 minutes (enough for setup + build + test)
- **Complex projects with dependencies**: 15-30 minutes
- **Never go above 60 minutes** without strong justification

### Success Patterns from Real Projects
- **Alamofire**: 10min timeout, xcodebuild, no setup actions
- **langchain-swift**: swift-actions/setup-swift@v1, simple commands
- **Key lesson**: Successful projects keep CI simple and reliable


## Agentic Coding Guidelines

- Agents should use this file as the source of truth for coding standards and automation.
- Focus on poker game functionality when adding new features.
- Consider iOS platform limitations and capabilities.
- Prioritize performance for real-time game scenarios.
- **When in doubt, SIMPLIFY** - especially for CI configuration.
- Research successful projects before adding complexity.
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
