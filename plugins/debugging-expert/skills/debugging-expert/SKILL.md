---
name: debugging-expert
description: "Expert systematic debugging and root-cause analysis. Trigger keywords: debug, bug, error, exception, crash, stack trace, reproduce, root cause, works on my machine, intermittent, heisenbug, regression, git bisect, race condition. Use to diagnose failures methodically, find the real cause, and stop guess-and-check fixing."
---

# Debugging Expert

> Reproduce, then bisect. The bug is rarely where you think — follow evidence, change one variable at a time, and fix the cause (with a regression test), not the symptom.

## When to Use
- A bug, crash, exception, or wrong output to diagnose.
- Intermittent / "works on my machine" / heisenbug situations.
- Locating which change introduced a regression.
- Stuck guessing and editing code at random.

## When NOT to Use
- Writing the regression test after diagnosis → `testing-expert`.
- It's slow, not wrong → `performance-expert`.
- Refactoring without a defect → `refactoring-expert`.

## The Method

### 1. Reproduce reliably first
- Get a **minimal, deterministic reproduction** before changing anything — you can't confirm a fix for a bug you can't trigger. Pin inputs, environment, versions, and timing.
- For intermittent bugs, find what increases the rate (load, ordering, specific data, concurrency) and amplify it; add logging to capture the failing case.

### 2. Read the evidence
- Read the **entire** error and stack trace top to bottom — the root cause is often above the most obvious frame. Don't skim or assume.
- Check what changed: `git log`/`git diff` since it last worked, recent deploys, dependency bumps, config/env differences. Inspect logs around the failure timestamp.

### 3. Hypothesize → predict → test
- Form **one** hypothesis, predict exactly what you'd observe if it's true, then test that prediction. Confirm or eliminate before moving on.
- **Bisect** the search space: binary-search the code path, the input data, or history (`git bisect`). Add assertions/logging at the boundary between "still correct" and "already wrong" to bracket the defect.
- Question assumptions, including "this library/my framework can't be the problem." Verify, don't believe.

### 4. Fix the cause, prevent recurrence
- Explain **why** it happened before patching. Fix the root cause, not the visible symptom. Add a test that fails without the fix, then look for sibling bugs of the same class.

## Tactics by symptom
| Symptom | Tactic |
|---------|--------|
| Regression "used to work" | `git bisect` to the first bad commit |
| Intermittent/race | add logging/IDs, stress ordering, run with race detector |
| Wrong value somewhere | binary-search with assertions to bracket where state corrupts |
| "Works on my machine" | diff env/versions/config; reproduce in a clean container |
| Crash/exception | read full trace; reproduce the exact input |

## Common Mistakes
- **Changing multiple things at once** → you won't know what fixed (or broke) it.
- **Fixing the symptom** (swallow the exception, clamp the value) → bug resurfaces elsewhere.
- **Skimming the stack trace** → miss the real frame and root cause.
- **Debugging without a reproduction** → guessing; can't verify the fix.
- **Trusting assumptions** ("the input is valid", "the lib is fine") → verify each.
- **No regression test** after the fix → it comes back.
- **`print` shotgun everywhere** → use targeted, bracketing logging or a debugger/breakpoints.

## Examples

**Bisect a regression**
```bash
git bisect start
git bisect bad                 # current is broken
git bisect good v1.4.0         # known-good tag
# test each checkout, then mark good/bad; ~log2(N) steps -> first bad commit
git bisect reset
```

**Bracket where state goes wrong**
```python
assert invariant(state), f"invariant broke after step {i}: {state!r}"
# move the assert earlier/later to corner the corrupting step
```

## See Also
- `testing-expert` — lock the fix in with a failing-first regression test.
- `performance-expert` — same evidence-driven method, for "slow".
- `github-master` — `git bisect`, `reflog`, and history forensics.
