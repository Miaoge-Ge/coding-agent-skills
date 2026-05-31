---
name: performance-expert
description: "Expert performance optimization across CPU, memory, I/O, and rendering. Trigger keywords: performance, slow, profiling, profiler, optimize, latency, throughput, p99, memory leak, allocation, bottleneck, benchmark, flamegraph, N+1, cache. Use to diagnose and fix performance problems with a measure-first methodology."
---

# Performance Optimization Expert

> Measure, don't guess. Profile to find the real bottleneck, fix the biggest one, re-measure, repeat — and stop at the target. Algorithmic and I/O wins dwarf micro-optimizations.

## When to Use
- Something is slow, memory-hungry, or doesn't scale.
- Profiling guidance for CPU, memory, I/O, or rendering.
- Setting/validating latency or throughput targets; benchmarking.
- Hunting a memory leak or GC pressure.

## When NOT to Use
- Wrong output, not slow → `debugging-expert`.
- Behavior-preserving cleanup with no perf goal → `refactoring-expert`.
- DB query plans/indexing specifically → `sql-expert`.

## Core Principles

### 1. Measure first, always
- Profile before changing anything. Intuition about hotspots is usually wrong. Optimize the **top** item the profiler shows, not what you assume.
- Define the metric and target up front (p99 latency, throughput, peak memory, frame time) and a **representative workload** to measure against. Optimizing the wrong workload wastes effort.
- Beware micro-benchmarks that don't reflect production (warmup, caching, JIT, data size).

### 2. Biggest levers first
- **Algorithmic complexity**: O(n²)→O(n log n), removing redundant passes, and killing **N+1** calls beat constant-factor tuning by orders of magnitude.
- **Eliminate repeated work**: cache/memoize pure results, precompute, hoist invariants out of loops, batch requests.
- Apply **Amdahl's law**: speeding up code that's 5% of runtime caps your win at 5%.

### 3. Levers by axis
- **I/O-bound**: batch + parallelize requests, add caching, cut round trips, stream instead of buffering, connection pooling.
- **CPU-bound**: better algorithm/data structures, reduce allocations in hot loops, vectorize/parallelize, avoid needless serialization.
- **Memory**: stream large data, fix leaks (lingering refs, unbounded caches, dangling listeners), right-size buffers, reduce per-object overhead.
- **Frontend**: shrink/split bundles, lazy-load, virtualize long lists, avoid layout thrash and unnecessary re-renders, debounce, use the browser cache/CDN.

### 4. Verify and guard
- Re-measure after each change to confirm a **real** win and watch for regressions elsewhere. Stop when you hit the target — over-optimizing adds complexity for no user benefit. Add a benchmark/regression check to prevent backsliding.

## Tools
| Domain | Tools |
|--------|-------|
| Python | `cProfile`, `py-spy`, `memray`, `scalene` |
| Node/Web | Chrome DevTools, `--prof`, `clinic`, Lighthouse, React Profiler |
| Go | `pprof`, `go test -bench`, `-benchmem` |
| Rust/native | `perf`, flamegraphs, `cargo bench`, valgrind/heaptrack |
| DB | `EXPLAIN ANALYZE` (→ `sql-expert`) |

## Common Mistakes
- **Optimizing without profiling** → effort on cold code; ignore the real hotspot.
- **Micro-optimizing** (loop unrolling) while an N+1 or O(n²) dominates.
- **No baseline/target** → can't tell if a change helped or when to stop.
- **Premature optimization** that obscures code before there's a measured problem.
- **Caching without invalidation** → correctness bugs; cache deliberately.
- **Benchmarking unrealistic data** → wins that vanish in production.
- **Fixing a symptom in one layer** while the cost is elsewhere (e.g., app loop vs DB).

## Examples

**Profile, then fix the top frame**
```bash
python -m cProfile -s tottime app.py | head -20   # find the real hotspot
py-spy top --pid <PID>                            # sample a running process
```

**Kill an N+1 with batching**
```python
# ❌ one query per id
users = [db.get_user(i) for i in ids]
# ✅ one query
users = db.get_users_in(ids)        # WHERE id IN (...)
```

## See Also
- `debugging-expert` — same evidence-driven mindset, for correctness.
- `sql-expert` — query plans and indexing (often the real bottleneck).
- `rust-expert` / `go-expert` — low-level profiling and allocation control.
- `react-expert` — render performance and memoization.
