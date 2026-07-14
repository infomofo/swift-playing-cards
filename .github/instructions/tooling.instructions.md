---
applyTo: "**"
excludeAgent: "cloud-agent"
---

# Tooling Review Rules

## SwiftLint in CI

Before flagging that the lint CI workflow needs the Swift toolchain installed:

1. Verify that the mise `aqua:realm/SwiftLint` backend installs a static binary (`swiftlint-static`) with no Swift runtime dependency.
2. The lint workflow uses `jdx/mise-action` + `mise exec -- swiftlint lint`, which resolves the static binary — no separate Swift install step is required.
3. Only flag a missing Swift toolchain in `lint.yml` if you can confirm the installed binary dynamically links against Swift libraries on Ubuntu.

## mise-managed tools

Tools listed in `.mise.toml` under `[tools]` are installed by `mise install`. Do not suggest installing them separately via Homebrew, apt, or pip unless the README explicitly documents that as an alternative path.
