#!/usr/bin/env bash
# check.sh — Go quality gate: gofmt, go vet, race-enabled tests, and golangci-lint
# (if installed). Run from a module root. Requires the Go toolchain.
# Usage: scripts/check.sh [--fix]   (--fix runs gofmt -w)
set -uo pipefail
fix=0; [[ "${1:-}" == "--fix" ]] && fix=1
command -v go >/dev/null 2>&1 || { echo "go not found — install the Go toolchain"; exit 127; }
status=0
section() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

section "gofmt"
unformatted="$(gofmt -l . 2>/dev/null)"
if [[ -n "$unformatted" ]]; then
  if [[ $fix -eq 1 ]]; then gofmt -w .; echo "formatted: $unformatted";
  else echo "needs gofmt:"; echo "$unformatted"; status=1; fi
else echo "ok"; fi

section "go vet"
go vet ./... || status=1

section "go test -race"
go test -race ./... || status=1

section "golangci-lint"
if command -v golangci-lint >/dev/null 2>&1; then golangci-lint run || status=1
else echo "skip: golangci-lint not installed (https://golangci-lint.run)"; fi

section "result"
[[ $status -eq 0 ]] && echo "✔ fmt/vet/test passed" || echo "✘ issues found"
exit $status
