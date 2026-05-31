#!/usr/bin/env bash
# scaffold.sh — generate a production-grade multi-stage Dockerfile + .dockerignore
# for a detected/!specified stack. Never overwrites existing files.
# Usage: scripts/scaffold.sh [node|python|go] [outdir]   (auto-detects if omitted)
set -uo pipefail
stack="${1:-}"; out="${2:-.}"
detect() {
  [[ -f "$out/package.json" ]] && { echo node; return; }
  [[ -f "$out/go.mod" ]] && { echo go; return; }
  [[ -f "$out/pyproject.toml" || -f "$out/requirements.txt" ]] && { echo python; return; }
  echo ""
}
[[ -z "$stack" ]] && stack="$(detect)"
[[ -z "$stack" ]] && { echo "could not detect stack; pass one: node|python|go"; exit 2; }
df="$out/Dockerfile"; di="$out/.dockerignore"
[[ -e "$df" ]] && { echo "refusing to overwrite $df"; exit 1; }

case "$stack" in
node)
cat > "$df" <<'EOF'
# syntax=docker/dockerfile:1
FROM node:22-slim AS build
WORKDIR /app
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY . .
RUN npm run build

FROM node:22-slim
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist
USER node
HEALTHCHECK --interval=30s CMD node -e "fetch('http://localhost:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "dist/server.js"]
EOF
;;
python)
cat > "$df" <<'EOF'
# syntax=docker/dockerfile:1
FROM python:3.12-slim AS build
WORKDIR /app
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
COPY pyproject.toml* requirements*.txt ./
RUN --mount=type=cache,target=/root/.cache/pip pip install --prefix=/install -r requirements.txt 2>/dev/null || pip install --prefix=/install .
COPY . .

FROM python:3.12-slim
WORKDIR /app
COPY --from=build /install /usr/local
COPY . .
RUN useradd -m app && chown -R app /app
USER app
CMD ["python", "-m", "app"]
EOF
;;
go)
cat > "$df" <<'EOF'
# syntax=docker/dockerfile:1
FROM golang:1.23 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .
RUN --mount=type=cache,target=/root/.cache/go-build CGO_ENABLED=0 go build -ldflags="-s -w" -o /app ./cmd/...

FROM gcr.io/distroless/static-debian12
COPY --from=build /app /app
USER nonroot:nonroot
ENTRYPOINT ["/app"]
EOF
;;
*) echo "unknown stack: $stack"; exit 2;;
esac

[[ -e "$di" ]] || cat > "$di" <<'EOF'
.git
node_modules
dist
build
__pycache__
*.log
.env
.DS_Store
EOF

echo "✔ wrote $df and $di ($stack). Review, then: docker build -t app ."
