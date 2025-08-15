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

### Timeout Management
- **Always set timeouts** to prevent runaway jobs that consume resources and cost money
- Use `timeout-minutes` at both job and step levels where appropriate:
  - **Job-level**: 15-30 minutes for most Swift projects
  - **Build step**: 10-15 minutes for typical Swift builds
  - **Test step**: 5-10 minutes for test suites
- For complex projects or benchmarks, may need 60+ minutes

### Caching Strategy
- **Cache Swift packages** to improve build times:
  ```yaml
  - name: Cache Swift packages
    uses: actions/cache@v4
    with:
      path: |
        .build
        ~/.cache/org.swift.swiftpm
      key: ${{ runner.os }}-swift-${{ hashFiles('Package.swift', 'Package.resolved') }}
      restore-keys: |
        ${{ runner.os }}-swift-
  ```

### Swift Build Optimization
- Use `swift build` and `swift test --parallel` for standard builds
- Consider `swift build -c release` for release builds
- Monitor for known issues with `swift-actions/setup-swift` action
- For simple projects, builds should complete within 5-15 minutes on macOS runners

### Common Issues and Solutions
- **Long build times**: Likely due to package resolution or dependency issues
- **Setup failures**: GPG import issues with swift-actions, consider alternative setup methods
- **Resource exhaustion**: Set appropriate timeouts to prevent billing issues
- **Inconsistent builds**: Use caching and pin Swift versions for reproducibility

## Agentic Coding

- Agents should use this file as the source of truth for coding standards and automation.
- For Jules integration, ensure workflows and scripts are idempotent and well-documented.

## Useful Commands

- `make build` - Build the project.
- `make test` - Run all tests.
- `make release` - Build in release mode.
- `make clean` - Remove build artifacts.

## Contact

For questions, open an issue or contact the maintainers.
