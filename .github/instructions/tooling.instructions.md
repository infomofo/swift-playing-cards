---
applyTo: "**"
excludeAgent: "cloud-agent"
---

# Tooling Review Rules

## SwiftLint in CI

Before flagging that the lint CI workflow needs the Swift toolchain installed:

1. Check whether the mise backend for SwiftLint installs a static binary. The `aqua:realm/SwiftLint` backend (the mise registry default) provides a `swiftlint-static` build on Linux with no Swift runtime dependency.
2. Confirm by inspecting the SwiftLint GitHub release assets for the platform. If the asset is named `swiftlint-static` or is a fully self-contained binary, no Swift toolchain is needed.
3. Only flag a missing Swift toolchain if you can show the specific binary dynamically links against Swift libraries on the target platform.

## SwiftLint pre-commit hook: pass_filenames

Before suggesting `pass_filenames: true` for the SwiftLint pre-commit hook:

1. Verify that SwiftLint rules in use do not require whole-project context. Rules like `unused_import` and cross-file analysis only work correctly when SwiftLint sees the full source tree.
2. If the project uses any project-level rules, `pass_filenames: false` is correct and intentional. Do not flag it as a performance issue without confirming no project-level rules are active.

## mise-managed tools

Tools listed in `.mise.toml` under `[tools]` are installed by `mise install`. Do not suggest installing them separately via Homebrew, apt, or pip unless the README explicitly documents that as an alternative path.

## Swift `public extension` access control

Before flagging a member declared inside a `public extension` as internal:

1. Verify Swift's access control rules. Members declared in a `public extension TypeName { ... }` are public by default -- they inherit the extension's access level.
2. Only flag a member as internal if it has an explicit narrower modifier (e.g., `internal var`, `private var`) overriding the extension's level.
3. Do not flag `public extension Foo { var bar: T { ... } }` as a visibility regression from `public struct Foo { public var bar: T { ... } }` -- both expose `bar` as public.
