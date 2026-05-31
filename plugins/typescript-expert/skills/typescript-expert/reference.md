# TypeScript Engineering Reference

Load when the task needs concrete config, advanced types, or build/declaration details.

## Strict tsconfig (baseline)
```jsonc
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noUncheckedIndexedAccess": true,   // arr[i] is T | undefined
    "exactOptionalPropertyTypes": true, // a?: T  ≠  a: T | undefined
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "verbatimModuleSyntax": true,        // explicit type-only imports
    "isolatedModules": true,             // safe for esbuild/swc/babel
    "skipLibCheck": true,
    "declaration": true,                 // emit .d.ts for libraries
    "sourceMap": true
  }
}
```
For libraries publish `types`, `exports`, and dual ESM/CJS if needed. For apps, let the bundler (vite/esbuild/tsup) emit; use `tsc --noEmit` only for type-checking.

## Narrowing toolkit
| Tool | Use |
|------|-----|
| `typeof x === "string"` | primitives |
| `x instanceof C` | class instances |
| `"key" in obj` | structural presence |
| discriminated union on `kind` | tagged variants |
| user-defined guard `x is T` | custom predicates |
| `assert` functions | `asserts x is T` to narrow + throw |
| `satisfies` | validate literal without widening |

## Advanced types cookbook
```ts
// Derive, don't duplicate
type Keys = keyof Config;
type Value = Config["timeout"];
type Args = Parameters<typeof fn>;
type Ret  = Awaited<ReturnType<typeof fetchUser>>;

// Mapped + template literal
type Getters<T> = { [K in keyof T & string as `get${Capitalize<K>}`]: () => T[K] };

// Conditional + infer
type ElementOf<T> = T extends readonly (infer U)[] ? U : never;

// Branded nominal type
type Email = string & { readonly __brand: "Email" };
const toEmail = (s: string): Email => { if (!s.includes("@")) throw 0; return s as Email; };

// Exhaustiveness
function assertNever(x: never): never { throw new Error(`unexpected: ${x}`); }
```
Keep conditional/mapped types shallow — deep recursion is slow and unreadable. If a type is hard to read, it's hard to maintain; prefer a named helper or a runtime schema.

## Runtime validation at boundaries
Types vanish at runtime. Validate external data (HTTP, env, files) with `zod`/`valibot` and **derive** the static type:
```ts
import { z } from "zod";
const User = z.object({ id: z.string(), age: z.number().int() });
type User = z.infer<typeof User>;          // single source of truth
const user = User.parse(await res.json()); // throws on bad data
```

## Declaration files & module augmentation
- Ambient types: `declare module "untyped-lib" { export function f(): void }`.
- Augment globals/3rd-party: `declare global { interface Window { analytics: Analytics } }`.

## Performance & DX
- `skipLibCheck: true` and project references (`tsc -b`) speed large builds. `incremental: true` caches.
- Avoid massive union types and deep conditional recursion (compiler slowdowns / "type instantiation is excessively deep").
- Prefer `interface` for hot, extended object types (cached) over large intersections.

## Pitfalls → fixes
| Pitfall | Fix |
|---------|-----|
| `as` to silence errors | narrow/guard; `as` only with a why-comment |
| `any` spreading | `unknown` + validate at boundary |
| `enum` | `as const` union (`type X = "a"\|"b"`) |
| `!` non-null everywhere | narrow or restructure |
| `{}`/`object`/`Function` types | precise shapes / `(...a:unknown[])=>unknown` |
| optional vs `undefined` | mind `exactOptionalPropertyTypes` |
| `catch (e)` typed `any` | it's `unknown` (4.4+); `e instanceof Error` |

## Quality gate
`scripts/check.sh [path]` — `tsc --noEmit`, eslint, prettier --check. Run in CI on PRs.
