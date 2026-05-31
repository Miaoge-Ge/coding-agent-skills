#!/usr/bin/env bash
# scaffold.sh — generate a production-grade Deployment + Service with probes,
# resource requests/limits, and a non-root securityContext.
# Usage: scripts/scaffold.sh NAME IMAGE [PORT] [> out.yaml]
set -uo pipefail
name="${1:-}"; image="${2:-}"; port="${3:-8080}"
[[ -z "$name" || -z "$image" ]] && { echo "usage: scaffold.sh NAME IMAGE [PORT]" >&2; exit 2; }
case "$image" in *:latest) echo "warning: pin a tag/digest, not :latest" >&2;; esac

cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${name}
  labels: { app: ${name} }
spec:
  replicas: 3
  selector:
    matchLabels: { app: ${name} }
  template:
    metadata:
      labels: { app: ${name} }
    spec:
      securityContext:
        runAsNonRoot: true
        seccompProfile: { type: RuntimeDefault }
      containers:
        - name: ${name}
          image: ${image}
          ports:
            - containerPort: ${port}
          resources:
            requests: { cpu: "100m", memory: "128Mi" }
            limits:   { cpu: "500m", memory: "256Mi" }
          readinessProbe:
            httpGet: { path: /health, port: ${port} }
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet: { path: /health, port: ${port} }
            periodSeconds: 10
            failureThreshold: 6
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities: { drop: ["ALL"] }
---
apiVersion: v1
kind: Service
metadata:
  name: ${name}
spec:
  selector: { app: ${name} }
  ports:
    - port: 80
      targetPort: ${port}
EOF
