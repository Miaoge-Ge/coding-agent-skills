---
name: sql-expert
description: "Expert SQL & relational databases: queries, schema design, indexing, query-plan optimization, and transactions (Postgres/MySQL/SQLite). Trigger keywords: SQL, database, Postgres, MySQL, SQLite, JOIN, index, EXPLAIN, query plan, slow query, N+1, normalization, transaction, isolation, deadlock, migration. Use for writing/optimizing queries, designing schemas, or fixing slow/locking queries."
---

# SQL & Database Expert

> Think in sets, not loops. The database is smarter than your application loop. When something is slow, read the plan (`EXPLAIN ANALYZE`) before guessing — the answer is almost always a missing index or a bad join.

## When to Use
- Writing, debugging, or optimizing SQL.
- Schema design: tables, relationships, constraints, types, migrations.
- Slow queries, missing/unused indexes, N+1, lock contention.
- Transactions, isolation levels, and concurrency correctness.

## When NOT to Use
- ORM/app wiring → `nodejs-backend-expert` / language skill.
- Vector/semantic retrieval → `rag-expert`.
- Data-platform / warehouse-scale architecture → `software-architect`.

## Core Principles

### 1. Schema design
- Normalize to 3NF by default; denormalize only for a **measured** read win, and then keep it consistent (triggers/jobs).
- Right types: `timestamptz` (not naive timestamps), `numeric`/`decimal` for money (never float), `uuid`/`bigint` keys, native `enum`/`boolean`. Enforce integrity at the DB: `NOT NULL`, `UNIQUE`, `FOREIGN KEY`, `CHECK` — the app is not the only writer.

### 2. Query like a pro
- Select only needed columns (no `SELECT *` in app queries — it breaks covering indexes and over-fetches).
- Know your JOINs and beware **fan-out**: a one-to-many join multiplies rows and inflates `SUM`/`COUNT`. Pre-aggregate in a subquery/CTE.
- Kill **N+1** patterns: one query with a JOIN or `WHERE id IN (...)` instead of a query per row.
- `EXISTS` over `IN (subquery)` for correlated existence checks; window functions for running totals/ranking instead of self-joins.

### 3. Indexing
- Index columns in `WHERE`, `JOIN`, and `ORDER BY`. **Composite index order**: equality columns first, then the range/sort column. The index serves a left-to-right prefix.
- A function/expression on the column (`WHERE lower(email)=…`, `WHERE created_at::date=…`) defeats a plain index — index the expression or rewrite as a sargable range.
- Indexes speed reads, slow writes, and use space — add deliberately. Drop unused ones. Use partial/covering indexes for hot queries.

### 4. Read the plan & transactions
- `EXPLAIN (ANALYZE, BUFFERS)`. Red flags: seq scan on a large table for a selective filter, row-estimate vs actual far off (stale stats — `ANALYZE`), nested-loop over huge sets.
- Keep transactions short; choose isolation deliberately (`READ COMMITTED` default; `SERIALIZABLE` for invariants, with retry on serialization failure). Acquire locks in a consistent order to avoid deadlocks.

## Common Mistakes
- **`SELECT *`** in application code → over-fetch, fragile, no covering index.
- **Aggregates over a fanned-out JOIN** → doubled sums; aggregate before joining.
- **Functions on indexed columns in `WHERE`** → full scan.
- **Wrong composite-index column order** → index unused for the query.
- **Offset pagination on huge tables** (`OFFSET 100000`) → slow; use keyset/cursor pagination.
- **Floating-point money** → rounding errors; use `numeric`.
- **Implicit type mismatch** in joins/filters → silent full scans.

## Examples

**Avoid JOIN fan-out with a CTE; keyset pagination**
```sql
WITH totals AS (
  SELECT order_id, SUM(qty * unit_price) AS total
  FROM order_items GROUP BY order_id
)
SELECT o.id, o.created_at, t.total
FROM orders o
JOIN totals t ON t.order_id = o.id
WHERE (o.created_at, o.id) < ($1, $2)   -- keyset cursor, not OFFSET
ORDER BY o.created_at DESC, o.id DESC
LIMIT 20;
```

**Composite index matching a query**
```sql
-- WHERE tenant_id = $1 AND status = $2 ORDER BY created_at DESC
CREATE INDEX idx_orders_tenant_status_created
  ON orders (tenant_id, status, created_at DESC);
```

## See Also
- `nodejs-backend-expert` — calling the DB safely (pooling, parameterization).
- `performance-expert` — end-to-end latency and profiling.
- `api-design-expert` — cursor pagination contracts backed by SQL.
- `security-expert` — parameterization and least-privilege access.
