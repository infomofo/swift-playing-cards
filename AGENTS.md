# Agentic Coding Instructions

This repository is prepared for agentic coding and automation using GitHub Actions and Jules. Please follow these guidelines when contributing or automating tasks:

## Conventions

- All code changes should be documented with concise commit messages.
- Use clear, descriptive comments for all public APIs and exported functions.
- Prefer small, focused pull requests.

## Documentation

- Update `README.md` with any new features or changes.
- Document public types and methods using Swift's doc comment syntax (`///`).
- Add usage examples for new APIs.

## Automation

- Ensure all code passes tests (`make test`) before merging.
- Use GitHub Actions for CI/CD. See `.github/workflows/` for workflow files.
- For agentic tasks, reference this file for process and standards.

## GitHub Actions Best Practices

### CRITICAL: Don't Overengineer CI for Simple Projects

**The biggest mistake agents make with Swift CI is overengineering.** Before adding complexity, research what successful projects actually do:

- **Alamofire** (42k stars): Uses direct `xcodebuild` with 10-minute timeouts, NO setup actions
- **Simple projects**: Use built-in Swift on macOS runners, NO setup actions
- **Key insight**: macOS runners already have Swift installed - don't try to "fix" what isn't broken

### For Simple Swift Package Projects (like this one):

```yaml
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

## Agentic Coding

- Agents should use this file as the source of truth for coding standards and automation.
- **When in doubt, SIMPLIFY** - especially for CI configuration.
- Research successful projects before adding complexity.
- For Jules integration, ensure workflows and scripts are idempotent and well-documented.

## Useful Commands

- `make build` - Build the project.
- `make test` - Run all tests.
- `make release` - Build in release mode.
- `make clean` - Remove build artifacts.

## Contact

For questions, open an issue or contact the maintainers.
