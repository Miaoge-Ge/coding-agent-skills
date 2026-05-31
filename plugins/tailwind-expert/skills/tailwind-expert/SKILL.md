---
name: tailwind-expert
description: "Expert Tailwind CSS: utility-first styling, responsive/dark mode, theming, and design systems. Trigger keywords: Tailwind, CSS, utility classes, responsive, breakpoints, dark mode, design tokens, theme, @apply, cva, clsx, class-variance-authority, arbitrary values, shadcn. Use for styling UIs, responsive layouts, theming, or untangling class soup."
---

# Tailwind CSS Expert

> Constraints are the feature: style from the theme scale, not magic numbers. Composition + variants beat `@apply`. If a class string is unreadable, extract a component or a `cva` variant — not a custom CSS file.

## When to Use
- Styling components with Tailwind or migrating hand-written CSS → Tailwind.
- Responsive, dark-mode, or themeable layouts.
- Taming long/conditional class lists; building reusable styled primitives.
- Configuring the theme (colors, spacing, breakpoints, plugins).

## When NOT to Use
- Component state/logic → `react-expert`.
- Accessibility semantics beyond focus/contrast (ARIA, keyboard) → `accessibility-expert`.

## Core Principles

### 1. Stay on the scale
- Use theme tokens (`p-4`, `gap-2`, `text-lg`, `text-gray-600`) over arbitrary values (`p-[13px]`). Arbitrary values are an escape hatch, not the norm.
- Define brand colors/spacing/typography in the theme (Tailwind v4: `@theme` in CSS; v3: `tailwind.config`) so every utility stays consistent. Know your version — v4 is CSS-first and config is largely in CSS.

### 2. Manage class complexity by composition
- Repeated UI → a **component**, not copy-pasted class strings. `@apply` is only for tiny shared primitives, not whole components.
- Conditional/variant styling → `clsx` for booleans, `cva` (class-variance-authority) for structured variants. Merge conflicting classes with `tailwind-merge`.

### 3. Mobile-first, state-aware
- Unprefixed = base (smallest screen); layer up with `sm:`/`md:`/`lg:`. Never "undo" a larger breakpoint with a smaller one.
- Use state variants: `hover:`, `focus-visible:`, `active:`, `disabled:`, `aria-*:`, `data-*:`, `group-hover:`, `peer-checked:`, `dark:`.

### 4. Layout with flor/grid, theme with tokens
- Space items with `flex`/`grid` + `gap-*` rather than per-item margins.
- Dark mode: prefer `dark:` driven by a `class` strategy you toggle, so it's controllable and testable.

## Decision Guide
| Situation | Use |
|-----------|-----|
| One-off conditional classes | `clsx` |
| Component with size/intent variants | `cva` + `tailwind-merge` |
| Tiny shared primitive (e.g., `.btn-base`) | `@apply` |
| Truly bespoke value not in scale | arbitrary `[...]` (sparingly) |
| Spacing between siblings | `gap-*` on a flex/grid parent |

## Common Mistakes
- **`@apply` everywhere** → recreates the CSS-soup Tailwind avoids and loses co-location. Compose components instead.
- **Arbitrary values as default** (`mt-[7px]`) → inconsistent spacing; use the scale.
- **Conditionally concatenating strings** → conflicting classes ("last wins" is unreliable); use `tailwind-merge`.
- **Dynamic class names built from variables** (`` `text-${color}-500` ``) → purged away by the compiler; use full static class names or a lookup map.
- **Fighting specificity** → don't mix ad-hoc CSS; resolve within utilities.
- **Index/order assumptions** → utility order in the class attribute doesn't set precedence; the generated CSS order does.

## Examples

**Responsive, dark-mode card (tokens + states)**
```html
<article class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm
                transition hover:shadow-md
                dark:border-gray-800 dark:bg-gray-900
                sm:p-6 md:flex md:items-center md:gap-6">
  <img class="h-16 w-16 rounded-full object-cover" src="/avatar.jpg" alt="" />
  <div class="mt-3 md:mt-0">
    <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Title</h3>
    <p class="text-sm text-gray-600 dark:text-gray-400">Subtitle</p>
  </div>
</article>
```

**Type-safe variants with cva + safe merge**
```ts
import { cva, type VariantProps } from "class-variance-authority";
import { twMerge } from "tailwind-merge";

export const button = cva(
  "inline-flex items-center rounded-md px-3 py-2 text-sm font-medium focus-visible:ring-2 disabled:opacity-50",
  {
    variants: {
      intent: { primary: "bg-blue-600 text-white hover:bg-blue-700",
                ghost:   "bg-transparent text-blue-600 hover:bg-blue-50" },
      size:   { sm: "text-xs px-2 py-1", md: "text-sm" },
    },
    defaultVariants: { intent: "primary", size: "md" },
  },
);
export type ButtonProps = VariantProps<typeof button>;
// usage: className={twMerge(button({ intent: "ghost" }), className)}
```

## See Also
- `react-expert` — applying classes and variants in components.
- `accessibility-expert` — focus-visible states and contrast ratios.
- `nextjs-expert` — styling App Router apps and shared layouts.
