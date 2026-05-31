---
name: docker-expert
description: "Expert Docker: Dockerfiles, multi-stage builds, image size/cache optimization, Compose, and container best practices. Trigger keywords: Docker, Dockerfile, container, image, multi-stage, layer cache, docker-compose, .dockerignore, entrypoint, distroless, non-root, healthcheck, build context. Use for writing/optimizing Dockerfiles, shrinking images, faster builds, or Compose setup."
---

# Docker Expert

> Small, reproducible, non-root, cache-friendly. Order layers from least- to most-changing, build in one stage and ship artifacts from another, and never bake secrets into the image.

## When to Use
- Writing or optimizing a Dockerfile.
- Reducing image size, speeding builds, or fixing cache busting.
- Multi-service local dev with Compose.
- Container networking, volumes, signals, or startup issues.

## When NOT to Use
- Cluster orchestration, scaling, rollouts, probes → `kubernetes-expert`.
- The app code itself → the relevant language skill.
- CI pipeline YAML → `github-master`.

## Core Principles

### 1. Small & secure base
- Minimal, **pinned** bases: `node:22.4-slim`, `python:3.12-slim`, Alpine, or **distroless** for runtime. Never `:latest` (non-reproducible).
- Run as a **non-root** user (`USER`). Copy only what's needed; add a `.dockerignore` (`.git`, `node_modules`, build output, secrets) to shrink the build context and avoid leaking files.

### 2. Cache-efficient layers
- Order instructions least- → most-frequently-changing. **Copy dependency manifests and install before copying source**, so editing code doesn't bust the dependency layer.
- Combine related `RUN` steps and clean caches **in the same layer** (`apt-get … && rm -rf /var/lib/apt/lists/*`) — a separate cleanup layer doesn't shrink the image.
- Use BuildKit cache mounts (`RUN --mount=type=cache`) for package managers; pass secrets via `--mount=type=secret`, never `ARG`/`ENV`.

### 3. Multi-stage builds
- Heavy build/compile stage → copy only artifacts into a lean runtime stage. Drops compilers, dev deps, and source from the final image (often 5–20× smaller).

### 4. Correct runtime
- One concern per container. Use **exec-form** `CMD`/`ENTRYPOINT` (`["node","server.js"]`) so signals (SIGTERM) reach the process for graceful shutdown; add `--init` or `tini` if your process doesn't reap children.
- Add a `HEALTHCHECK`. Configure via env; persist data in volumes, not the writable layer.

## Common Mistakes
- **`COPY . .` before installing deps** → every code change reinstalls everything.
- **`:latest` / unpinned bases** → irreproducible builds.
- **Secrets in `ARG`/`ENV` or layers** → baked into history; use build secrets / runtime env.
- **Cleanup in a separate `RUN`** → image doesn't shrink (layers are additive).
- **Running as root** → larger blast radius; add a non-root `USER`.
- **Shell-form `CMD`** → PID 1 is the shell, signals don't propagate; container won't shut down cleanly.
- **No `.dockerignore`** → huge build context, slow builds, leaked files.

## Examples

**Multi-stage Node image, cache-friendly, non-root**
```dockerfile
# ---- build ----
FROM node:22-slim AS build
WORKDIR /app
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci   # cached unless manifests change
COPY . .
RUN npm run build

# ---- runtime ----
FROM node:22-slim
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist
USER node
HEALTHCHECK --interval=30s CMD node -e "fetch('http://localhost:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "dist/server.js"]
```

## See Also
- `kubernetes-expert` — deploying these images with probes and resources.
- `nodejs-backend-expert` / `go-expert` — the services you containerize.
- `security-expert` — image scanning and supply-chain safety.
- `github-master` — building/pushing images in CI.
