# Kubernetes Engineering Reference

Load for manifest templates, probe/resource tuning, and a troubleshooting playbook.

## Workload templates
`scripts/scaffold.sh NAME IMAGE PORT` emits a Deployment+Service with probes,
resources, and a non-root securityContext. Pick the workload:
| Need | Kind |
|------|------|
| Stateless app | Deployment |
| Stable identity/storage | StatefulSet |
| One pod per node | DaemonSet |
| Batch / scheduled | Job / CronJob |

## Probes (get these right — most outages are misconfigured probes)
- **readiness**: gate traffic; fail → removed from Service endpoints (no restart). Use for "can I serve now?".
- **liveness**: restart a hung process. Keep it cheap; too aggressive → restart loops. Higher `failureThreshold`/`periodSeconds` than readiness.
- **startup**: protect slow boots; disables the other probes until it passes.

## Resources
- `requests` = scheduling guarantee + QoS; `limits` = hard cap. Memory over-limit → **OOMKilled**; CPU over-limit → throttled (not killed).
- Set `requests == limits` for latency-sensitive/Guaranteed QoS. Right-size from real usage (`kubectl top`, VPA recommendations).

## Config, secrets, security
- Config → `ConfigMap`; secrets → `Secret` (+ external manager / sealed-secrets / external-secrets for prod). Roll pods on change via a checksum annotation.
- Security baseline: `runAsNonRoot`, `readOnlyRootFilesystem`, drop ALL capabilities, `seccompProfile: RuntimeDefault`. Default-deny `NetworkPolicy`. Least-privilege RBAC. `PodDisruptionBudget` for availability during drains.

## Rollouts
- `RollingUpdate` with `maxSurge`/`maxUnavailable`. Pin images by tag or digest (never `:latest` — breaks rollback). `kubectl rollout status` / `undo`.
- HPA scales on metrics (CPU/memory/custom); needs metrics-server and sane `requests`.

## Troubleshooting playbook
`scripts/troubleshoot.sh [-n ns] <pod|selector>` gathers status, describe(events), logs(+previous), and recent events.
| Symptom | First checks |
|---------|-------------|
| CrashLoopBackOff | `logs --previous`; command/args; liveness probe too strict |
| ImagePullBackOff | image tag/registry; `imagePullSecret`; private-registry auth |
| Pending | `describe` events: insufficient cpu/mem, taints/affinity, no PV |
| OOMKilled | raise memory limit or fix leak (`kubectl top pod`) |
| Service has no endpoints | selector/labels mismatch; readiness failing |
| 5xx through Ingress | readiness, Service targetPort, Ingress path/backend |

## Helm/Kustomize
- Kustomize for env overlays (base + patches); Helm for packaged, parameterized releases. Keep manifests declarative and in git (GitOps: Argo CD/Flux) — avoid `kubectl edit` drift.

## Scripts
- `scripts/validate.sh FILE|DIR` — kubeconform/kubectl + best-practice heuristics (probes, resources, :latest, securityContext).
- `scripts/scaffold.sh NAME IMAGE [PORT]` — Deployment+Service with probes/resources/securityContext.
- `scripts/troubleshoot.sh [-n ns] <pod|selector>` — evidence-gathering + quick-diagnosis cheatsheet.
