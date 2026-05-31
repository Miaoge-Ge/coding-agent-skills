#!/usr/bin/env bash
# troubleshoot.sh — gather the evidence you need to diagnose a workload:
# pod status, describe (events), logs (+ previous for crashes), and recent
# namespace events. Read events first — they usually name the cause.
# Usage: scripts/troubleshoot.sh [-n NAMESPACE] <pod-or-selector>
#   e.g. scripts/troubleshoot.sh -n prod app=web
set -uo pipefail
command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found on PATH"; exit 127; }
ns="default"
if [[ "${1:-}" == "-n" ]]; then ns="$2"; shift 2; fi
sel="${1:-}"; [[ -z "$sel" ]] && { echo "usage: troubleshoot.sh [-n ns] <pod|selector>"; exit 2; }
KQ=(kubectl -n "$ns")
# resolve to pod names (accept a literal pod name or a label selector)
if [[ "$sel" == *=* ]]; then mapfile -t pods < <("${KQ[@]}" get pods -l "$sel" -o name); else pods=("pod/$sel"); fi
[[ ${#pods[@]} -eq 0 ]] && { echo "no pods match '$sel' in ns/$ns"; exit 1; }

sec(){ printf '\n\033[1m==== %s ====\033[0m\n' "$1"; }
sec "pods (status / restarts)"; "${KQ[@]}" get pods -o wide ${sel:+$([[ $sel == *=* ]] && echo -l "$sel")} 2>/dev/null || "${KQ[@]}" get "${pods[@]}"
for p in "${pods[@]}"; do
  sec "describe $p (read Events at the bottom)"; "${KQ[@]}" describe "$p" | sed -n '/Events:/,$p;/Containers:/,/Conditions:/p' | head -60
  sec "logs $p (current)"; "${KQ[@]}" logs "$p" --tail=50 2>&1 | tail -50
  sec "logs $p (previous, if crashed)"; "${KQ[@]}" logs "$p" --previous --tail=50 2>/dev/null | tail -50 || echo "(no previous container)"
done
sec "recent namespace events"; "${KQ[@]}" get events --sort-by=.lastTimestamp 2>/dev/null | tail -20

cat <<'TIPS'

---- quick diagnosis ----
CrashLoopBackOff  -> read logs/--previous; check liveness probe + command/args
ImagePullBackOff  -> wrong image tag/registry or missing imagePullSecret
Pending           -> insufficient resources / unschedulable (taints/affinity); check events
OOMKilled         -> raise memory limit or fix the leak
TIPS
