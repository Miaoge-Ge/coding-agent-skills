#!/usr/bin/env bash
# harden.sh — heuristic review of a shell script for the most common, dangerous
# mistakes. Complements shellcheck (and works without it). Reports line numbers.
# Usage: scripts/harden.sh FILE.sh
set -uo pipefail
f="${1:-}"; [[ -f "$f" ]] || { echo "usage: harden.sh FILE.sh"; exit 2; }
n=0; hit(){ printf '  \033[33mL%-4s %s\033[0m\n' "$1" "$2"; n=$((n+1)); }
# `while ... done < <(...)` (process substitution) keeps $n in this shell;
# a `grep | while` pipe would run the loop in a subshell and lose the count.

echo "== hardening review: $f =="

head -5 "$f" | grep -Eq 'set -euo pipefail|set -e.*-u' || hit 1 "missing 'set -euo pipefail' near the top"

while IFS=: read -r ln _; do hit "$ln" "possible unquoted \$var (quote it: \"\$var\")"; done < <(
  grep -nE '\b(rm|cp|mv|cd|cat|test|\[)\s+[^"|]*\$[A-Za-z_][A-Za-z0-9_]*([^"A-Za-z0-9_]|$)' "$f" | grep -vE '"\$' | head -10)

while IFS=: read -r ln _; do hit "$ln" "backticks — use \$(...)"; done < <(grep -nE '`[^`]+`' "$f" | head -5)
while IFS=: read -r ln _; do hit "$ln" "single [ test — prefer [[ ... ]]"; done < <(grep -nE '(^|[^[])\[ [^]]*\] ' "$f" | head -5)
while IFS=: read -r ln _; do hit "$ln" "parsing ls — use a glob or find -print0"; done < <(grep -nE '\bfor\s+\w+\s+in\s+\$\(ls' "$f")
while IFS=: read -r ln _; do hit "$ln" "echo -e is non-portable — use printf"; done < <(grep -nE '\becho\s+-e' "$f")
while IFS=: read -r ln _; do hit "$ln" "cd without '|| exit' guard"; done < <(grep -nE '\bcd\s+[^&|]*$' "$f" | grep -vE 'exit' | head -5)
grep -qE 'mktemp' "$f" && ! grep -qE "trap .* EXIT" "$f" && hit 0 "uses mktemp but no 'trap ... EXIT' cleanup"

echo "== $([[ $n -eq 0 ]] && echo '✔ no obvious issues' || echo "⚠ $n finding(s); also run shellcheck") =="
exit 0
