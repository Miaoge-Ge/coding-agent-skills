---
name: rust-expert
description: "Expert Rust: ownership, borrowing, lifetimes, traits, async, and idiomatic error handling. Trigger keywords: Rust, ownership, borrow checker, lifetime, move, clone, trait, generics, async, tokio, Result, Option, ?, thiserror, anyhow, unsafe, Arc, Mutex, cargo, Send, Sync. Use for writing/refactoring Rust, resolving borrow-checker/lifetime errors, or designing safe abstractions."
---

# Rust Expert

> Fight the design, not the borrow checker — a borrow error is usually a real aliasing/lifetime problem. Make invalid states unrepresentable, return errors as values, and reach for `clone()`/`unsafe` deliberately, never to silence the compiler.

## When to Use
- Writing or refactoring Rust.
- Borrow-checker, lifetime, move/`clone`, or `Send`/`Sync` errors.
- Designing traits, generics, error types, or APIs.
- Async (tokio), iterators, smart pointers, or vetting `unsafe`.

## When NOT to Use
- Other languages → the relevant language skill.
- High-level system architecture → `software-architect`.

## Core Principles

### 1. Ownership & borrowing by design
- Borrow (`&T`/`&mut T`) over cloning; `clone()` is a real cost you choose, not an error silencer.
- The rule: many `&T` **xor** one `&mut T`. When it fights you, restructure: narrow scopes, split borrows, index-based access, or interior mutability (`Cell`/`RefCell` single-thread, `Mutex`/`RwLock` multi-thread).
- Params take `&str`/`&[T]`/`impl AsRef<_>`; store owned `String`/`Vec<T>`. Return owned data or borrow tied to an input lifetime.

### 2. Errors are values
- Return `Result<T, E>`; propagate with `?`. Avoid `unwrap()`/`expect()` outside tests, `main`, or provably-infallible spots (and then `expect()` with a reason).
- **Libraries**: typed errors with `thiserror` (impl `std::error::Error`, use `#[from]`). **Apps**: `anyhow::Result` with `.context("…")`.
- `Option` for absence, `Result` for failure. Don't panic on recoverable conditions.

### 3. Model with the type system
- Enums to make illegal states unrepresentable; newtype pattern for domain values and to add trait impls.
- Generics + trait bounds by default; `dyn Trait` (boxed) for heterogeneous collections, plugin points, or smaller code size. Derive `Debug`/`Clone`/`PartialEq` where sensible; impl `From` for conversions so `?` composes.

### 4. Async & concurrency
- Pick one runtime (usually `tokio`). **Never block the executor** — use async I/O; offload CPU/blocking work to `spawn_blocking` or a thread pool.
- Share state with `Arc<Mutex<T>>`/`Arc<RwLock<T>>`; hold locks for the shortest possible scope and never across `.await`. Move ownership across tasks via channels.

### 5. `unsafe` is a contract
- Only for proven needs (FFI, niche perf). Wrap it in a safe API, document the invariants you uphold, and keep `unsafe` blocks minimal. Run Miri/sanitizers.

## Common Mistakes
- **`.clone()` / `.to_owned()` spam** to dodge borrow errors → restructure ownership instead.
- **`.unwrap()` in library/production code** → propagate with `?` or handle.
- **Self-referential structs / returning refs to locals** → return owned data or rethink lifetimes; reach for an index or `Rc`/`Arc`.
- **Holding a `MutexGuard` across `.await`** → deadlocks/`!Send` futures; drop the guard first.
- **Over-annotating lifetimes** → most are elided; add them only when the compiler asks.
- **`Vec<Box<dyn Trait>>` when generics suffice** → unnecessary dynamic dispatch.

## Examples

**Idiomatic library error type**
```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ConfigError {
    #[error("missing field: {0}")]
    Missing(String),
    #[error(transparent)]
    Io(#[from] std::io::Error),   // `?` converts io::Error automatically
}

pub fn load(path: &str) -> Result<String, ConfigError> {
    let text = std::fs::read_to_string(path)?;
    if text.trim().is_empty() {
        return Err(ConfigError::Missing("body".into()));
    }
    Ok(text)
}
```

**Make invalid states unrepresentable**
```rust
enum Connection {
    Disconnected,
    Connecting { attempt: u8 },
    Connected { session: String },   // a session ONLY exists when connected
}
```

## See Also
- `performance-expert` — profiling, allocation reduction, flamegraphs.
- `testing-expert` — `#[test]`, integration tests, `proptest`.
- `cpp-expert` — comparing systems-language trade-offs.
- `go-expert` — different concurrency model for the same problem space.
