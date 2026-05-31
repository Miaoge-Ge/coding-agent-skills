---
name: security-expert
description: "Expert defensive application security and secure code review (OWASP Top 10). Trigger keywords: security, vulnerability, OWASP, injection, SQL injection, XSS, CSRF, SSRF, authentication, authorization, access control, secrets, JWT, session, dependency, secure coding, sanitization. Use to write secure code, review a diff for vulnerabilities, or harden an app. Defensive use only."
---

# Application Security Expert

> Defensive only: build and harden, don't attack. Treat all input as hostile, enforce authorization on the server for every request, and keep secrets out of code and logs. Default deny.

## When to Use
- Writing security-sensitive code (auth, input handling, file/URL/DB access, uploads).
- Reviewing a diff/feature for common vulnerabilities.
- Handling secrets, tokens, sessions, passwords, or dependencies.
- Hardening against the OWASP Top 10.

## When NOT to Use
- Building exploits, offensive tooling, or attacks on systems you don't own → decline.
- General correctness bugs → `debugging-expert`.
- Cluster RBAC/NetworkPolicy specifics → `kubernetes-expert`.

## Core Principles

### 1. Trust boundaries & input
- All external input is hostile (body, query, headers, files, env, upstream APIs). **Validate against an allowlist**, then **encode/escape for the destination context** (HTML, SQL, shell, URL, LDAP).
- **Injection**: parameterized queries / prepared statements only — never concatenate untrusted data into SQL or shell commands. Avoid `eval`/dynamic command execution on user input.
- **XSS**: context-aware output encoding + a strict `Content-Security-Policy`; avoid `innerHTML`/`dangerouslySetInnerHTML` with untrusted data.

### 2. AuthN vs AuthZ (the #1 real-world gap)
- Authenticate with vetted libraries; hash passwords with `argon2`/`bcrypt` (never `md5`/`sha1`/plaintext). Cookies `HttpOnly`+`Secure`+`SameSite`; short-lived tokens with rotation.
- **Authorize every request on the server** with object-level checks (does *this* user own *this* resource?). Never trust client-supplied roles, IDs, or hidden fields. **Default deny.** This is Broken Access Control — OWASP #1.
- Protect state-changing requests from **CSRF** (tokens or `SameSite`), and validate redirect targets / server-side fetch URLs against an allowlist to prevent **SSRF** and open redirects.

### 3. Secrets & data
- Secrets in env/secret manager, never in code, git, or client bundles. Rotate on exposure. **Never log** secrets, tokens, passwords, or PII.
- TLS in transit; encrypt sensitive data at rest; minimize collection/retention. Don't leak stack traces or internal details in error responses.

### 4. Dependencies & supply chain
- Pin and audit deps (`npm audit`, `pip-audit`, `cargo audit`, Dependabot/Renovate); patch known-vuln packages promptly. Verify integrity (lockfiles) and prefer maintained libraries over hand-rolled crypto.

## Review checklist
- [ ] Every query parameterized? [ ] Output encoded for its context + CSP?
- [ ] Server-side authz on every endpoint/object? [ ] Default deny?
- [ ] Secrets out of code/logs? [ ] Passwords hashed with argon2/bcrypt?
- [ ] CSRF + SSRF/redirect protections? [ ] Deps audited & pinned?
- [ ] File uploads validated (type/size/path)? [ ] Errors don't leak internals?

## Common Mistakes
- **String-built SQL/commands** → injection; parameterize.
- **Authorization only on the client / missing object-level checks** → IDOR, privilege escalation.
- **Trusting role/userId from the request** → spoofing; derive from the authenticated session.
- **Secrets in code, env files in git, or logs** → leakage.
- **Plaintext/weak password hashing** → mass compromise on breach.
- **Reflecting user input unescaped** → XSS. **Unvalidated server-side fetch** → SSRF.
- **Verbose error/stack traces to clients** → info disclosure.

## Examples

**Parameterized query + server-side object authorization**
```python
# ❌ injectable
cur.execute(f"SELECT * FROM docs WHERE id = '{doc_id}'")
# ✅ parameterized
cur.execute("SELECT * FROM docs WHERE id = %s", (doc_id,))

def get_document(user, doc_id):
    doc = repo.find(doc_id)
    if doc is None or doc.owner_id != user.id:   # object-level access control
        raise Forbidden()                         # default deny
    return doc
```

## See Also
- `nodejs-backend-expert` / `api-design-expert` — secure endpoints, auth flows, rate limits.
- `sql-expert` — parameterization and least-privilege DB access.
- `docker-expert` / `kubernetes-expert` — image scanning, secrets, network policy.
- `security-review` (built-in) — automated review of pending changes.
