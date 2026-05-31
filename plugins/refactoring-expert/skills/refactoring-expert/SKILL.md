---
name: refactoring-expert
description: "Expert safe, incremental, behavior-preserving refactoring. Trigger keywords: refactor, code smell, cleanup, technical debt, extract function, rename, inline, decouple, simplify, guard clause, legacy code, duplication, god class. Use to restructure code without changing behavior, reduce complexity, or pay down tech debt safely."
---

# Refactoring Expert

> Refactoring preserves behavior — full stop. Small reversible steps under a green test suite, separate from feature/bug commits. Refactor toward a goal, then stop.

## When to Use
- Cleaning up, simplifying, or decoupling existing code.
- Addressing code smells (long functions, duplication, deep nesting, god objects, primitive obsession, feature envy).
- Preparing messy code before adding a feature ("make the change easy, then make the easy change").
- Paying down technical debt in legacy code.

## When NOT to Use
- Adding behavior/features — that's not refactoring → relevant language skill.
- Fixing a defect → `debugging-expert`.
- Optimizing speed (may justify behavior/structure trade-offs) → `performance-expert`.

## Core Principles

### 1. Behavior must not change
- Refactoring changes structure, never observable behavior. Keep refactors in **separate commits** from features and bug fixes so review and rollback stay clean.
- If you find a bug mid-refactor, note it and fix it separately — don't smuggle a behavior change into a refactor.

### 2. Establish a safety net first
- Tests are what make refactoring safe. No tests around the code? Add **characterization tests** (capture current behavior, even if "wrong") before changing legacy code. Then refactor against green.

### 3. Small, reversible steps
- One named transformation at a time — Extract Function, Rename, Inline, Introduce Parameter Object, Replace Conditional with Polymorphism, Move Method — running tests after each. Commit frequently so any step is cheap to revert.
- Prefer IDE/automated refactorings (rename, extract) — they're safer than hand edits.

### 4. Target real smells, then stop
- Extract long functions into small, single-purpose, well-named ones. Remove duplication once a pattern is proven (**rule of three** — don't abstract on the first repeat).
- Flatten nesting with **guard clauses**/early returns. Replace magic numbers/flags with named constants/types. Improve names — good names delete the need for comments.
- Refactor in service of a goal (readability, an upcoming change), not endlessly. **Don't gold-plate** or add speculative generality (YAGNI).

## Common Mistakes
- **Mixing refactor + feature/bugfix** in one commit → unreviewable, risky rollback.
- **Refactoring without tests** → silent behavior changes; add characterization tests first.
- **Big-bang rewrite** instead of incremental steps → long-lived broken branch.
- **Premature abstraction / DRY-ing too early** → wrong abstraction is costlier than duplication; wait for the rule of three.
- **Speculative generality** ("might need it later") → complexity now for hypothetical futures.
- **Renaming/moving by hand** across a codebase → use automated refactors.

## Examples

**Guard clauses flatten nesting**
```js
// before — arrow-code, single deep happy path
function price(user, cart) {
  if (user) {
    if (cart.items.length) {
      return cart.total - discount(user);
    }
  }
  return 0;
}
// after — early returns, linear flow
function price(user, cart) {
  if (!user) return 0;
  if (cart.items.length === 0) return 0;
  return cart.total - discount(user);
}
```

**Extract a named function from a comment**
```python
# before:  # check if user can publish
if user.active and not user.banned and user.role in ("editor", "admin"):
    ...
# after:
def can_publish(user) -> bool:
    return user.active and not user.banned and user.role in ("editor", "admin")
if can_publish(user):
    ...
```

## See Also
- `testing-expert` — the safety net (incl. characterization tests).
- `debugging-expert` — when behavior changed unintentionally.
- `code-review` / `simplify` (built-in) — find cleanup opportunities in a diff.
