#!/usr/bin/env bash
# check.sh — Rust quality gate: format check, clippy (warnings as errors), and tests.
# Run from a Cargo project root. Requires the Rust toolchain (rustup).
# Usage: scripts/check.sh [--fix]   (--fix applies rustfmt + clippy --fix)
set -uo pipefail
fix=0; [[ "${1:-}" == "--fix" ]] && fix=1
command -v cargo >/dev/null 2>&1 || { echo "cargo not found — install rustup"; exit 127; }
status=0
section() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

section "rustfmt"
if [[ $fix -eq 1 ]]; then cargo fmt; else cargo fmt --check || status=1; fi

section "clippy (deny warnings)"
if [[ $fix -eq 1 ]]; then cargo clippy --fix --allow-dirty --allow-staged -- -D warnings || status=1
else cargo clippy --all-targets -- -D warnings || status=1; fi

section "tests"
cargo test --quiet || status=1

section "result"
[[ $status -eq 0 ]] && echo "✔ fmt/clippy/test passed" || echo "✘ issues found"
exit $status
