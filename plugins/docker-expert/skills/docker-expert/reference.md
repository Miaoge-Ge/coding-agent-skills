# Docker Engineering Reference

Load for concrete Dockerfiles, Compose, build optimization, and security hardening.

## Multi-stage templates
See `scripts/scaffold.sh` to generate these. Key ideas per stack:
- **Node**: build stage runs `npm ci` + build; runtime stage installs prod deps only and copies `dist/`. Non-root `node` user.
- **Go**: `CGO_ENABLED=0 go build`, then copy the static binary into `gcr.io/distroless/static` (tiny, no shell, `nonroot`).
- **Python**: install into a prefix in the build stage, copy `/usr/local` into a slim runtime; run as a created non-root user.

## BuildKit features (enable with `# syntax=docker/dockerfile:1`)
```dockerfile
# cache mount — persist package caches across builds
RUN --mount=type=cache,target=/root/.npm npm ci
# secret mount — never lands in a layer
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci
```
Build with secrets: `docker build --secret id=npmrc,src=$HOME/.npmrc .`

## Compose (local multi-service dev)
```yaml
services:
  api:
    build: .
    ports: ["3000:3000"]
    environment: { DATABASE_URL: postgres://app:app@db:5432/app }
    depends_on:
      db: { condition: service_healthy }
  db:
    image: postgres:16-alpine
    environment: { POSTGRES_USER: app, POSTGRES_PASSWORD: app, POSTGRES_DB: app }
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app"]
      interval: 5s
      retries: 5
    volumes: [pgdata:/var/lib/postgresql/data]
volumes: { pgdata: {} }
```

## Image size & cache checklist
- [ ] Slim/distroless base, pinned tag/digest.
- [ ] Deps installed before `COPY . .` (cache).
- [ ] Multi-stage: no compilers/dev deps in runtime.
- [ ] Caches cleaned in the same `RUN` (apt lists, npm cache).
- [ ] `.dockerignore` excludes `.git`, `node_modules`, build output, `.env`.
- [ ] `--mount=type=cache` for package managers; `--mount=type=secret` for tokens.

## Security checklist
- [ ] Non-root `USER`; read-only FS where possible.
- [ ] No secrets in `ARG`/`ENV`/layers (use BuildKit secrets / runtime env).
- [ ] Exec-form `CMD`/`ENTRYPOINT` (signal propagation) + `--init`/tini if it spawns children.
- [ ] `HEALTHCHECK` defined.
- [ ] Scan images (`docker scout cves`, `trivy image`) in CI; pin & update bases.

## Troubleshooting
| Symptom | Cause / fix |
|---------|-------------|
| Rebuild reinstalls deps every time | `COPY . .` before install — copy manifests first |
| Image huge | single-stage / dev deps / uncleaned caches — multi-stage + cleanup |
| Container won't stop on deploy | shell-form CMD → use exec form; handle SIGTERM |
| "permission denied" at runtime | files owned by root but `USER` non-root — `chown` in build |
| Secret leaked in `docker history` | was in ARG/ENV/layer — use `--mount=type=secret` |
| Zombie processes | PID 1 doesn't reap — add `--init` or tini |

## Scripts
- `scripts/analyze.sh [Dockerfile]` — hadolint (if present) + built-in heuristics.
- `scripts/scaffold.sh [node|python|go]` — generate a multi-stage Dockerfile + `.dockerignore`.
- `scripts/image-size.sh [tag] [ctx]` — build and report size + largest layers.
