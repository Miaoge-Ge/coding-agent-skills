---
name: nextjs-expert
description: "Expert Next.js App Router: Server vs Client Components, data fetching, caching, server actions, and rendering strategy. Trigger keywords: Next.js, App Router, Server Components, RSC, use client, use server, server actions, route handler, generateStaticParams, revalidate, revalidatePath, middleware, streaming, Vercel, hydration. Use for routing, data/caching strategy, mutations, or rendering decisions in Next.js."
---

# Next.js Expert

> Server Components are the default; `"use client"` is a deliberate, leaf-level choice. Fetch on the server, cache explicitly, and keep secrets off the client.

## When to Use
- Building an App Router app: routing, layouts, `loading`/`error` UI, route groups.
- Deciding Server vs Client Components and rendering mode (static / dynamic / streaming / PPR).
- Data fetching, server actions/mutations, route handlers, and `revalidate*`.
- Debugging caching, hydration mismatches, or middleware.

## When NOT to Use
- Generic React hooks/component patterns → `react-expert`.
- Pure styling → `tailwind-expert`.
- A standalone (non-Next) API/server → `nodejs-backend-expert`.

## Core Principles

### 1. The server/client boundary is the whole game
- Everything is a **Server Component** unless it has `"use client"`. Add the directive only for state, effects, event handlers, or browser APIs — and keep it at the **leaves**.
- `"use client"` makes a component and its imported tree part of the client bundle. Pass server-fetched data down as props instead of pulling data into client components.
- **Never** import DB clients, secrets, or server-only SDKs into a client component. Guard with `import "server-only"`.

### 2. Fetch on the server, control caching explicitly
- `async`/`await` directly in Server Components; co-locate the fetch with the component that needs it (React dedups identical requests in a render).
- Caching is **opt-in and explicit** (especially Next 15, where fetches are uncached by default): `fetch(url, { cache: "force-cache" })`, `{ next: { revalidate: N } }` for ISR, or `{ cache: "no-store" }` for always-fresh.
- Tag data (`next: { tags: [...] }`) and invalidate precisely with `revalidateTag`/`revalidatePath` after writes.

### 3. Mutations via server actions
- `"use server"` functions for forms/mutations. **Validate and authorize on the server** — actions are public endpoints. Revalidate affected paths/tags afterward and return typed results.

### 4. Rendering & UX
- `loading.tsx` + `<Suspense>` to stream slow parts; `error.tsx` for boundaries; `generateStaticParams` to statically render dynamic routes.
- Use the `next/image`, `next/font`, and `<Link>` primitives — they fix common perf/CLS/font issues for free.

## Decision Guide
| Need | Do |
|------|-----|
| Read data for a page | `async` Server Component fetch |
| Always-fresh data | `cache: "no-store"` / `dynamic` |
| Rebuild every N seconds | `next: { revalidate: N }` (ISR) |
| Invalidate after a write | `revalidateTag` / `revalidatePath` |
| Interactivity (state/events) | small `"use client"` leaf |
| Mutation/form submit | server action (`"use server"`) |
| Slow section shouldn't block page | `<Suspense>` + `loading.tsx` |

## Common Mistakes
- **`"use client"` at the top of a big tree** → ships everything to the browser. Push it to leaves.
- **Assuming fetches are cached** (Next 15 default is no-cache) → set caching explicitly.
- **Secrets/DB access in a client component** → leaks to the bundle; use `server-only`.
- **Forgetting to revalidate after a server action** → stale UI.
- **`useEffect` data fetching in a page that could be a Server Component** → lose SSR, caching, and SEO.
- **Hydration mismatch** from `Date.now()`/`window`/random in render → guard or move to an effect/client component.

## Examples

**Server Component fetch with ISR + tags**
```tsx
// app/posts/page.tsx
export default async function Posts() {
  const posts = await fetch("https://api.example.com/posts", {
    next: { revalidate: 60, tags: ["posts"] },
  }).then((r) => r.json());
  return <ul>{posts.map((p) => <li key={p.id}>{p.title}</li>)}</ul>;
}
```

**Server action: validate, authorize, revalidate**
```tsx
// app/actions.ts
"use server";
import { revalidateTag } from "next/cache";
import { z } from "zod";

const Input = z.object({ title: z.string().min(1) });

export async function createPost(formData: FormData) {
  const { title } = Input.parse(Object.fromEntries(formData)); // validate
  const user = await requireUser();                            // authorize
  await db.post.create({ data: { title, authorId: user.id } });
  revalidateTag("posts");
}
```

## See Also
- `react-expert` — patterns inside client components.
- `typescript-expert` — typing pages, actions, and params.
- `api-design-expert` — route-handler contracts. `tailwind-expert` — styling.
