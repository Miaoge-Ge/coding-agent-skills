---
name: api-design-expert
description: "Expert API design for REST & GraphQL: resource modeling, status codes, versioning, pagination, idempotency, errors, and contracts. Trigger keywords: API design, REST, RESTful, GraphQL, OpenAPI, endpoint, status code, versioning, pagination, cursor, idempotency, rate limit, contract, schema. Use to design or review HTTP/GraphQL APIs and their contracts."
---

# API Design Expert

> Design for the consumer and for change. Consistency beats cleverness: predictable naming, one error shape, accurate status codes, additive evolution. The contract is the product.

## When to Use
- Designing or reviewing a REST/GraphQL API.
- Resource modeling, naming, versioning, pagination, filtering.
- Error formats, status codes, idempotency, rate limiting.
- Writing an OpenAPI/GraphQL SDL contract.

## When NOT to Use
- Implementing the server framework → `nodejs-backend-expert` / language skill.
- DB schema/query design → `sql-expert`.
- Overall system topology/scaling → `software-architect`.

## Core Principles

### 1. Resource modeling (REST)
- Nouns, plural collections, hierarchy for relationships: `GET /orders/{id}/items`. No verbs in paths (`/getOrder` ❌).
- Methods carry semantics: **GET** safe & cacheable, **POST** create/non-idempotent, **PUT** full idempotent replace, **PATCH** partial, **DELETE** idempotent.
- Accurate status codes: `200/201/204`; `400` (malformed) vs `422` (valid syntax, semantic error) vs `409` (conflict); `401` (unauthenticated) vs `403` (unauthorized); `404`; `429` (rate limit). **Never** `200` with an error body.

### 2. One consistent contract
- Single error envelope everywhere: `{ "error": { "code", "message", "details" } }` with a stable machine-readable `code`.
- Consistent field naming/casing across all endpoints. Use ISO-8601 UTC timestamps, explicit currency/units, and string IDs. Document everything in OpenAPI/SDL — contract first.

### 3. Evolve without breaking
- Version at the edge (`/v1`, or media-type/header). Change **additively**; never repurpose, retype, or silently drop a field. Deprecate with headers + sunset dates.
- Make writes **idempotent**: support an `Idempotency-Key` for POST so retries don't double-charge. Document side effects.

### 4. Collections & resilience
- Paginate large collections — prefer **cursor/keyset** over offset for large or changing data. Provide filtering/sorting/field-selection explicitly and consistently.
- Publish rate limits (headers), auth scheme, and idempotency semantics. Validate every input; return precise field-level errors.

### 5. REST vs GraphQL
- REST for resource-centric, cacheable, simple-client APIs. GraphQL when clients need flexible nested selections — then prevent **N+1** with dataloaders, and limit query **depth/cost** to avoid abuse.

## Common Mistakes
- **`200` for errors** / inventing custom status semantics → use HTTP codes correctly.
- **Inconsistent error shapes** across endpoints → one envelope.
- **Offset pagination** on big datasets → slow + items skip/duplicate as data changes; use cursors.
- **Breaking changes without versioning** → broken clients.
- **Verbs in URLs / leaking DB schema** → model resources, not tables.
- **Non-idempotent POST with client retries** → duplicates; add idempotency keys.
- **Unbounded GraphQL queries** → DoS via deep/expensive queries.

## Examples

**Consistent error + cursor pagination (REST)**
```json
// GET /v1/orders?limit=20&cursor=eyJpZCI6MTQ0fQ
{
  "data": [ { "id": "ord_124", "total": 4200, "currency": "USD" } ],
  "page": { "next_cursor": "eyJpZCI6MTY0fQ", "has_more": true }
}
// Error (same shape on every endpoint)
{ "error": { "code": "validation_error", "message": "email is invalid",
             "details": [ { "field": "email", "rule": "format" } ] } }
```

**Idempotent create**
```http
POST /v1/payments
Idempotency-Key: 5f3c…   # server returns the same result for retries with this key
```

## See Also
- `nodejs-backend-expert` — implementing endpoints and validation.
- `sql-expert` — backing pagination/filters efficiently (keyset).
- `security-expert` — auth, scopes, rate limiting.
- `rag-expert` — designing retrieval/LLM endpoints and streaming responses.
