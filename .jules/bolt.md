## 2026-07-21 - Optimal Branchless Sorting Networks
**Learning:** Deeply nested insertion sorting in critical inner loops (such as rank sorting in 5-card poker hand evaluation) introduces highly unpredictable branches that degrade hardware pipeline efficiency. Utilizing a flat, branchless-friendly 5-element sorting network (Bose-Nelson algorithm) with exactly 9 compare-and-swap operations optimizes instruction scheduling, reduces CPI, and eliminates misprediction penalties.
**Action:** Replace nested conditional sorting logic in hot execution paths with flat, mathematically optimal sorting networks.

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

## 2026-07-22 - Swift Zero-Allocation Combinatorial Index Generation
**Learning:** Constructing intermediate arrays (`[Int]`) and subsets inside highly iterative loops (such as the 2,598,960-hand enumeration in `HandOutcomeArrays.swift`) triggers heavy heap allocation and reference-counting operations. Factoring out card slice manipulation and pre-calculating choose combinations at intermediate outer-loop levels allows combinatorial indices to be calculated entirely inline on the stack with zero allocations, yielding a massive (~1.6x) speedup for the entire RTP test suite.
**Action:** Avoid allocating any arrays or arrays of arrays inside deeply nested hot loops; compute indices directly on the stack using hoisted intermediate values and unrolled flat lookups.

## 2026-07-23 - Swift Flat Contiguous Arrays vs 2D Lookup Tables
**Learning:** Reading from nested arrays (e.g. `[[Int]]`) requires double dereferencing and separate bounds checks in Swift. Flattening to a contiguous 1D array (`[Int]`) indexed by a stride calculation (e.g. `n * stride + k`) eliminates this nesting overhead and achieves much higher execution speed in hot path lookups.
**Action:** Always flatten small multi-dimensional lookup tables to contiguous 1D arrays on performance-critical evaluation paths.

## 2026-07-23 - Closure Overhead of withUnsafeBufferPointer in Hot Paths
**Learning:** Wrapping collections in `withUnsafeBufferPointer` inside extremely frequent loops (e.g. millions of calls) can introduce closure setup and teardown overhead that outweighs the benefits of bypassing standard array bounds checks.
**Action:** Extract unsafe buffer pointers at higher loop levels and pass down raw pointers to innermost operations, rather than calling buffer-wrapping methods repeatedly.

## 2026-07-26 - Swift Lifetime-Bounded Pointer Passing
**Learning:** Escaping raw pointers from `withUnsafeBufferPointer` closures to static or global properties violates memory safety. It causes undefined behavior because Swift does not guarantee the pointer remains valid after the closure ends. Wrapping the entire hot loop in a lifetime-bounded monadic closure (like `withChooseTablePointer`) and passing the pointer down the call stack is 100% memory safe.
**Action:** Always bind the lifetime of unsafe pointers to the outer-most loop and pass them down as function parameters, rather than storing them in variables.

## 2026-07-28 - Fast Reciprocal Multiplication in High-Frequency Loops
**Learning:** Performing floating-point divisions inside highly frequent evaluation loops (e.g. 83 million times in the RTP pay table analyzer) incurs massive execution latency on modern CPUs. Precomputing the reciprocals of division denominators as a static array, extracting its raw pointer using `withUnsafeBufferPointer` at the highest outer level, and multiplying by the pointer offsets instead of dividing completely avoids both division overhead and array bounds-checking, speeding up execution.
**Action:** Replace floating-point division in ultra-frequent loops with multiplication by precomputed reciprocals passed down as raw unsafe pointers.
