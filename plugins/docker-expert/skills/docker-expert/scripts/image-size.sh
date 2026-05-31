#!/usr/bin/env bash
# image-size.sh — build an image and report its size and per-layer breakdown,
# so you can see what's bloating it. Suggests `dive` for deep inspection.
# Usage: scripts/image-size.sh [TAG] [BUILD_CONTEXT]   (default: skill-tmp .)
set -uo pipefail
tag="${1:-skill-img-tmp:latest}"
ctx="${2:-.}"
command -v docker >/dev/null 2>&1 || { echo "docker not found on PATH"; exit 127; }

echo "== building $tag from $ctx =="
docker build -t "$tag" "$ctx" || { echo "✘ build failed"; exit 1; }

echo ""; echo "== image size =="
docker image ls "$tag" --format '{{.Repository}}:{{.Tag}}  {{.Size}}'

echo ""; echo "== layer history (largest layers first) =="
docker history "$tag" --no-trunc --format '{{.Size}}\t{{.CreatedBy}}' \
  | sort -h -r | head -15

echo ""
if command -v dive >/dev/null 2>&1; then
  echo "tip: run 'dive $tag' for an interactive layer/efficiency view"
else
  echo "tip: install 'dive' (https://github.com/wagoodman/dive) for layer-efficiency analysis"
fi
echo "(remove the temp image with: docker rmi $tag)"
