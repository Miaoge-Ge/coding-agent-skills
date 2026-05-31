#!/usr/bin/env bash
# build-check.sh — compile a C++ translation unit with strict warnings and
# the Address+UB sanitizers, then run it. Catches UB, leaks, and warning-level
# bugs that a plain build misses. Great for reproducing crashes/UB minimally.
# Usage: scripts/build-check.sh FILE.cpp [-- prog-args...]
#   env: CXX (default g++), STD (default c++20)
set -uo pipefail
[[ $# -ge 1 ]] || { echo "usage: build-check.sh FILE.cpp [-- args...]"; exit 2; }
src="$1"; shift
[[ "${1:-}" == "--" ]] && shift
CXX="${CXX:-g++}"; STD="${STD:-c++20}"
command -v "$CXX" >/dev/null 2>&1 || { echo "$CXX not found (set CXX=clang++?)"; exit 127; }
out="$(mktemp -u)"
warn="-Wall -Wextra -Wpedantic -Wshadow -Wconversion"

# Probe whether this toolchain can actually link the sanitizers (MinGW often can't).
san="-fsanitize=address,undefined -fno-omit-frame-pointer"
probe="$(mktemp -d)/p"; echo 'int main(){}' > "$probe.cpp"
if "$CXX" -std="$STD" $san "$probe.cpp" -o "$probe.out" >/dev/null 2>&1; then
  echo "== compiling $src ($CXX, -std=$STD, strict warnings + ASan/UBSan) =="
else
  san=""; echo "== compiling $src ($CXX, -std=$STD, strict warnings; sanitizers unavailable on this toolchain) =="
fi
rm -f "$probe.cpp" "$probe.out" 2>/dev/null

# shellcheck disable=SC2086
"$CXX" -std="$STD" $warn $san -g -O1 "$src" -o "$out" || { echo "✘ compile failed"; exit 1; }

echo "== running${san:+ (sanitizers active)} =="
ASAN_OPTIONS=detect_leaks=1 UBSAN_OPTIONS=print_stacktrace=1 "$out" "$@"
rc=$?
rm -f "$out"
echo "== exit $rc =="
exit $rc
