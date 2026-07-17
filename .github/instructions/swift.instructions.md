---
applyTo: "**/*.swift"
excludeAgent: "coding-agent"
---

# Swift Code Review Instructions

## Heap Allocation in Hot Loops

Before flagging heap allocation (e.g., `[T](repeating:count:)`, array literals, `Array(...)`) inside a hot loop as a performance defect:

1. Run the profiler or a dedicated benchmark and capture output showing the allocation site causes a measurable regression (wall-clock time, allocations/s, or memory pressure).
2. Include the measurement in your comment. "Will likely dominate runtime" or "adds significant overhead" without data is not sufficient evidence.
3. If you cannot produce a measurement, propose a benchmark test instead of a code change comment.

Do not flag small fixed-size array allocations in Swift as defects based on speculation alone. The Swift compiler and allocator optimize many short-lived small arrays; actual impact must be demonstrated before requesting a rewrite.

## Explicit `self.` in Closures

Before flagging a missing `self.` qualifier in a closure, verify that the enclosing type is a class or actor. Swift does not require explicit `self` capture for value types (structs and enums); the requirement is specific to reference types to surface potential retain cycles. If the type is a struct or enum, do not comment on the absence of `self.`.
