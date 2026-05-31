#!/usr/bin/env bash
# check.sh — run the standard Python quality gate on a path (default: .).
# Detects and runs ruff (lint+format), mypy (types), and pytest (tests).
# Each tool is optional: missing tools are reported and skipped, not fatal.
# Usage:   scripts/check.sh [PATH] [--fix]
#   --fix  apply ruff autofixes and formatting instead of just checking
set -uo pipefail

target="${1:-.}"
fix=0
for a in "$@"; do [[ "$a" == "--fix" ]] && fix=1; done

have() { command -v "$1" >/dev/null 2>&1; }
# prefer `uv run`/`python -m` so it works inside venvs without global installs
run() { if have "$1"; then "$@"; elif python -c "import $1" >/dev/null 2>&1; then python -m "$@"; else return 127; fi; }

status=0
section() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

section "ruff (lint)"
if have ruff || python -c "import ruff" 2>/dev/null; then
  if [[ $fix -eq 1 ]]; then run ruff check --fix "$target"; run ruff format "$target";
  else run ruff check "$target" || status=1; run ruff format --check "$target" || status=1; fi
else echo "skip: ruff not installed (pip install ruff)"; fi

section "mypy (types)"
if have mypy || python -c "import mypy" 2>/dev/null; then
  run mypy "$target" || status=1
else echo "skip: mypy not installed (pip install mypy)"; fi

section "pytest (tests)"
if have pytest || python -c "import pytest" 2>/dev/null; then
  run pytest -q "$target"; rc=$?
  # exit 5 = "no tests collected" — not a failure for a quality gate
  if [[ $rc -ne 0 && $rc -ne 5 ]]; then status=1; fi
  [[ $rc -eq 5 ]] && echo "(no tests found — ok)"
else echo "skip: pytest not installed (pip install pytest)"; fi

section "result"
[[ $status -eq 0 ]] && echo "✔ all available checks passed" || echo "✘ issues found (see above)"
exit $status
