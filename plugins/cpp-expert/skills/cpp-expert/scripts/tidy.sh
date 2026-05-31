#!/usr/bin/env bash
# tidy.sh — static analysis for C++ via clang-tidy and/or cppcheck. Uses
# compile_commands.json when present (configure with -DCMAKE_EXPORT_COMPILE_COMMANDS=ON).
# Usage: scripts/tidy.sh FILE_OR_DIR ...   (default: src)
set -uo pipefail
targets=("$@"); [[ ${#targets[@]} -eq 0 ]] && targets=("src")
files=()
for t in "${targets[@]}"; do
  if [[ -d "$t" ]]; then while IFS= read -r f; do files+=("$f"); done < <(find "$t" -type f \( -name '*.cpp' -o -name '*.cc' -o -name '*.cxx' \)); else files+=("$t"); fi
done
[[ ${#files[@]} -eq 0 ]] && { echo "no C++ source files found"; exit 2; }
status=0; sec(){ printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
cc=""; for d in . build; do [[ -f "$d/compile_commands.json" ]] && cc="$d"; done

sec "clang-tidy"
if command -v clang-tidy >/dev/null 2>&1; then
  for f in "${files[@]}"; do clang-tidy ${cc:+-p "$cc"} "$f" || status=1; done
else echo "skip: clang-tidy not installed (LLVM)"; fi

sec "cppcheck"
if command -v cppcheck >/dev/null 2>&1; then
  cppcheck --enable=warning,performance,portability --inline-suppr --error-exitcode=1 "${files[@]}" || status=1
else echo "skip: cppcheck not installed"; fi

[[ -z "$cc" ]] && echo "(tip: configure CMake with -DCMAKE_EXPORT_COMPILE_COMMANDS=ON for accurate clang-tidy)"
sec "result"; [[ $status -eq 0 ]] && echo "✔ clean (from available tools)" || echo "✘ findings above"
exit $status
