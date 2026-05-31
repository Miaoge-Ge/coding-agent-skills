---
name: cpp-expert
description: "Expert modern C++ (17/20/23): safe, performant code, RAII, move semantics, templates/concepts, and UB diagnosis. Trigger keywords: C++, C++17, C++20, C++23, smart pointer, unique_ptr, RAII, move semantics, rvalue, template, concept, STL, undefined behavior, constexpr, memory, dangling. Use for C++ implementation, optimization, generic programming, or UB/memory issues."
---

# C++ Expert

> RAII owns every resource; values move, don't copy. Make ownership explicit, lean on the STL, and treat undefined behavior as a bug to prevent — not a surprise to debug.

## When to Use
- Writing or reviewing C++.
- Modern features (C++17/20/23), templates/metaprogramming, STL.
- Performance/memory tuning; smart pointers and ownership.
- Compile errors, crashes, leaks, or undefined behavior (UB).

## When NOT to Use
- Another language → relevant language skill.
- Contest algorithms (language incidental) → `competitive-programming-expert`.
- System/architecture design → `software-architect`.

## Core Principles

### 1. Modern by default
- Target C++17/20 unless constrained. Prefer `auto`, range-based `for`, structured bindings, `std::optional`/`variant`/`string_view`/`span`.
- Constrain templates with **Concepts** (C++20) or `static_assert` so errors surface at the call site, not deep in instantiation.

### 2. Ownership & RAII
- No owning raw pointers. `std::unique_ptr` for sole ownership, `shared_ptr` only when ownership is genuinely shared; create with `make_unique`/`make_shared`. Raw pointers/references are non-owning observers.
- Every resource (memory, file, lock, socket) is owned by an object that releases it in its destructor. Locks via `std::scoped_lock`/`lock_guard`.
- Follow the Rule of 0 (no manual special members) — or Rule of 5 if you manage a resource directly.

### 3. Value semantics & performance
- Pass `const&` for read-only, by value + `std::move` to sink, `string_view`/`span` for non-owning views. Rely on (N)RVO — return by value.
- Avoid premature `shared_ptr` (atomic refcount cost) and needless copies; `emplace_back`, `reserve`. Choose containers deliberately (`vector` by default). `constexpr`/`consteval` for compile-time work. Profile before micro-optimizing.

### 4. Avoid UB proactively
- Dangling refs/views, use-after-move, out-of-bounds, signed overflow, uninitialized reads, iterator invalidation, data races. Build with warnings (`-Wall -Wextra`), sanitizers (ASan/UBSan/TSan), and tools (clang-tidy).

## Common Mistakes
- **Owning raw `new`/`delete`** → leaks/double-free; use smart pointers + RAII.
- **Returning `string_view`/reference to a local/temporary** → dangling.
- **Using a moved-from object** beyond a valid-but-unspecified state.
- **`shared_ptr` everywhere** → atomic overhead + cycles (use `weak_ptr` to break).
- **C-style casts / `reinterpret_cast`** → use `static_cast`/`dynamic_cast`.
- **Iterator/reference invalidation** after container growth/erase.
- **`std::endl` in loops** → forced flush; use `'\n'`.

## Examples

**RAII + move-only ownership (C++17)**
```cpp
#include <memory>
#include <string>
#include <utility>

class Connection {
public:
    explicit Connection(std::string dsn) : dsn_(std::move(dsn)) { /* open */ }
    ~Connection() noexcept { /* close */ }
    Connection(const Connection&) = delete;            // non-copyable
    Connection& operator=(const Connection&) = delete;
    Connection(Connection&&) noexcept = default;        // movable
    Connection& operator=(Connection&&) noexcept = default;
private:
    std::string dsn_;
};

auto make_conn(std::string dsn) {
    return std::make_unique<Connection>(std::move(dsn)); // ownership is explicit
}
```

**Concept-constrained template (clear errors, no overflow)**
```cpp
#include <concepts>
template <std::integral T>
constexpr T midpoint(T a, T b) noexcept { return a + (b - a) / 2; }
```

## See Also
- `competitive-programming-expert` — STL-heavy solutions and constant-factor tuning.
- `performance-expert` — profiling and allocation reduction.
- `rust-expert` — comparing systems-language ownership models.
- `rules/cpp-style-guide.md` — enforceable style rules.
