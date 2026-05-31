---
name: accessibility-expert
description: "Expert web accessibility (a11y): WCAG 2.2 AA, semantic HTML, ARIA, keyboard, and screen readers. Trigger keywords: accessibility, a11y, WCAG, ARIA, role, screen reader, keyboard navigation, focus, focus trap, contrast, alt text, semantic HTML, label, axe, tab order. Use to build accessible UI, audit/fix a11y issues, or add accessible behavior to widgets."
---

# Web Accessibility Expert

> The first rule of ARIA is don't use ARIA — a native `<button>` beats `<div role="button">` every time. Target WCAG 2.2 AA. If it doesn't work with the keyboard, it isn't done.

## When to Use
- Building UI you want accessible from the start.
- Auditing/fixing issues: keyboard traps, unlabeled controls, low contrast, missing focus.
- Adding accessible behavior to custom widgets (modal, menu, tabs, combobox, accordion, tooltip).
- Forms, images, dynamic updates, and motion.

## When NOT to Use
- Pure visual styling without semantics → `tailwind-expert`.
- Component state logic → `react-expert`.

## Core Principles

### 1. Semantics first, ARIA last
- Use the native element for the job (`<button>`, `<a href>`, `<label>`, `<nav>`, `<main>`, `<dialog>`, `<input type>`). They bring role, state, and keyboard behavior for free.
- **No ARIA is better than bad ARIA.** Don't add roles to elements that already have them; don't override native semantics. ARIA changes how AT announces — it does **not** add behavior (you still wire keyboard/focus yourself).

### 2. Keyboard operability (WCAG 2.1.1)
- Everything actionable is reachable and operable by keyboard: Tab to move, Enter/Space to activate, Esc to dismiss, arrows within composite widgets (menus, tabs, radios).
- Keep a **visible focus indicator** (`:focus-visible`). Never `outline:none` without a clear replacement.
- Logical tab order = DOM order. Avoid positive `tabindex`; use `tabindex="-1"` for programmatic focus, `0` to add non-interactive elements to tab order only when necessary.

### 3. Focus management for overlays
- Dialogs/menus: move focus **in** on open, **trap** within, restore to the trigger on close, and make background `inert`/`aria-hidden`. Prefer the native `<dialog>` element.

### 4. Name, role, value (WCAG 4.1.2)
- Every control has an accessible name: `<label for>`, wrapping `<label>`, `aria-label`, or `aria-labelledby`. Icon-only buttons need an accessible name (visually-hidden text or `aria-label`).
- Images: meaningful `alt`; decorative → `alt=""`. Communicate state with `aria-expanded`/`-selected`/`-checked`/`-current`/`-pressed`, and announce async changes via a live region (`aria-live="polite"`, or `role="alert"` for errors).

### 5. Perceivable
- Contrast ≥ **4.5:1** (text), **3:1** (large text & UI components/focus indicators — new in 2.2). Never rely on color alone to convey meaning.
- Honor `prefers-reduced-motion`. Don't disable zoom; support 200% text scaling.

## Common Mistakes
- **`<div onClick>` as a button** → not focusable or keyboard-operable; use `<button>`.
- **Placeholder as a label** → disappears on input; use a real `<label>`.
- **`role` without behavior** → `role="button"` still needs `tabindex="0"` + Enter/Space handlers (so just use `<button>`).
- **Removing focus outlines** for looks → keyboard users get lost.
- **`aria-label` on a non-interactive `<div>`** → often ignored; put names on real controls.
- **Toast/error not announced** → wrap in a live region.
- **`tabindex` > 0** → breaks natural order.

## Examples

**Accessible icon button + disclosure**
```html
<button type="button" aria-expanded="false" aria-controls="menu">
  <svg aria-hidden="true" focusable="false">…</svg>
  <span class="sr-only">Open menu</span>
</button>
<ul id="menu" hidden>…</ul>
<!-- toggle hidden + aria-expanded together in JS; Esc closes and returns focus -->
```

**Form field wired to its label and error**
```html
<label for="email">Email</label>
<input id="email" name="email" type="email"
       aria-describedby="email-err" aria-invalid="true" required />
<p id="email-err" role="alert">Enter a valid email address.</p>
```

## See Also
- `tailwind-expert` — `focus-visible` styles and meeting contrast ratios.
- `react-expert` — focus management, `inert`, and accessible component patterns.
- `testing-expert` — automated checks with `axe-core`/`jest-axe` in CI.
