#!/usr/bin/env bash
# validate.sh — validate Kubernetes manifests. Uses kubeconform and/or
# `kubectl --dry-run=client` when available, and always runs built-in
# best-practice heuristics so it works with no cluster/tools.
# Usage: scripts/validate.sh FILE_OR_DIR ...   (default: .)
set -uo pipefail
targets=("$@"); [[ ${#targets[@]} -eq 0 ]] && targets=(".")
files=()
for t in "${targets[@]}"; do
  if [[ -d "$t" ]]; then while IFS= read -r f; do files+=("$f"); done < <(find "$t" -type f \( -name '*.yaml' -o -name '*.yml' \)); else files+=("$t"); fi
done
[[ ${#files[@]} -eq 0 ]] && { echo "no manifests found"; exit 2; }
issues=0; flag(){ printf '  \033[33m! %s\033[0m\n' "$1"; issues=$((issues+1)); }

if command -v kubeconform >/dev/null 2>&1; then
  echo "-- kubeconform (schema) --"; kubeconform -summary "${files[@]}" || issues=$((issues+1))
elif command -v kubectl >/dev/null 2>&1; then
  echo "-- kubectl --dry-run=client --"
  for f in "${files[@]}"; do
    err="$(kubectl apply --dry-run=client -f "$f" 2>&1 >/dev/null)" || true
    # ignore no-cluster/connection noise (offline openapi download failures)
    if printf '%s' "$err" | grep -Eqi 'failed to download openapi|connection|wsarecv|Get "http|refused|no such host'; then
      continue
    fi
    # only a real schema/validation error counts
    if printf '%s' "$err" | grep -Eqi 'unknown field|must be|invalid value|missing required|error validating data'; then
      flag "kubectl: $f — $(printf '%s' "$err" | head -1)"
    fi
  done
else
  echo "(no kubeconform/kubectl — running built-in heuristics; install kubeconform for schema validation)"
fi

echo "-- best-practice heuristics --"
for f in "${files[@]}"; do
  grep -Eq 'kind:\s*(Deployment|StatefulSet|DaemonSet)' "$f" || continue
  grep -Eq 'resources:' "$f"      || flag "$f: no resources requests/limits"
  grep -Eq 'readinessProbe:' "$f" || flag "$f: no readinessProbe (traffic gating)"
  grep -Eq 'livenessProbe:' "$f"  || flag "$f: no livenessProbe"
  grep -Eq 'image:\s*\S+:latest' "$f" && flag "$f: image uses :latest (pin a tag/digest)"
  grep -Eq 'image:\s*\S+(:|@)' "$f"   || flag "$f: image has no tag/digest"
  grep -Eq 'securityContext:' "$f" || flag "$f: no securityContext (consider runAsNonRoot)"
done

echo "== $([[ $issues -eq 0 ]] && echo '✔ no issues' || echo "⚠ $issues finding(s)") =="
exit 0
