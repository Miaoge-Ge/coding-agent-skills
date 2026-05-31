---
description: Python coding standards (PEP 8 + modern best practices) — type safety, exception handling, performance, immutability, naming, and structure. Auto-attach for Python source files.
globs: *.py,*.pyi
alwaysApply: false
---

# Python Coding Standards (PEP 8 + Modern Best Practices)

## Key Rules

- **Type safety**: Annotate every function parameter and return value (`typing`); avoid `Any`; run `mypy` in strict mode.
- **Exception handling**: Catch specific exception types; never bare `except:` or broad `except Exception:`; include log context.
- **Performance**: Use generators (`yield`) for large data, comprehensions over trivial loops, and `str.join` for concatenation.
- **Immutability**: Prefer `Final`, frozen dataclasses; never mutate mutable default arguments (use `def foo(x=None)`).
- **Pythonic**: Use context managers (`with`), decorators, and `@property`; don't manage resources (file handles) by hand.
- **Documentation**: Public APIs need a Google- or NumPy-style docstring documenting parameter types and raised exceptions.

## Naming Conventions

- Classes: `PascalCase` (`HttpClient`, `DataProcessor`)
- Functions/variables/attributes: `snake_case` (`fetch_data()`, `user_count`)
- Constants: `UPPER_SNAKE_CASE` (`MAX_RETRIES`, `DEFAULT_TIMEOUT`)
- Private members: single leading underscore (`_internal_cache`); name-mangled with double underscore (`__private`)
- Modules: short `snake_case` (`data_utils.py`); packages use underscores

## Code Structure

- Single responsibility: functions under ~20 lines, at most ~5 public methods per class, modules under ~500 lines.
- Import order: standard library → third-party → local, separated by blank lines; automate with `isort`.
- Avoid circular imports: import under `TYPE_CHECKING` for type-only needs, or restructure modules.

<example>
# Correct: type hints, specific exceptions, context manager, generator
from __future__ import annotations

import logging
from collections.abc import Iterator
from pathlib import Path

logger = logging.getLogger(__name__)


def read_lines(path: Path) -> Iterator[str]:
    """Yield non-empty, stripped lines from a text file.

    Args:
        path: Path to the UTF-8 text file.

    Raises:
        FileNotFoundError: If the file does not exist.
    """
    try:
        with path.open(encoding="utf-8") as f:
            for line in f:
                stripped = line.strip()
                if stripped:
                    yield stripped
    except FileNotFoundError:
        logger.error("File not found: %s", path)
        raise
</example>

<example type="invalid">
# Wrong: no type hints, bare except, manual resource management, mutable default
def read_lines(path, cache=[]):  # mutable default arg
    f = open(path)               # never closed
    try:
        lines = f.readlines()
    except:                      # bare except swallows everything
        return cache
    return lines
</example>
