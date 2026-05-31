---
name: kubernetes-expert
description: "Expert Kubernetes: workloads, services, config, probes, resources, and troubleshooting. Trigger keywords: Kubernetes, k8s, Deployment, StatefulSet, Service, Pod, ConfigMap, Secret, Ingress, liveness, readiness, probe, requests, limits, HPA, kubectl, Helm, CrashLoopBackOff, ImagePullBackOff, OOMKilled. Use for writing manifests, configuring workloads, or debugging cluster issues."
---

# Kubernetes Expert

> Declarative, resilient, right-sized. Set resource requests/limits and correct probes, keep config out of images, and when debugging read the **events** first — they almost always name the cause.

## When to Use
- Writing/reviewing manifests (Deployments, StatefulSets, Services, Ingress, Config/Secrets).
- Probes, resource requests/limits, autoscaling (HPA), rollouts.
- Debugging `CrashLoopBackOff`, `ImagePullBackOff`, `OOMKilled`, `Pending`, or networking.
- Templating with Helm/Kustomize.

## When NOT to Use
- Building the container image → `docker-expert`.
- App-level bugs inside the container → relevant language skill.
- CI/CD pipeline wiring → `github-master`.

## Core Principles

### 1. Pick the right workload
- **Deployment** for stateless apps, **StatefulSet** for stable identity/storage, **DaemonSet** for per-node, **Job/CronJob** for batch. Don't run databases as a plain Deployment.

### 2. Resources & scheduling
- **Always set requests and limits.** Requests drive scheduling and guarantees; limits cap usage. Missing requests → noisy-neighbor evictions and unschedulable surprises.
- Memory limit too low → `OOMKilled`. CPU limit throttles (doesn't kill). Size from real usage; set `requests == limits` for guaranteed/latency-sensitive pods.

### 3. Health & rollouts
- **Readiness** gates traffic (don't route until ready); **liveness** restarts a hung process; **startup** probe protects slow boots. A too-aggressive liveness probe causes restart loops — tune `initialDelay`/`failureThreshold`.
- `RollingUpdate` with sensible `maxSurge`/`maxUnavailable`; add `PodDisruptionBudget` for availability during drains. Pin image tags/digests, never `:latest`.

### 4. Config, secrets, security
- Config in `ConfigMap`, secrets in `Secret` (+ a real secrets manager / sealed-secrets for prod). Never bake them into images. Roll pods on config change (checksum annotation).
- Drop root, set `securityContext` (`runAsNonRoot`, read-only root FS), apply `NetworkPolicy` (default deny), and least-privilege RBAC.

### 5. Troubleshoot methodically
- `kubectl get pods` → `describe pod` (read **Events**) → `logs` (+ `--previous` for crashed) → `get events --sort-by=.lastTimestamp`. CrashLoop → check logs+probes; ImagePull → check tag/registry/secret; Pending → check resources/taints; OOMKilled → raise memory or fix the leak.

## Common Mistakes
- **No resource requests/limits** → eviction, OOM, throttling, scheduling failures.
- **Liveness probe doing heavy/slow checks** → restart loops; use a cheap readiness check for traffic.
- **`:latest` images** → unpredictable rollouts, no rollback.
- **Secrets in ConfigMaps or images** → exposure.
- **Editing live objects with `kubectl edit`** instead of updating manifests → config drift; stay declarative/GitOps.
- **One giant pod / multiple concerns per container** → scale and fail independently instead.

## Examples

**Deployment with probes, resources, and security context**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata: { name: web }
spec:
  replicas: 3
  selector: { matchLabels: { app: web } }
  template:
    metadata: { labels: { app: web } }
    spec:
      securityContext: { runAsNonRoot: true }
      containers:
        - name: web
          image: registry.example.com/web@sha256:…   # pinned by digest
          ports: [ { containerPort: 3000 } ]
          resources:
            requests: { cpu: "100m", memory: "128Mi" }
            limits:   { cpu: "500m", memory: "256Mi" }
          readinessProbe: { httpGet: { path: /health, port: 3000 }, initialDelaySeconds: 5 }
          livenessProbe:  { httpGet: { path: /health, port: 3000 }, periodSeconds: 10, failureThreshold: 6 }
          securityContext: { allowPrivilegeEscalation: false, readOnlyRootFilesystem: true }
```

## Bundled Resources
- **`reference.md`** — workload/probe/resource guidance, security baseline, rollout, Helm/Kustomize, and a troubleshooting playbook.
- **`scripts/validate.sh`** — kubeconform/kubectl + best-practice heuristics (probes, resources, :latest, securityContext).
- **`scripts/scaffold.sh`** — Deployment+Service with probes, resources, non-root securityContext.
- **`scripts/troubleshoot.sh`** — gather pod status/describe/logs/events + quick-diagnosis cheatsheet.

## See Also
- `docker-expert` — the images these workloads run.
- `security-expert` — RBAC, NetworkPolicy, and secret handling.
- `performance-expert` — right-sizing resources and HPA tuning.
- `github-master` — CD pipelines that apply manifests.
