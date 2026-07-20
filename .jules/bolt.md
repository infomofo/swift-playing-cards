## 2026-07-17 - Swift Inner Loop Heap Allocations
**Learning:** In Swift, allocating arrays of even small fixed sizes (like 13-element arrays for rank frequencies) or dynamic arrays for combinations in tight, multi-million iteration loops incurs substantial heap allocation and reference counting overhead. Unrolling loops for specific draw sizes (0 to 5) and using inline insertion sort on local stack variables completely bypasses allocations, resulting in a ~7.7x speedup in release builds (10.53s to 1.36s).
**Action:** Always prefer unrolled loops, stack variables, and flat, zero-allocation switch statements when dealing with heavy combination evaluation and game theory trees.

## 2026-07-17 - Swift Task Groups vs Sequential Iteration in Combination Engines
**Learning:** For large-scale state space searches (such as the 32-mask combinations search which evaluates over 2.5 million inner-loop hands), utilizing Swift's structured concurrency (`withTaskGroup`) scales extremely well and provides a ~1.6x speedup (0.037s vs 0.059s in release build) over a pure sequential loop. The workload is heavy enough to overcome task creation/context-switching overhead on multi-core systems.
**Action:** Keep structured concurrency with Task Groups for heavy combination search tasks (> 1 million iterations), but continue avoiding allocations inside each concurrent task.

## 2026-07-17 - Swift Allocation-Free Hand Evaluation
**Learning:** Standard high-level collections like Arrays, Sets, and Dictionary groupings inside core evaluation loops incur massive heap allocation and reference-counting overheads. Bypassing them completely via inline register sorting networks (such as 5-item sorting networks) and direct, zero-allocation comparisons yields a ~5.5x speedup in release builds.
**Action:** Always replace map, Set, and Dictionary grouping in high-frequency evaluation functions with fixed-size inline variables and optimized sorting/conditional logic.

## 2026-07-18 - Safe O(1) Deck Dealing and Dynamic Loop Bounds
**Learning:** When optimizing card deck dealing, modifying array size or dealing from the end of the array (reversing the order) can cause functional regressions if down-stream tests expect specific cards in sequential order. Utilizing an index pointer tracks the deal state in O(1) time while perfectly preserving the original card sequence. Additionally, hardcoding loop boundaries for hand evaluation introduces index out-of-bounds risks; dynamic loop boundaries using `cards.count` guarantee safety.
**Action:** Prefer tracking state with index pointers over modifying array sizes in performance critical code, and always use dynamic collection counts for safety.

## 2026-07-18 - Swift Zero-Allocation 5-Card Combinations
**Learning:** Recursive generic combination generators allocate nested array structures (`[[T]]`) on the heap, triggering continuous allocation and deallocation operations in hand evaluation loops. Flattening combination checks into five unrolled nested loops and evaluating directly on individual-parameter function signatures completely eliminates allocation, speeding up hand evaluation by ~38x.
**Action:** For hot paths with known subset size targets, replace recursion with flat nested loops and parameter-separated function signatures.

## 2026-07-20 - Swift Direct Memory Access with Unsafe Buffer Pointers
**Learning:** In Swift, standard array subscriptions inside heavy multi-million iteration loops (such as combination evaluations) check bounds on every single iteration, introducing significant CPU overhead. Using `withUnsafeBufferPointer` to obtain direct memory pointers (`rem.baseAddress!`) and subscripting those pointers instead bypasses bounds-checking completely, yielding a measurable speed improvement (~6.1%) on already state-of-the-art hand evaluation logic.
**Action:** Always prefer `withUnsafeBufferPointer` and raw pointer subscripts for collections accessed inside performance-critical, multi-million iteration inner loops.
