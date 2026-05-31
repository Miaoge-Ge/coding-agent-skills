---
name: react-expert
description: "Expert modern React (18/19): hooks, component design, state, performance, and Server Components. Trigger keywords: React, hooks, useState, useEffect, useMemo, useCallback, useRef, context, re-render, key, Suspense, Server Components, RSC, JSX, stale closure. Use when building/refactoring components or hooks, fixing render/effect bugs, or choosing a state-management approach."
---

# React Expert

> UI is a pure function of state. Derive during render; use effects only to sync with the outside world. Most "React performance" problems are really "I created an effect/state I didn't need."

## When to Use
- Building or refactoring React components and custom hooks.
- Bugs: stale state, infinite render loops, effects firing too often, lost input focus, extra re-renders.
- Choosing state management (local vs lifted vs context vs server cache vs store).
- Effects, refs, memoization, Suspense, or Server Components.

## When NOT to Use
- Pure TypeScript typing → `typescript-expert`.
- Next.js routing/server actions/caching specifics → `nextjs-expert`.
- Styling only → `tailwind-expert`. Accessibility semantics → `accessibility-expert`.

## Core Principles

### 1. Render is pure; derive don't sync
- Compute values from props/state **during render**. Don't mirror props into state, then sync with `useEffect` — that adds a render and bugs.
- Reset component state with a `key`, not an effect. Adjust state during render (the rare "store previous value" pattern) instead of in an effect when possible.

### 2. `useEffect` is an escape hatch
- It's for **synchronizing with external systems** (network, subscriptions, DOM, timers) — not for transforming data or responding to events.
- Event logic belongs in event handlers, not effects. If an effect only runs because a user did something, it's probably wrong.
- Always clean up (abort fetches, clear timers, unsubscribe) in the returned function. Give complete dependency arrays; if a dep "shouldn't" re-run things, restructure (move it into a ref, a reducer, or out of the component).

### 3. State, placed correctly
- Local `useState` → `useReducer` when transitions are related/complex → **lift** to the closest common parent → Context for low-frequency global values (theme, auth) → external store (Zustand/Redux) for high-frequency or cross-cutting state.
- **Server data is not UI state** — use TanStack Query or RSC fetching for caching, dedup, and revalidation. Don't hand-roll it in `useEffect`.

### 4. Performance: measure, then memo
- Profile with React DevTools first. Memoize only proven hot paths or referential-stability needs.
- `useMemo`/`useCallback` cost memory + comparison; sprinkling them everywhere is net-negative. `React.memo` only helps if props are referentially stable.
- React 19's compiler can auto-memoize — prefer clean code over manual memo when it's available.

### 5. Keys & lists
- Stable, identity-based `key` (an ID), never the array index for reorderable/insertable lists — index keys corrupt state and inputs.

## Decision Guide
| Need | Reach for |
|------|-----------|
| Value computed from props/state | derive in render (no state/effect) |
| Reset state when a prop changes | `key={...}` |
| Server data (fetch/cache/refetch) | TanStack Query / RSC |
| Global low-frequency value | Context |
| High-frequency / cross-tree state | Zustand/Redux |
| Imperative DOM / mutable value across renders | `useRef` |

## Common Mistakes
- **Derived state mirrored into `useState` + effect** → derive instead.
- **Missing/over-trimmed effect deps** → stale closures or loops; fix the cause, don't lie to the linter.
- **`useEffect` for data fetching without cleanup** → race conditions on fast prop changes; abort on cleanup or use a query lib.
- **Index as key** in dynamic lists → wrong item state after reorder/delete.
- **New object/array/function in render passed to memoized child** → defeats `React.memo`.
- **Calling hooks conditionally** → breaks the rules of hooks.

## Examples

**Derive, don't store-and-sync**
```jsx
// ❌ extra state + effect (renders twice, can desync)
const [full, setFull] = useState("");
useEffect(() => setFull(`${first} ${last}`), [first, last]);
// ✅
const full = `${first} ${last}`;
```

**Fetch effect that survives fast prop changes**
```jsx
useEffect(() => {
  const ctrl = new AbortController();
  let active = true;
  fetch(`/api/user/${id}`, { signal: ctrl.signal })
    .then((r) => r.json())
    .then((u) => active && setUser(u))
    .catch((e) => { if (e.name !== "AbortError") setError(e); });
  return () => { active = false; ctrl.abort(); };
}, [id]);
```

## See Also
- `nextjs-expert` — App Router, RSC, and server-side data fetching.
- `typescript-expert` — typing props, generic components, and events.
- `tailwind-expert` — styling. `accessibility-expert` — accessible interactions.
- `performance-expert` — profiling render hotspots.
