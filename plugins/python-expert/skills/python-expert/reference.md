# Python Engineering Reference

Deep reference for production Python. Load this when the task needs concrete setup, config, or patterns beyond the SKILL overview.

## Project layout (src layout — recommended)
```
myproject/
├── pyproject.toml          # single source of truth (PEP 621)
├── src/mypkg/__init__.py   # src layout prevents accidental local imports
├── tests/
└── README.md
```
`src/` layout forces you to test the *installed* package, catching packaging bugs early.

## pyproject.toml (uv / PEP 621)
```toml
[project]
name = "mypkg"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["httpx>=0.27"]

[project.optional-dependencies]
dev = ["pytest", "pytest-cov", "ruff", "mypy"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.ruff]
line-length = 100
[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM", "RUF"]  # pycodestyle, pyflakes, isort, pyupgrade, bugbear, simplify

[tool.mypy]
strict = true
warn_unreachable = true

[tool.pytest.ini_options]
addopts = "-q --cov=mypkg --cov-report=term-missing"
```
Workflow with **uv**: `uv sync` (install), `uv run pytest`, `uv add <pkg>`, `uv run scripts/check.sh`.

## Typing patterns
- **Protocols** (structural typing) decouple from concrete classes:
  ```python
  from typing import Protocol
  class Reader(Protocol):
      def read(self, n: int = -1) -> bytes: ...
  def consume(r: Reader) -> bytes: return r.read()
  ```
- `TypedDict` for JSON-ish dicts; `dataclass(slots=True, frozen=True)` for value objects; `Literal`/`Enum` for fixed sets; `TypeVar`/`Generic` (or 3.12 `def f[T]()`) for generics; `assert_never(x)` for exhaustiveness.
- Validate untrusted input at the edge with `pydantic` (v2) — it converts + validates and gives typed objects.

## Concurrency decision table
| Workload | Use | Notes |
|----------|-----|-------|
| Many network calls | `asyncio` + `httpx`/`aiohttp` | bound with `Semaphore`; `asyncio.gather`/`TaskGroup` (3.11+) |
| Blocking library, I/O-bound | `ThreadPoolExecutor` | GIL released during I/O |
| CPU-bound | `ProcessPoolExecutor` / numpy | sidestep the GIL |
| Mixed in async code | `asyncio.to_thread(fn, ...)` | offload blocking calls |

`asyncio.TaskGroup` (3.11+) for structured concurrency with proper cancellation:
```python
async with asyncio.TaskGroup() as tg:
    for u in urls: tg.create_task(fetch(u))   # all awaited; first error cancels siblings
```

## Performance recipes
- Profile: `python -m cProfile -s tottime app.py`; line-level: `py-spy top --pid <PID>`; memory: `memray`.
- Hot loops: hoist attribute/global lookups to locals; prefer comprehensions/`map`; use `__slots__` on hot classes; `functools.lru_cache` for pure repeats.
- Bulk numeric → numpy vectorization; bulk data → generators to stream, `itertools` to avoid materializing.
- `bisect` for sorted lookups; `array`/`bytes` for compact numeric buffers; `collections.deque` for queues.

## Errors & logging
- `raise SpecificError("context") from err` to preserve the cause. Define a small exception hierarchy per package.
- Use the stdlib `logging` (not `print`) with structured extras; configure once at the entrypoint. Never log secrets/PII.
- `contextlib.contextmanager` / `ExitStack` for ad-hoc resource scoping; `try/finally` only when no CM exists.

## Testing (pytest)
- Fixtures for setup; `tmp_path`/`monkeypatch`/`caplog` built-ins; `pytest.mark.parametrize` for table tests.
- Fake the clock/network/randomness via injection or `monkeypatch`; use `respx`/`responses` for HTTP. Aim coverage at branches, not a number.

## Pitfalls → fixes
| Pitfall | Fix |
|---------|-----|
| Mutable default arg `def f(x=[])` | `x=None`; assign inside |
| `except:` / `except Exception` broad | catch specific types; re-raise with context |
| Late-binding loop closures | default-arg capture / `functools.partial` |
| Threads for CPU work | processes or numpy |
| `requirements.txt` drift | `pyproject.toml` + lockfile (`uv.lock`) |
| Circular imports | move shared types to a leaf module / `TYPE_CHECKING` |
| `datetime.now()` naive | `datetime.now(tz=...)` / `zoneinfo` |

## Quality gate
Run `scripts/check.sh [path] [--fix]` — ruff (lint+format), mypy (strict types), pytest. Wire the same into CI.
