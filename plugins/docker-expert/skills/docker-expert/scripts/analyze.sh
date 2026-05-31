#!/usr/bin/env bash
# analyze.sh — review a Dockerfile for common problems. Runs hadolint if
# installed; always runs built-in heuristic checks so it works with no deps.
# Usage: scripts/analyze.sh [Dockerfile]   (default: ./Dockerfile)
set -uo pipefail
f="${1:-Dockerfile}"
[[ -f "$f" ]] || { echo "no such file: $f"; exit 2; }
issues=0
flag() { printf '  \033[33m! %s\033[0m\n' "$1"; issues=$((issues+1)); }

echo "== analyzing $f =="

# hadolint if available (authoritative)
if command -v hadolint >/dev/null 2>&1; then
  echo "-- hadolint --"; hadolint "$f" || issues=$((issues+1))
else
  echo "(hadolint not installed — running built-in checks; install for full linting)"
fi

echo "-- heuristics --"
grep -Eq '^\s*FROM\s+\S+:\S+|@sha256:' "$f" || flag "FROM is unpinned (no tag/digest) — avoid implicit :latest"
grep -Eq '^\s*FROM\s+\S+:latest' "$f"        && flag "FROM uses :latest — pin a version for reproducibility"
grep -Eq '^\s*USER\s+' "$f"                  || flag "no USER — container runs as root; add a non-root USER"
grep -Eqi 'apt-get\s+install' "$f" && ! grep -Eq 'rm -rf /var/lib/apt/lists' "$f" \
                                             && flag "apt-get install without cleaning lists in the same layer"
grep -Eqi '(ADD)\s+https?://' "$f"           && flag "ADD with URL — prefer curl/wget in a RUN, or COPY"
grep -Eq '^\s*(CMD|ENTRYPOINT)\s+\[' "$f"    || flag "CMD/ENTRYPOINT not in exec form [\"a\",\"b\"] — signals won't propagate"
grep -Eqi '(ARG|ENV).*(SECRET|TOKEN|PASSWORD|KEY)=' "$f" && flag "possible secret in ARG/ENV — use build secrets / runtime env"
[[ -f "$(dirname "$f")/.dockerignore" ]]     || flag "no .dockerignore next to the Dockerfile — build context may be bloated"
grep -Eqi 'COPY\s+\.\s' "$f" && grep -Eqn 'COPY\s+\.\s' "$f" | head -1 | grep -q . && \
  awk '/COPY[[:space:]]+\.[[:space:]]/{c=NR} /RUN.*(npm (ci|install)|pip install|go mod|cargo build)/{r=NR} END{if(c&&r&&c<r) exit 1}' "$f" \
  || flag "COPY . appears before dependency install — busts layer cache on every code change"
grep -Eqi 'multi-stage|AS\s+\w' "$f" || flag "single-stage build — consider multi-stage to drop build deps from the runtime image"

echo "== $([[ $issues -eq 0 ]] && echo '✔ no obvious issues' || echo "⚠ $issues finding(s) above") =="
exit 0
