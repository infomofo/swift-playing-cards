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
