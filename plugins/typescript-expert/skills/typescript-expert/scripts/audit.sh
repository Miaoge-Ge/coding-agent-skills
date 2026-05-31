#!/usr/bin/env bash
# audit.sh — dependency health for a JS/TS project: known vulnerabilities,
# outdated packages, and (if depcheck is available) unused dependencies.
# Usage: scripts/audit.sh [DIR]
set -uo pipefail
dir="${1:-.}"; cd "$dir" || { echo "no such dir: $dir"; exit 2; }
[[ -f package.json ]] || { echo "no package.json in $dir"; exit 2; }
pm="npm"; [[ -f pnpm-lock.yaml ]] && pm="pnpm"; [[ -f yarn.lock ]] && pm="yarn"
sec(){ printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
status=0

sec "vulnerabilities ($pm audit)"
case "$pm" in
  npm)  npm audit --omit=dev || status=1;;
  pnpm) pnpm audit --prod || status=1;;
  yarn) yarn npm audit || yarn audit || status=1;;
esac

sec "outdated packages"
$pm outdated || true   # outdated exits non-zero when anything is outdated; informational

sec "unused dependencies (depcheck)"
if command -v depcheck >/dev/null 2>&1; then depcheck || true
else echo "skip: depcheck not installed (npx depcheck)"; fi

sec "result"; [[ $status -eq 0 ]] && echo "✔ no known vulnerabilities" || echo "✘ vulnerabilities found — update affected packages"
exit $status
