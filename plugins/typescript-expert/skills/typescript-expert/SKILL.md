---
name: typescript-expert
description: "Expert TypeScript: type system, generics, narrowing, inference, and strict-mode safety. Trigger keywords: TypeScript, types, generics, type narrowing, tsconfig, strict, discriminated union, conditional/mapped types, utility types, declaration files, type error, satisfies, infer, any vs unknown. Use when writing/refactoring TS, fixing cryptic type errors, designing type-safe/generic APIs, or configuring the compiler."
---

# TypeScript Expert

> Make illegal states unrepresentable. Let inference do the work; annotate boundaries, not internals. `any` is a hole in the type system — reach for `unknown` + narrowing instead.

## When to Use
- Writing or refactoring TypeScript and wanting types that catch real bugs.
- A cryptic type error needs explaining or fixing (`not assignable`, `excessively deep`, variance complaints).
- Designing generic, reusable library types or public API surfaces.
- Configuring `tsconfig.json`, writing `.d.ts`, or migrating JS → TS.

## When NOT to Use
- Runtime/algorithm logic unrelated to typing → relevant language skill.
- React-specific component/hook patterns → `react-expert`.
- Backend framework wiring → `nodejs-backend-expert`.

## Core Principles

### 1. Strictness is non-negotiable
- `strict: true` is the floor. Add `noUncheckedIndexedAccess` (array access is `T | undefined`), and for libraries `exactOptionalPropertyTypes` + `noImplicitOverride`.
- Don't disable `strict` to "make it compile" — the error is usually a real bug. Fix the model.

### 2. `any` vs `unknown`
- `any` disables checking and silently spreads. Ban it (`@typescript-eslint/no-explicit-any`).
- At untyped boundaries (JSON, `catch`, 3rd-party) use `unknown`, then **narrow** with a guard or schema (`zod`) before use.

### 3. Let inference work; annotate intent
- Annotate function **parameters** and public **return types**; let locals infer.
- Use `as const` for literal tuples/objects, and `satisfies` to validate a value against a type **without widening** it (keeps the precise inferred type).

### 4. Model with the type system
- **Discriminated unions** for state/variants; a shared literal `kind`/`status` field unlocks exhaustive narrowing.
- Derive, don't duplicate: `ReturnType`, `Parameters`, `Awaited`, `keyof`, indexed access (`T["field"]`), `Pick`/`Omit`/`Record`.
- Newtype/branded types for domain values (`type UserId = string & { __brand: "UserId" }`) to stop mixing IDs.

### 5. Generics with constraints
- Add a type parameter only when callers vary the type. Constrain it (`<T extends ...>`) so errors surface at the call site, not deep inside.
- Use `infer` in conditional types to extract; avoid gratuitous deep conditional types (slow + unreadable).

## Decision Guide
| Situation | Use |
|-----------|-----|
| Object shape, may be extended/implemented | `interface` |
| Unions, intersections, mapped/conditional, tuples | `type` |
| Validate a literal without losing its narrow type | `satisfies` |
| Untrusted external data | `unknown` + `zod`/guard |
| One of N known variants | discriminated union + exhaustive `switch` |
| Prevent mixing same-typed domain values | branded type |

## Common Mistakes
- **Type assertions (`as`) to silence errors** → hides real mismatches. Narrow or fix the type instead; `as` only when you genuinely know more than the compiler (and add a comment why).
- **`enum`** → prefer `as const` union (`type Role = "admin" | "user"`); enums have runtime cost and odd semantics.
- **Non-null `!` everywhere** → masks `undefined` bugs; narrow with a guard or restructure.
- **`Function`, `object`, `{}` as types** → far too wide. `{}` means "anything but null/undefined".
- **Optional vs `undefined` confusion** → `a?: T` and `a: T | undefined` differ under `exactOptionalPropertyTypes`.
- **`any` in catch** → it's `unknown` since TS 4.4; narrow `if (e instanceof Error)`.

## Examples

**Discriminated union + exhaustive `never` check**
```ts
type Result<T> =
  | { status: "ok"; data: T }
  | { status: "error"; error: string };

function unwrap<T>(r: Result<T>): T {
  switch (r.status) {
    case "ok": return r.data;
    case "error": throw new Error(r.error);
    default: {
      const _: never = r; // compile error if a new variant is added
      return _;
    }
  }
}
```

**`satisfies` keeps precise inference while validating shape**
```ts
const routes = {
  home: "/",
  user: (id: string) => `/users/${id}`,
} satisfies Record<string, string | ((...a: any[]) => string)>;
routes.home;        // type is "/" (not widened to string)
routes.user("42");  // typed callable
```

**Type predicate + branded id**
```ts
type UserId = string & { readonly __brand: unique symbol };
const asUserId = (s: string): UserId => s as UserId;     // single controlled cast
function isNonEmpty<T>(a: T[]): a is [T, ...T[]] { return a.length > 0; }
```

## See Also
- `react-expert` — typing props, hooks, events, and generics in components.
- `nodejs-backend-expert` — typing handlers, config, and validated input.
- `api-design-expert` — sharing contract types across client/server.
- `refactoring-expert` — tightening types as a safe, incremental refactor.
