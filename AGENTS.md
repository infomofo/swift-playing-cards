# AGENTS.md

## Skills

This project has task-specific skills available.

> **MANDATORY:** Before writing any code, creating any file, or running any command,
> you **MUST** first read `.claude/skills/*/SKILL.md` and check for relevant skill files.
> This step is **non-negotiable** and applies to **every task** without exception.

**Steps to follow before any task:**
1. `.claude/skills/*/SKILL.md`: discover all available skill files
2. `view` every skill file that is plausibly relevant to the task
3. Only then proceed with the task

Skipping this step is not allowed, even if you believe you already know how to do the task.
Skills encode environment-specific constraints that override general knowledge.

## Critical Rules

- **Save agent-specific learnings and worklogs in agent-specific markdown files under their respective agent directories (e.g., `.Jules/`, `.claude/`, `.copilot/`).** Do not commit other unrelated documentation files.

---

## Integrity

- Never fabricate URLs, citations, commands, CLI flags, or facts. If you can't verify it, say so.
- Investigate the problem before proposing a fix. Read configs, files, logs, and errors before suggesting changes.
- Verify commands and configs before suggesting them (read the config, run help, check docs).
- When uncertain, say "I don't know" and investigate.
- When ambiguous, ask for clarification before acting.
- Multiple valid options: present tradeoffs, let the user decide.
- Claims about third-party tools, services, APIs, or platforms: always verify via docs, web search, or CLI help before stating. If you can't verify in-session, say "I'm not sure" and offer to look it up. Never present training-data beliefs as facts.
- Transient failures (push rejected, network error, rate limit): say so and suggest a retry before proposing code changes.
- Confidence is not evidence. If your only source for a claim is training data (not something you read, ran, or searched in this session), flag it as unverified or verify it first.

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
- Remove unused code. Never commit dead code or build artifacts.
- Prefer built-in language and framework operators over new utilities.
- Don't Repeat Yourself (DRY). Factor out repeated patterns.
- Solve root causes, not symptoms.
- Read 2-3 existing examples before writing anything new. Match structure and style.
- Ensure all code is compatible with iOS 15+, watchOS 8+, macOS 12+, and Linux for CI.

## Testing Rules

- Write tests for all logic branches, including edge cases.
- Poker hand evaluation must cover: all hand types, wheel straights (A-2-3-4-5), ace-high straights, tie-breaking, and 5+ card hand evaluation (Texas Hold'em style).
- SwiftUI components: use text-based representations for validation in headless CI. No pixel-perfect image comparisons.
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

### Before Creating a PR

- Run `git log origin/<base>..HEAD --oneline` and `git diff origin/<base>...HEAD --stat`. If unrelated commits or files appear, fix the branch first.
- Always pass `--base` explicitly to `gh pr create`.

### After Creating a PR

- Run `gh pr view <n> --json baseRefName,headRefName,files` to verify base branch and changed files. Fix before presenting.

## Git Rules

### Hard Stops

- **NEVER run `git push` targeting main or master.** No exceptions. If the current branch is main/master, STOP and create a feature branch first.
- **NEVER chain `git commit` and `git push` in a single command.** They must be separate invocations so the commit output can be inspected before pushing.
- **NEVER commit without explicit approval.** After editing files, show the diff and stop. Wait for an explicit "commit", "push", "open a PR", or equivalent instruction. Silence is not approval. Approval covers only the exact diff shown at the moment it was given -- any subsequent edit requires showing a new diff and getting new approval.
- **NEVER run `git push --force`, `git push --force-with-lease`, or any force push variant.** If a push is rejected or history has diverged, STOP and ask the user what to do.
- **NEVER run `git commit --amend`.** Always create new commits. If the user explicitly says "amend," confirm which commit before running it.
- **NEVER run `git reset --hard` on a branch that has been pushed to a remote.** Use `git revert` to undo changes on remote-tracking branches.
- **NEVER rebase a PR branch for any reason.** To integrate upstream changes, run `git fetch origin` then `git merge origin/<base>`.

### Branch Awareness

The branch shown at session start may change mid-session (e.g. after a PR merge). NEVER assume you are still on the same branch. Always verify with `git branch --show-current` before any git write operation (commit, push, rebase, merge, checkout).

### Pre-commit Checklist

1. `git branch --show-current`: confirm you are on a feature branch.
2. Run lint: `mise run lint`
3. Run tests: `mise run test`
4. `git status`: check for untracked files that should not be staged.
5. `git diff --stat`: show the diff and wait for explicit approval before committing.

### Pre-push Checklist

1. Read the commit output. Verify the branch name is NOT main/master. If it says `[main ...]` or `[master ...]`, do NOT push -- alert the user immediately.
2. `git log --oneline -1` -- confirm the commit message and branch.
3. Only then run `git push`.

## Communication

- Do not suggest next steps. Do the work and stop.
- Do not praise or comment on the quality of the user's questions or prompts. This includes validating phrases like "Fair point", "Good question", "Great idea", etc.
- When you make a mistake, own it and fix the root cause. If you violated a rule and the violation was predictable, the rule needs to be strengthened -- propose the fix and apply it.

## GitHub Identity

- Never post as the user on GitHub (comments, reviews, issues). Present proposed replies in chat. Creating PRs, updating PR descriptions, and authoring commits are fine.

## Writing Style

All prose (code comments, commit messages, PR descriptions, documentation):

- No em-dashes. Use commas or restructure.
- No hedging ("arguably", "could potentially", "generally speaking").
- No sycophantic openers or filler transitions.
- Terse, direct, first-person. Vary sentence length. State positions.
- Matter-of-fact language in user-facing content. No marketing language.

**Banned patterns:**

- Contrast framing ("not X but Y", "not only X but also Y").
- Signposting openers ("It's worth noting", "It's important to remember", "It bears mentioning").
- Transition stacking ("However,", "Additionally,", "Moreover,", "Furthermore,", "Consequently,").
- Summary closers ("In conclusion,", "To summarize,", "At the end of the day,").
- Restating the same point rephrased, or ending a section by summarizing what was just said.
- Hedging ("some might say", "arguably", "could potentially", "generally speaking", "to some extent", "if needed", "if possible", "wherever you can").
- Meta-commentary on significance ("the key takeaway is", "this matters because", "here's where it gets interesting", "the important part is this").
- Manufactured hooks ("In today's [fast-paced/rapidly evolving] world", "In an increasingly X world").
- Collaborative framing ("Let's dive in", "Let's break down", "Let's explore").
- False intimacy ("Here's the thing", "Here's an uncomfortable truth", "I'll be honest").
- Sycophantic openers ("That's a great question", "I'm glad you asked", "I was hoping someone would ask about that").
- Reflexive rule of three (always grouping into exactly three items).
- "Whether" summaries ("Whether you're looking for X, Y, or Z, there's something for everyone").
- Explaining significance instead of demonstrating it ("This is important because", "This cannot be overstated").
- Vague attribution ("Research suggests", "Experts believe") without a source.

**Banned words:** delve, tapestry, landscape (metaphorical), nuanced, pivotal, robust, intricate, comprehensive (filler), vital, transformative, dynamic, realm, embark, vibrant, crucial, leverage, foster, harness, bolster, underscore, seamless, streamlined, cutting-edge, groundbreaking, game-changing, innovative, holistic, multifaceted, navigate (figurative), notably, genuinely/truly (as intensifiers), nestled.
