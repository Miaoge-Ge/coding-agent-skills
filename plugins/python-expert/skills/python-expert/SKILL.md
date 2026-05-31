---
name: python-expert
description: "Expert Python: Pythonic code, typing, async, the standard library, and performance. Trigger keywords: Python, PEP 8, type hints, mypy, asyncio, generator, decorator, context manager, dataclass, pytest, pandas, numpy, packaging, uv, GIL, profiling. Use for writing/refactoring Python, fixing bugs, performance, or library/tooling guidance."
---

# Python Expert

> Write code that reads like the problem. Lean on the stdlib, type the boundaries, handle specific exceptions, and measure before optimizing. There's usually one obvious, Pythonic way — find it.

## When to Use
- Writing, refactoring, or reviewing Python.
- Best practices: PEP 8, typing, packaging, project layout.
- Debugging exceptions/tracebacks or unexpected behavior.
- Performance/profiling, async, or data-stack (numpy/pandas) work.

## When NOT to Use
- Another language → relevant language skill.
- Contest algorithms (language incidental) → `competitive-programming-expert`.
- System/architecture design → `software-architect`.
- DL modeling/training → `deep-learning-expert`.

## Core Principles

### 1. Pythonic & typed
- PEP 8 via autoformatter (`ruff format`/`black`) + linter (`ruff`). Comprehensions, generators, `enumerate`/`zip`, `pathlib`, f-strings.
- Type public functions; run `mypy`/`pyright` strict for libraries. Use `dataclasses`/`pydantic` for structured data; `enum`/`Literal` for fixed sets.

### 2. Correct & robust
- Catch **specific** exceptions; never bare `except:`. Re-raise with context (`raise X from e`). EAFP (try/except) over LBYL where it reads cleaner.
- Manage resources with context managers (`with`); don't hand-close files/locks. Prefer pure functions and immutability where practical.

### 3. Use the stdlib first
- `collections` (`Counter`, `defaultdict`, `deque`), `itertools`, `functools` (`lru_cache`, `cached_property`), `contextlib`, `pathlib`, `datetime`/`zoneinfo`. Reach for a dependency only when the stdlib falls short.
- Tooling: `uv` (or Poetry) for envs/deps, `pytest` for tests, `ruff` for lint/format.

### 4. Concurrency & performance
- Measure first (`timeit`, `cProfile`, `py-spy`). Use `set`/`dict` for O(1) membership; pick the right container.
- Concurrency model matters because of the GIL: **`asyncio`** for high-concurrency I/O, **threads** for blocking I/O calls, **`multiprocessing`** (or vectorized numpy) for CPU-bound work. (Free-threaded 3.13+ is changing this — know your runtime.)

## Common Mistakes
- **Mutable default arguments** (`def f(x=[])`) → shared across calls; use `None` + assign inside.
- **Bare `except:`** → swallows `KeyboardInterrupt`/bugs; catch specific types.
- **`==` vs `is`** → `is` only for `None`/singletons, not value equality.
- **Late-binding closures in loops** → capture with a default arg or `functools.partial`.
- **String-concatenating in a loop** / building lists you immediately sum → use `join`/generators.
- **`from module import *`** and deep relative imports → explicit imports.
- **Threads for CPU-bound work** → GIL-bound; use processes or numpy.

## Examples

**Idiomatic, typed, safe**
```python
from __future__ import annotations
from collections import Counter
from collections.abc import Iterable

def top_words(words: Iterable[str], n: int = 3) -> list[tuple[str, int]]:
    """Return the n most common non-empty words, case-insensitively."""
    return Counter(w.casefold() for w in words if w).most_common(n)
```

**Async I/O with bounded concurrency**
```python
import asyncio, httpx

async def fetch_all(urls: list[str], limit: int = 10) -> list[str]:
    sem = asyncio.Semaphore(limit)
    async with httpx.AsyncClient(timeout=10) as client:
        async def one(u: str) -> str:
            async with sem:
                r = await client.get(u); r.raise_for_status()
                return r.text
        return await asyncio.gather(*(one(u) for u in urls))
```

## Bundled Resources
- **`reference.md`** — deep engineering reference: `pyproject.toml`/uv setup, src layout, typing patterns (Protocols/TypedDict/generics), concurrency decision table, performance recipes, testing, pitfalls. Read it for any non-trivial task.
- **`scripts/check.sh`** — quality gate: ruff (lint+format), mypy (strict types), pytest. Run `bash scripts/check.sh [path] [--fix]`; wire the same into CI.

## See Also
- `competitive-programming-expert` — algorithmic Python + fast I/O.
- `deep-learning-expert` — PyTorch/NumPy on Python fundamentals.
- `testing-expert` — `pytest`, fixtures, fakes. `performance-expert` — profiling.
- `rules/python-style-guide.md` — enforceable style rules.
