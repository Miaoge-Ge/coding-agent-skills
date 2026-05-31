#!/usr/bin/env bash
# bench.sh — run Go benchmarks with allocation stats, optionally capturing a CPU
# profile for pprof. Use to find hot paths and allocation pressure.
# Usage: scripts/bench.sh [PKG] [BENCH_REGEX]
#   env: COUNT (default 1), CPUPROFILE=1 to capture cpu.prof
set -uo pipefail
command -v go >/dev/null 2>&1 || { echo "go not found"; exit 127; }
pkg="${1:-./...}"; re="${2:-.}"; count="${COUNT:-1}"
args=(test -run '^$' -bench "$re" -benchmem -count "$count" "$pkg")
if [[ "${CPUPROFILE:-0}" == "1" ]]; then
  args+=(-cpuprofile cpu.prof)
  echo "== benchmarking (CPU profile -> cpu.prof) =="
else
  echo "== benchmarking $pkg (regex /$re/, benchmem) =="
fi
go "${args[@]}"
rc=$?
if [[ "${CPUPROFILE:-0}" == "1" && -f cpu.prof ]]; then
  echo "analyze: go tool pprof -top cpu.prof   (or -http=:8080 cpu.prof for a flamegraph)"
fi
exit $rc
