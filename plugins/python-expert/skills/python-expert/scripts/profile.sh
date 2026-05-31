#!/usr/bin/env bash
# profile.sh — profile a Python script with cProfile and print the top functions
# by cumulative + total time. Hints at py-spy (sampling) and memray (memory).
# Usage: scripts/profile.sh script.py [args...]
#   env: TOP (rows, default 20), SORT (tottime|cumtime, default tottime)
set -euo pipefail
[[ $# -ge 1 ]] || { echo "usage: profile.sh script.py [args...]" >&2; exit 2; }
script="$1"; shift
[[ -f "$script" ]] || { echo "no such file: $script" >&2; exit 2; }
py="$(command -v python3 || command -v python)"
TOP="${TOP:-20}"; SORT="${SORT:-tottime}"
stats="$(mktemp --suffix=.pstats)"
trap 'rm -f "$stats"' EXIT

echo "== cProfile $script (sort=$SORT, top=$TOP) =="
"$py" -m cProfile -o "$stats" "$script" "$@" || { echo "✘ script errored under profiler"; exit 1; }
"$py" - "$stats" "$SORT" "$TOP" <<'PY'
import pstats, sys
stats, sort, top = sys.argv[1], sys.argv[2], int(sys.argv[3])
p = pstats.Stats(stats); p.sort_stats(sort); p.print_stats(top)
PY
echo "tip: 'py-spy top -- python $script' (live sampling, no instrumentation); 'memray run $script' (memory)."
