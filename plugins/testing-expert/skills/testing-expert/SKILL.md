---
name: testing-expert
description: "Expert software testing: unit/integration/e2e, TDD, test doubles, fixtures, and flakiness. Trigger keywords: testing, unit test, integration test, e2e, TDD, mock, stub, fake, spy, fixture, coverage, flaky test, assertion, test pyramid, snapshot. Use for writing tests, designing test strategy, or fixing flaky/brittle/slow tests."
---

# Software Testing Expert

> Test behavior, not implementation — that's what survives refactors. Fast and deterministic beats exhaustive. A bug fixed without a failing test first will come back.

## When to Use
- Writing unit/integration/e2e tests for new or existing code.
- Designing a test strategy or adopting TDD.
- Flaky, slow, or brittle tests that break on harmless changes.
- Mocking/stubbing, fixtures, fakes, and coverage decisions.

## When NOT to Use
- LLM/model evaluation specifically → `llm-testing-expert`.
- Diagnosing a specific known failure → `debugging-expert`.
- Performance benchmarking → `performance-expert`.

## Core Principles

### 1. Test the contract, not the internals
- Assert on observable behavior and public outputs/effects, not private methods or call counts. Tests coupled to implementation block refactoring and create false failures.
- Follow the **test pyramid**: many fast unit tests, fewer integration tests, a thin layer of e2e for critical user journeys. Push detail down to the cheapest level that can catch the bug.
- Cover edge cases and error paths, not just the happy path. Boundary values, empties, nulls, concurrency, and failures are where bugs live.

### 2. Good test shape
- **Arrange–Act–Assert**, one behavior per test, names that state the expectation (`returns 401 when token expired`).
- Tests must be **deterministic and independent**: no shared mutable state, no order dependence, no real clock/network/randomness leaking in.

### 3. Test doubles, sparingly
- Mock/stub/fake only at **boundaries** you don't own (network, DB, clock, filesystem, randomness). Never mock the unit under test.
- Inject those dependencies (time, IDs, I/O) so tests control them. Prefer **fakes** (in-memory impl) over brittle mock-verification chains. Over-mocking tests the mocks, not the code.

### 4. Reliability & coverage
- Eliminate flakiness at the source: fake time, `await` real conditions instead of `sleep`, control async ordering, isolate test data. Quarantine and fix flaky tests — don't retry-until-green.
- Coverage finds **untested branches**; it's a flashlight, not a goal. 100% coverage of trivial code ≠ quality; a critical untested branch at 90% is the real risk.

## TDD loop
**Red** (write a failing test for the next behavior) → **Green** (simplest code to pass) → **Refactor** (clean up with the test as safety net). Especially valuable for bug fixes: reproduce as a failing test first.

## Common Mistakes
- **Asserting implementation details** (private calls, exact internal state) → brittle; assert outcomes.
- **`sleep()` to wait for async** → flaky and slow; await a condition/event.
- **Over-mocking** → tests pass while real integration breaks; use fakes and some integration tests.
- **Interdependent / order-dependent tests** → spooky failures; isolate state.
- **Testing only the happy path** → bugs hide in errors/edges.
- **Snapshot tests for everything** → giant snapshots nobody reviews; snapshot small, stable output only.
- **Chasing a coverage number** → tests written to touch lines, not to assert behavior.

## Examples

**Behavior test with a controlled boundary (pytest)**
```python
def test_token_expires(monkeypatch):
    clock = {"now": 1000}
    monkeypatch.setattr(auth, "now", lambda: clock["now"])  # fake the clock

    token = auth.issue(ttl=60)        # valid until 1060
    assert auth.is_valid(token)

    clock["now"] = 1061               # advance time deterministically
    assert not auth.is_valid(token)   # asserts behavior, not internals
```

**Bug → failing test first**
```python
def test_discount_never_negative():   # reproduces the reported bug
    assert price(items=[], coupon="HUGE") == 0   # was returning -5
```

## See Also
- `debugging-expert` — turn a bug into a failing test, then fix.
- `refactoring-expert` — tests are the safety net for restructuring.
- `github-master` — run tests + coverage gates in CI.
- `llm-testing-expert` — evaluation for LLM systems.
