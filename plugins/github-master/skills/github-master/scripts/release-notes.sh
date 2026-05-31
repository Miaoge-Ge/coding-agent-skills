#!/usr/bin/env bash
# release-notes.sh — generate Markdown release notes from Conventional Commits
# since the last tag (or a given ref). Groups by type; lists breaking changes.
# Usage: scripts/release-notes.sh [SINCE_REF]   (default: latest tag)
set -uo pipefail
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repo"; exit 2; }
since="${1:-}"
if [[ -z "$since" ]]; then since="$(git describe --tags --abbrev=0 2>/dev/null || true)"; fi
range="${since:+$since..}HEAD"
echo "# Release notes (${since:-beginning}..HEAD)"; echo

emit() { # $1=regex $2=heading
  local body; body="$(git log "$range" --no-merges --pretty=format:'%s (%h)' \
    | grep -E "^$1" | sed -E "s/^[a-z]+(\([^)]*\))?!?: //" | sed 's/^/- /')"
  [[ -n "$body" ]] && { echo "## $2"; echo "$body"; echo; }
}
emit 'feat(\(.+\))?!?:' "Features"
emit 'fix(\(.+\))?!?:'  "Fixes"
emit 'perf(\(.+\))?!?:' "Performance"
emit '(refactor|build|ci|docs|test|chore)(\(.+\))?!?:' "Other"

breaking="$(git log "$range" --no-merges --pretty=format:'%s%n%b' \
  | grep -E 'BREAKING CHANGE|!:' | sed 's/^/- /')"
[[ -n "$breaking" ]] && { echo "## ⚠ Breaking changes"; echo "$breaking"; echo; }

count="$(git log "$range" --oneline 2>/dev/null | wc -l | tr -d ' ')"
echo "_$count commit(s)._"
