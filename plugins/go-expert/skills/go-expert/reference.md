# Go Engineering Reference

Load for concrete concurrency patterns, error handling, project layout, and testing.

## Project layout
```
project/
├── cmd/app/main.go        # entrypoints (thin)
├── internal/              # private packages (not importable externally)
│   ├── service/
│   └── store/
├── pkg/                   # exported libraries (only if truly reusable)
└── go.mod
```
Organize by capability/domain, not by technical layer. Keep `main` thin; wire dependencies there.

## Error handling
```go
if err != nil {
    return fmt.Errorf("fetch user %d: %w", id, err)   // %w preserves the chain
}
// inspect
if errors.Is(err, sql.ErrNoRows) { /* sentinel */ }
var perr *PathError
if errors.As(err, &perr) { /* typed */ }
```
Sentinel errors: `var ErrNotFound = errors.New("not found")`. Custom: implement `Error()` (and `Unwrap()` to chain). Log once at the boundary; add context as it propagates.

## Concurrency patterns
**Worker pool (bounded)**:
```go
jobs := make(chan Job)
results := make(chan Result)
var wg sync.WaitGroup
for i := 0; i < runtime.NumCPU(); i++ {
    wg.Add(1)
    go func() { defer wg.Done(); for j := range jobs { results <- process(j) } }()
}
go func() { for _, j := range allJobs { jobs <- j }; close(jobs) }()
go func() { wg.Wait(); close(results) }()
for r := range results { /* collect */ }
```
**errgroup with context** (cancel-on-first-error, bounded): see SKILL example.
**Pipeline**: stages connected by channels, each closing its output; propagate `ctx` for cancellation.

Rules: the **sender** closes a channel, once. Every goroutine has an owner and an exit. `context.Context` is the first arg of cancelable calls and is never stored in a struct. Always test with `-race`.

## Interfaces
- Accept interfaces, return concrete types. Define interfaces in the **consumer** package; keep them tiny (`io.Reader`, `io.Writer`).
- Avoid premature interfaces — introduce when there's a second implementation or a test seam.

## Generics (1.18+)
```go
func Map[T, U any](xs []T, f func(T) U) []U {
    out := make([]U, len(xs))
    for i, x := range xs { out[i] = f(x) }
    return out
}
type Number interface { ~int | ~int64 | ~float64 }
```
Use for container/algorithm code; don't genericize where an interface is clearer.

## Testing
```go
func TestAdd(t *testing.T) {
    cases := []struct{ name string; a, b, want int }{
        {"zero", 0, 0, 0}, {"mixed", -1, 2, 1},
    }
    for _, c := range cases {
        t.Run(c.name, func(t *testing.T) {
            if got := Add(c.a, c.b); got != c.want {
                t.Errorf("Add(%d,%d)=%d want %d", c.a, c.b, got, c.want)
            }
        })
    }
}
```
Table-driven + subtests; `t.Parallel()` where safe; `httptest` for HTTP; golden files for big outputs; `-race` always; `testing.B` for benchmarks.

## HTTP service essentials
- `http.Server` with `ReadTimeout`/`WriteTimeout`/`IdleTimeout` (defaults are unbounded). Graceful shutdown via `server.Shutdown(ctx)` on SIGTERM.
- Pass `ctx` from `r.Context()` into downstream calls. Use `http.NewRequestWithContext`.

## Pitfalls → fixes
| Pitfall | Fix |
|---------|-----|
| loop var capture in goroutine | Go 1.22+ fixed; else `x := x` |
| ignored errors `_ =` | handle/return |
| goroutine leak (blocked forever) | provide ctx/close; bound lifetime |
| `WaitGroup.Add` inside goroutine | `Add` before `go` |
| concurrent map write | `Mutex` / `sync.Map` |
| typed-nil in interface | return `nil` explicitly, not a nil pointer |
| unbounded goroutines per request | worker pool / `errgroup.SetLimit` |

## Script
`scripts/check.sh [--fix]` — gofmt, go vet, `go test -race`, golangci-lint (if present).
