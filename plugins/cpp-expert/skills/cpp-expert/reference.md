# C++ Engineering Reference

Load for concrete build setup, ownership patterns, templates, and a UB checklist.

## Build (CMake, modern)
```cmake
cmake_minimum_required(VERSION 3.20)
project(app LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_executable(app src/main.cpp)
target_compile_options(app PRIVATE -Wall -Wextra -Wpedantic -Wshadow -Wconversion)
# Debug builds: sanitizers
target_compile_options(app PRIVATE $<$<CONFIG:Debug>:-fsanitize=address,undefined -g>)
target_link_options(app PRIVATE $<$<CONFIG:Debug>:-fsanitize=address,undefined>)
```
Build: `cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build`. Use `clang-tidy`, `cppcheck`, and `-fsanitize=address,undefined,thread` to catch real bugs.

## Ownership decision
| Need | Type |
|------|------|
| Sole owner | `std::unique_ptr<T>` |
| Shared ownership (truly) | `std::shared_ptr<T>` (+ `weak_ptr` for cycles) |
| Non-owning observer | `T*` or `T&` (or `std::span`/`string_view`) |
| Optional value | `std::optional<T>` |
| One of several types | `std::variant<...>` + `std::visit` |
| Value semantics | the value itself (rely on RVO/move) |
Rule of 0 (let the compiler generate special members) — or Rule of 5 if you manage a raw resource.

## Move semantics & forwarding
```cpp
void sink(std::string s);                 // takes ownership: pass by value
sink(std::move(name));                     // move into it
template <class T> void wrap(T&& x) {      // forwarding reference
    inner(std::forward<T>(x));             // preserve value category
}
```
- Don't `std::move` a local you then `return` (RVO already optimal; move *disables* NRVO).
- After `std::move(x)`, `x` is valid-but-unspecified — reassign before use.

## Templates & concepts (C++20)
```cpp
#include <concepts>
template <std::ranges::range R>
auto sum(const R& r) {
    std::ranges::range_value_t<R> total{};
    for (const auto& v : r) total += v;
    return total;
}
// constrain for clear call-site errors
template <class T> requires std::copyable<T> ...
```
Prefer concepts over SFINAE (`enable_if`). Use `if constexpr` for compile-time branching; ranges/views for composable, lazy algorithms.

## STL idioms
- `emplace_back`/`try_emplace` to construct in place; `reserve` before bulk inserts.
- Algorithms over hand loops: `std::ranges::sort`, `find_if`, `accumulate`, `transform`.
- `std::string_view`/`std::span` for non-owning params; never return a view to a temporary.

## UB / safety checklist
- [ ] No dangling refs/views (returning ref to local/temp).
- [ ] No use-after-move / use-after-free; smart pointers own resources.
- [ ] No out-of-bounds (`.at()` in debug, bounds checks at edges).
- [ ] No signed integer overflow; watch `size_t` underflow in subtraction.
- [ ] No uninitialized reads; initialize members (in-class initializers).
- [ ] No iterator/reference invalidation after container modification.
- [ ] No data races (protect shared state; `-fsanitize=thread`).
- [ ] Build clean under `-Wall -Wextra` + ASan/UBSan.

## Pitfalls → fixes
| Pitfall | Fix |
|---------|-----|
| owning raw `new/delete` | `make_unique`/`make_shared` + RAII |
| return `string_view` to temp | return owned `std::string` |
| `shared_ptr` everywhere | `unique_ptr` default; `weak_ptr` for cycles |
| C-style cast | `static_cast`/`dynamic_cast` |
| `std::endl` in loop | `'\n'` (avoid flush) |
| `[i]` past end | `.at()` / bounds-check |
| move-and-return local | just `return local;` (NRVO) |

## Script
`scripts/build-check.sh FILE.cpp` — compiles with strict warnings + ASan/UBSan and runs it; ideal for minimal UB/crash repros.
