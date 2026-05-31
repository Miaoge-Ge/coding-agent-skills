---
name: nodejs-backend-expert
description: "Expert Node.js backends (Express/Fastify/Hono): routing, middleware, validation, auth, async, and production hardening. Trigger keywords: Node.js, Express, Fastify, Hono, REST, middleware, JWT, session, zod, async, streams, unhandled rejection, graceful shutdown, backend, server. Use for building HTTP services, structuring backends, or fixing async/error/security issues."
---

# Node.js Backend Expert

> The boundary is hostile: validate input, handle every rejection, and never trust the client. Keep handlers thin, push logic into services, and make the process production-safe (timeouts, health, graceful shutdown).

## When to Use
- Building/structuring an HTTP API or service in Node (Express, Fastify, Hono…).
- Routing, middleware, input validation, auth, sessions, rate limiting.
- Unhandled-rejection, error-propagation, streaming, or backpressure issues.
- Project layout: transport → service → data layer.

## When NOT to Use
- Next.js server features (RSC, server actions) → `nextjs-expert`.
- SQL/schema/indexing → `sql-expert`. API contract design → `api-design-expert`.
- Deep auth threat modeling/OWASP → `security-expert`.

## Core Principles

### 1. Layering
- Handlers/controllers stay thin (parse → call service → format response). Business logic lives in services; data access is isolated and mockable.
- Load config from env, **validated at startup** (`zod`/`envalid`); fail fast on missing/invalid config. No `process.env.X` scattered through code.

### 2. Async & error discipline
- `async/await` throughout. Every route's thrown error must reach a **central error handler** — wrap async handlers (or use Fastify/Express 5 which await handlers natively).
- Attach `process.on("unhandledRejection")`/`"uncaughtException"` to log and exit; don't swallow.
- Validate request body/query/params at the edge with a schema; reject early with 400 and a structured error.

### 3. Security baseline
- `helmet` for headers, explicit CORS allowlist, rate limiting on public/auth routes.
- Hash passwords with `argon2`/`bcrypt`; sign tokens/sessions with env secrets; cookies `HttpOnly`+`Secure`+`SameSite`. Never log secrets, tokens, or full request bodies with PII.
- Parameterize all DB access (no string-built SQL); cap body size.

### 4. Production-ready process
- `/health` (liveness) + readiness; **graceful shutdown** on `SIGTERM` (stop accepting, drain in-flight, close DB pool).
- Set server/socket timeouts. **Stream** large responses/uploads instead of buffering. Structured logging (`pino`) with request IDs.

## Decision Guide
| Need | Reach for |
|------|-----------|
| Max performance / schema-first | Fastify |
| Minimal/edge/runtime-agnostic | Hono |
| Ubiquitous ecosystem / familiarity | Express (use v5 for async error handling) |
| Input validation | `zod` / `valibot` at the boundary |
| Heavy CPU work | worker_threads / separate service (don't block the event loop) |

## Common Mistakes
- **Blocking the event loop** (sync crypto/`fs`, big JSON, CPU loops) → stalls all requests; offload to workers/streams.
- **Unhandled async errors** in Express 4 (thrown in a promise) → use a wrapper or Express 5.
- **Trusting client input** (mass assignment, unvalidated query) → validate + allowlist fields.
- **Catch-and-ignore** (`catch (e) {}`) → log with context and respond appropriately.
- **No timeouts / no shutdown** → hung sockets and dropped requests on deploy.
- **Secrets in code or logs** → env + secret manager; redact logs.

## Examples

**Central async error handling + validation (Express 5)**
```js
import express from "express";
import { z } from "zod";

const app = express();
app.use(express.json({ limit: "1mb" }));

const Body = z.object({ email: z.string().email(), name: z.string().min(1) });

app.post("/users", async (req, res) => {          // Express 5 awaits handlers
  const body = Body.parse(req.body);               // throws -> error middleware
  const user = await userService.create(body);
  res.status(201).json(user);
});

app.use((err, _req, res, _next) => {
  const status = err?.name === "ZodError" ? 400 : 500;
  if (status === 500) logger.error({ err }, "unhandled");
  res.status(status).json({ error: { message: err.message } });
});
```

**Graceful shutdown**
```js
const server = app.listen(3000);
for (const sig of ["SIGTERM", "SIGINT"]) {
  process.on(sig, () => server.close(() => db.end().then(() => process.exit(0))));
}
```

## See Also
- `api-design-expert` — endpoint contracts, versioning, pagination.
- `sql-expert` — the data layer behind services.
- `security-expert` — authn/authz and OWASP hardening.
- `docker-expert` / `kubernetes-expert` — packaging and running the service.
