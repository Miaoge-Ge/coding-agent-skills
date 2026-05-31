# Rust Engineering Reference

Load for concrete error-handling, async, trait, and concurrency patterns.

## Error handling templates
**Library** — typed errors with `thiserror`:
```rust
use thiserror::Error;
#[derive(Error, Debug)]
pub enum StoreError {
    #[error("not found: {0}")]
    NotFound(String),
    #[error("db error")]
    Db(#[from] sqlx::Error),     // `?` converts automatically
}
pub type Result<T> = std::result::Result<T, StoreError>;
```
**Application** — `anyhow` with context:
```rust
use anyhow::{Context, Result};
fn load(p: &str) -> Result<Config> {
    let s = std::fs::read_to_string(p).with_context(|| format!("reading {p}"))?;
    toml::from_str(&s).context("parsing config")
}
```
Rule: libraries return concrete error enums (callers can match); apps use `anyhow`. Never `unwrap()` in library code.

## Ownership cookbook
| Problem | Pattern |
|---------|---------|
| Need to read data | borrow `&T` |
| Caller keeps ownership after call | take `&T`, return owned/derived |
| Shared read-only across threads | `Arc<T>` |
| Shared mutable, single thread | `Rc<RefCell<T>>` |
| Shared mutable, multi-thread | `Arc<Mutex<T>>` / `Arc<RwLock<T>>` |
| Two owners of a graph (cycles) | `Rc/Arc` + `Weak` to break cycles |
| Self-referential struct | redesign with indices, or `Pin`/crates (`ouroboros`) |

## Traits & generics
- Static dispatch (generics + bounds) by default — zero-cost. `impl Trait` in args/returns for ergonomics.
- `dyn Trait` (boxed) for heterogeneous collections, plugin points, or to cut monomorphization/binary size. Object-safe traits only.
- Blanket impls (`impl<T: Display> MyTrait for T`) and `From`/`TryFrom` for conversions so `?` composes. Derive `Debug, Clone, PartialEq, Eq, Hash` as appropriate.

## Async (tokio) patterns
```rust
// bounded concurrency
use futures::stream::{StreamExt, iter};
let results: Vec<_> = iter(urls)
    .map(|u| async move { fetch(u).await })
    .buffer_unordered(16)   // cap in-flight
    .collect().await;
```
- Never block the runtime: use async I/O; offload CPU/blocking with `tokio::task::spawn_blocking`.
- Don't hold a `std::sync::Mutex` guard across `.await` (use `tokio::sync::Mutex` if you must, but prefer message passing). Cancellation: drop the future, or `tokio::select!` with a shutdown signal.
- Share work via channels (`tokio::sync::mpsc`); fan-in results.

## Iterators over loops
```rust
let total: u64 = items.iter().filter(|i| i.active).map(|i| i.size).sum();
```
Lazy, allocation-free, and often faster than manual loops. Avoid collecting intermediates you don't need.

## `unsafe` checklist
- [ ] Is there a safe alternative? Prefer it.
- [ ] `unsafe` block is minimal and wrapped in a safe API.
- [ ] Invariants documented (`// SAFETY: ...`).
- [ ] Tested under **Miri** (`cargo +nightly miri test`) and sanitizers.

## Cargo & tooling
```
project/
├── Cargo.toml         # [dependencies], [dev-dependencies], workspace
├── src/lib.rs / main.rs
├── src/bin/, tests/, benches/
```
`cargo fmt`, `cargo clippy -- -D warnings`, `cargo test`, `cargo deny`/`cargo audit` for supply chain. Use workspaces for multi-crate repos.

## Pitfalls → fixes
| Pitfall | Fix |
|---------|-----|
| `.clone()` spam to beat borrowck | restructure ownership/scopes |
| `.unwrap()` in libs | propagate with `?` |
| return ref to local | return owned, or tie lifetime to input |
| guard across `.await` | drop guard first / message passing |
| `Vec<Box<dyn T>>` when generic works | use generics (static dispatch) |
| over-annotated lifetimes | rely on elision; add when asked |
| blocking in async | `spawn_blocking` |

## Script
`scripts/check.sh [--fix]` — rustfmt --check, clippy (deny warnings), tests.
