# AGENTS.md

## Skills

This project has task-specific skills available.

> **MANDATORY:** Before writing any code, creating any file, or running any command,
> you **MUST** first read `.claude/skills/*/SKILL.md` and check for relevant skill files.
> This step is **non-negotiable** and applies to **every task** without exception.

**Steps to follow before any task:**
1. `.claude/skills/*/SKILL.md` — discover all available skill files
2. `view` every skill file that is plausibly relevant to the task
3. Only then proceed with the task

Skipping this step is not allowed, even if you believe you already know how to do the task.
Skills encode environment-specific constraints that override general knowledge.

## Critical Rules

- **Save agent-specific learnings and worklogs in agent-specific markdown files under their respective agent directories (e.g., `.Jules/`, `.claude/`, `.copilot/`).** Do not commit other unrelated documentation files.

---

## Tooling

This repo uses **mise** for task running and **prek** for git hooks. Hooks are defined in `.pre-commit-config.yaml`; prek runs them.

### Quick Commands

```bash
# First-time setup: installs SwiftLint (via mise) and git hooks (via prek)
mise install

# Build
mise run build

# Test
mise run test

# Lint (required before every PR)
mise run lint
```

`mise install` pins and downloads all tools from `.mise.toml` and then automatically runs `prek install --install-hooks` via the `postinstall` hook.

### SwiftLint

SwiftLint and SwiftFormat are managed by mise. Versions are pinned in `.mise.toml` and match CI:

```bash
mise install   # downloads SwiftLint and SwiftFormat at pinned versions
```

After install, `mise exec -- swiftlint lint` and `mise exec -- swiftformat --lint` resolve to the pinned versions. No Docker required.

### Git Hooks

`.pre-commit-config.yaml` configures: trailing whitespace, end-of-file fixes, YAML/TOML validation, merge conflict detection, and SwiftLint. The `postinstall` hook in `.mise.toml` runs `prek install --install-hooks` automatically after `mise install`, so hooks are registered as part of first-time setup.

---

## Code Rules

- Follow Swift naming conventions throughout.
- Use doc comments (`///`) on all public APIs.
- Remove unused code — never commit dead code or build artifacts.
- Prefer built-in language and framework operators over new utilities.
- Don't Repeat Yourself (DRY). Factor out repeated patterns.
- Solve root causes, not symptoms.
- Read 2-3 existing examples before writing anything new. Match structure and style.
- Ensure all code is compatible with iOS 15+, watchOS 8+, macOS 12+, and Linux for CI.

## Testing Rules

- Write tests for all logic branches, including edge cases.
- Poker hand evaluation must cover: all hand types, wheel straights (A-2-3-4-5), ace-high straights, tie-breaking, and 5+ card hand evaluation (Texas Hold'em style).
- SwiftUI components: use text-based representations for validation in headless CI — no pixel-perfect image comparisons.
- Run `swift test` before every PR. Fix all failures before submitting.

## Card and Game Logic Rules

- Use cryptographically secure shuffling (Fisher-Yates with `SystemRandomNumberGenerator` or `SecRandomCopyBytes`).
- Document all poker hand evaluation logic with usage examples for video poker scenarios.
- Optimize card display components for small screens (Apple Watch: 28×36px compact mode).

## Pull Request Rules

- Run lint and tests locally before opening a PR. Do not rely on CI to catch lint violations.
- PRs modifying logic must include tests for core behavior, boundary conditions, and edge cases.
- Always edit main documents (README.md, AGENTS.md), not separate analysis files.
- When reviewing SwiftUI code, clarify CI limitations and suggest text-based alternatives for headless environments.
- Provide code suggestions for Swift when reviewing PRs. Do not leave nitpicky comments.
- If platform-specific features (e.g., SwiftUI rendering) are unavailable in CI, propose fallback strategies and document them in the PR.
- Update README.md for any new public APIs or features.

## Git Rules

- **NEVER push to main or master directly.** Create a feature branch first.
- **NEVER commit without explicit approval.** Show the diff and wait for confirmation.
- **NEVER force push** (`--force`, `--force-with-lease`).
- **NEVER chain `git commit` and `git push`.** They must be separate commands.
- Verify branch with `git branch --show-current` before any write operation.
- Use `git revert` to undo changes on remote-tracking branches, not `git reset --hard`.

### Pre-commit Checklist

1. `git branch --show-current` — confirm you are on a feature branch.
2. Run lint: `mise run lint`
3. Run tests: `mise run test`
4. `git status` — check for untracked files that should not be staged.
5. `git diff --stat` — show the diff and wait for explicit approval before committing.

## Writing Style

All prose (code comments, commit messages, PR descriptions, documentation):

- No em-dashes. Use commas or restructure.
- No hedging ("arguably", "could potentially", "generally speaking").
- No sycophantic openers or filler transitions.
- Terse, direct, first-person. Vary sentence length. State positions.
- Matter-of-fact language in user-facing content. No marketing language.