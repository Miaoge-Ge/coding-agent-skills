---
name: go-expert
description: "Expert idiomatic Go: concurrency, interfaces, error handling, and the standard library. Trigger keywords: Go, golang, goroutine, channel, context, select, interface, error wrapping, errors.Is, defer, sync, Mutex, WaitGroup, errgroup, race, pprof. Use for writing/refactoring Go, designing concurrency, or fixing races, leaks, and deadlocks."
---

# Go Expert

> Clear is better than clever. Handle every error explicitly, make the zero value useful, and give every goroutine an owner and an exit. "Share memory by communicating," but a `Mutex` is fine for protecting state.

## When to Use
- Writing or refactoring Go.
- Designing concurrent code (goroutines, channels, `context`, `select`).
- Data races, deadlocks, goroutine leaks, or context propagation bugs.
- Package layout, interfaces, and standard-library usage.

## When NOT to Use
- Other languages → the relevant language skill.
- System-level architecture → `software-architect`.

## Core Principles

### 1. Errors are explicit values
- Check immediately: `if err != nil { return fmt.Errorf("doing X: %w", err) }`. Wrap with `%w` to preserve the chain; inspect with `errors.Is` (sentinel) / `errors.As` (typed).
- Add context at each layer ("opening config: …") but don't double-log the same error. Return errors up; log once at the boundary.
- Panic only for truly unrecoverable programmer errors, never for normal control flow.

### 2. Interfaces & types
- **Accept interfaces, return concrete types.** Keep interfaces small (often one method) and define them in the **consumer** package, not the producer.
- Make the **zero value useful** (`sync.Mutex`, `bytes.Buffer` work unboxed). Use `defer` for cleanup (close/unlock) right after acquisition.

### 3. Concurrency with ownership
- Every goroutine needs a clear lifetime and exit path — leaks are silent. Use `sync.WaitGroup` or `errgroup` to wait, and **bound** concurrency (`errgroup.SetLimit`, worker pool, semaphore).
- `context.Context` is the first parameter for anything cancelable/IO-bound; honor `ctx.Done()`. Never store a Context in a struct.
- Channels for handoff/signaling; `Mutex` for protecting shared state. Close a channel from the **sender**, once. Prefer `select` with `ctx` for cancelable waits.

### 4. Tooling & structure
- `gofmt` (non-negotiable), `go vet`, `golangci-lint`. **Always test concurrent code with `-race`.**
- Organize by capability; keep private code under `internal/`. Avoid premature interfaces and needless abstraction.

## Common Mistakes
- **Loop variable capture** in goroutines/closures — historically `for i, v := range` needed `i, v := i, v`; fixed in Go 1.22+, but know your version.
- **Ignoring errors** (`_ = f()`) or only logging without returning.
- **Goroutine leak**: a goroutine blocked on a channel/`ctx` that never fires — always provide cancellation.
- **`WaitGroup.Add` inside the goroutine** → race; call `Add` before `go`.
- **Mutating a map concurrently** → fatal race; guard with `Mutex` or use `sync.Map` for the right pattern.
- **Returning an interface holding a nil pointer** → `err != nil` is true unexpectedly (typed-nil trap).
- **Unbounded goroutine spawning** per request → resource exhaustion.

## Examples

**Bounded concurrency with errgroup + context**
```go
func fetchAll(ctx context.Context, urls []string) ([]string, error) {
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(10) // cap concurrency
    out := make([]string, len(urls))
    for i, u := range urls { // Go 1.22+: no manual capture needed
        i, u := i, u
        g.Go(func() error {
            req, _ := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
            resp, err := http.DefaultClient.Do(req)
            if err != nil {
                return fmt.Errorf("get %s: %w", u, err)
            }
            defer resp.Body.Close()
            b, err := io.ReadAll(resp.Body)
            out[i] = string(b)
            return err
        })
    }
    return out, g.Wait() // first error cancels the rest via ctx
}
```

**Sentinel error inspection**
```go
if errors.Is(err, sql.ErrNoRows) { return nil, ErrNotFound }
```

## Bundled Resources
- **`reference.md`** — project layout, error wrapping, concurrency patterns (worker pool/pipeline/errgroup), interfaces, generics, table-driven testing, HTTP service essentials, pitfalls. Read for non-trivial Go tasks.
- **`scripts/check.sh`** — gofmt, go vet, `go test -race`, golangci-lint. Run `bash scripts/check.sh [--fix]`.

## See Also
- `performance-expert` — `pprof`, escape analysis, allocation reduction.
- `testing-expert` — table-driven tests and `-race`.
- `docker-expert` — tiny static images (`FROM scratch`/distroless).
- `rust-expert` — alternative ownership-based concurrency model.
