#!/usr/bin/env bash
# check.sh — TypeScript quality gate: type-check (tsc --noEmit), lint (eslint),
# and format-check (prettier). Tools are auto-detected via the local project;
# missing tools are skipped with a hint, not fatal.
# Usage: scripts/check.sh [PATH]   (PATH defaults to the current project)
set -uo pipefail
target="${1:-.}"
status=0
pm() { if [ -f pnpm-lock.yaml ]; then echo pnpm; elif [ -f yarn.lock ]; then echo yarn; else echo npx; fi; }
X="$(pm)"
section() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

section "tsc --noEmit (types)"
if [ -f tsconfig.json ]; then
  $X tsc --noEmit -p tsconfig.json || status=1
else echo "skip: no tsconfig.json found"; fi

section "eslint"
if ls .eslintrc* eslint.config.* >/dev/null 2>&1; then
  $X eslint "$target" || status=1
else echo "skip: no eslint config"; fi

section "prettier --check"
if command -v npx >/dev/null 2>&1; then
  $X prettier --check "$target" 2>/dev/null || { echo "(prettier not configured or found differences)"; }
fi

section "result"
[ $status -eq 0 ] && echo "✔ type-check/lint passed" || echo "✘ issues found"
exit $status
