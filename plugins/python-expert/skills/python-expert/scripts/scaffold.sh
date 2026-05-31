#!/usr/bin/env bash
# scaffold.sh — create a modern src-layout Python project (pyproject + ruff +
# mypy + pytest config). uv-friendly. Never overwrites existing files.
# Usage: scripts/scaffold.sh PACKAGE_NAME [DIR]
set -euo pipefail
pkg="${1:-}"; dir="${2:-.}"
[[ -z "$pkg" ]] && { echo "usage: scaffold.sh PACKAGE_NAME [DIR]" >&2; exit 2; }
[[ "$pkg" =~ ^[a-z][a-z0-9_]*$ ]] || { echo "package name must be lowercase snake_case" >&2; exit 2; }
mkdir -p "$dir/src/$pkg" "$dir/tests"

w(){ [[ -e "$1" ]] && { echo "skip (exists): $1"; return; }; cat > "$1"; echo "wrote $1"; }

w "$dir/pyproject.toml" <<EOF
[project]
name = "${pkg//_/-}"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[project.optional-dependencies]
dev = ["pytest", "pytest-cov", "ruff", "mypy"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM", "RUF"]

[tool.mypy]
strict = true

[tool.pytest.ini_options]
addopts = "-q --cov=$pkg --cov-report=term-missing"
EOF

[[ -e "$dir/src/$pkg/__init__.py" ]] || { printf '__all__ = []\n' > "$dir/src/$pkg/__init__.py"; echo "wrote src/$pkg/__init__.py"; }
w "$dir/src/$pkg/core.py" <<EOF
def greet(name: str) -> str:
    return f"hello, {name}"
EOF
w "$dir/tests/test_core.py" <<EOF
from $pkg.core import greet

def test_greet() -> None:
    assert greet("world") == "hello, world"
EOF
echo "✔ done. Next: uv sync && uv run pytest   (or: pip install -e .[dev])"
