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

## GitHub Actions Timeout Requirements

**CRITICAL**: All GitHub Actions workflows and jobs must include appropriate timeouts to prevent runaway processes and control costs:

- **Job-level timeouts**: Set `timeout-minutes` on all jobs (recommended: 15 minutes max for simple builds)
- **Step-level timeouts**: Set `timeout-minutes` on individual build/test steps that may hang
- **Swift builds**: Swift compilation can hang in CI environments, especially with SwiftUI/graphics code - limit build steps to 10 minutes max
- **Test steps**: Limit test execution to reasonable timeouts (5 minutes for unit tests)

Example timeout configuration:
```yaml
jobs:
  build:
    runs-on: macos-latest
    timeout-minutes: 15
    steps:
      - name: Build
        run: make build
        timeout-minutes: 10
      - name: Test
        run: make test
        timeout-minutes: 5
```

## Agentic Coding

- Agents should use this file as the source of truth for coding standards and automation.
- For Jules integration, ensure workflows and scripts are idempotent and well-documented.

### Fix Verification Requirements

**CRITICAL**: Never claim a fix is working without proper verification:

1. **Local Testing Required**: Before claiming any CI fix works, test the EXACT commands locally:
   - Run the same Makefile targets used in CI workflows
   - Verify build times are reasonable (should complete in seconds, not minutes)
   - Check that only intended targets are built (look for "Building..." output)

2. **Command Verification**: For Swift projects, verify:
   - `swift build --product <target>` builds only the specified target
   - No "warning: '--product' cannot be used with automatic product" messages
   - Build output shows only expected modules compiling
   - Release builds use `-O` optimization flag

3. **CI Environment Differences**: Always consider environment-specific issues:
   - Local vs CI Swift versions and SDK compatibility
   - Graphics/SwiftUI code that works locally but hangs in headless CI
   - Conditional compilation flags that may behave differently

4. **Timeout Testing**: When implementing timeout fixes:
   - Test with shorter timeouts locally to verify they work
   - Monitor GitHub Actions usage to prevent cost overruns
   - Add multiple timeout layers (job, step, command-level)

5. **Incremental Verification**: After each change:
   - Test build commands immediately  
   - Verify no regressions in existing functionality
   - Check that only minimal changes were made to achieve the goal

**Never use phrases like "Fixed in commit X" without having verified the commands work locally first.**

## Useful Commands

- `make build` - Build the project.
- `make test` - Run all tests.
- `make release` - Build in release mode.
- `make clean` - Remove build artifacts.

## Contact

For questions, open an issue or contact the maintainers.
