## 2026-07-17 - Swift Inner Loop Heap Allocations
**Learning:** In Swift, allocating arrays of even small fixed sizes (like 13-element arrays for rank frequencies) or dynamic arrays for combinations in tight, multi-million iteration loops incurs substantial heap allocation and reference counting overhead. Unrolling loops for specific draw sizes (0 to 5) and using inline insertion sort on local stack variables completely bypasses allocations, resulting in a ~7.7x speedup in release builds (10.53s to 1.36s).
**Action:** Always prefer unrolled loops, stack variables, and flat, zero-allocation switch statements when dealing with heavy combination evaluation and game theory trees.

## 2026-07-17 - Swift Task Groups vs Sequential Iteration in Combination Engines
**Learning:** For large-scale state space searches (such as the 32-mask combinations search which evaluates over 2.5 million inner-loop hands), utilizing Swift's structured concurrency (`withTaskGroup`) scales extremely well and provides a ~1.6x speedup (0.037s vs 0.059s in release build) over a pure sequential loop. The workload is heavy enough to overcome task creation/context-switching overhead on multi-core systems.
**Action:** Keep structured concurrency with Task Groups for heavy combination search tasks (> 1 million iterations), but continue avoiding allocations inside each concurrent task.

## 2026-07-17 - Swift Allocation-Free Hand Evaluation
**Learning:** Standard high-level collections like Arrays, Sets, and Dictionary groupings inside core evaluation loops incur massive heap allocation and reference-counting overheads. Bypassing them completely via inline register sorting networks (such as 5-item sorting networks) and direct, zero-allocation comparisons yields a ~5.5x speedup in release builds.
**Action:** Always replace map, Set, and Dictionary grouping in high-frequency evaluation functions with fixed-size inline variables and optimized sorting/conditional logic.
