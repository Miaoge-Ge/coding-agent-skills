---
description: C++ coding standards (Modern C++17/20/23) — memory safety, RAII, exception safety, naming, and code organization. Auto-attach for C/C++ source and header files.
globs: *.cpp,*.hpp,*.h,*.cc,*.cxx
alwaysApply: false
---

# C++ Coding Standards (Modern C++17/20/23)

## Key Rules

- **Memory safety**: Never manage resources with raw pointers — use smart pointers (`unique_ptr`/`shared_ptr`) or containers.
- **RAII**: Acquire resources in constructors, release in destructors; mark non-throwing constructors `noexcept`.
- **Modern features**: Prefer `auto`, range-based `for`, `constexpr`, and `nullptr`; never use `NULL` or `0` for pointers.
- **Exception safety**: Specify exception guarantees (`noexcept` or documented); destructors must be `noexcept`.
- **Type safety**: Forbid C-style casts — use `static_cast`/`dynamic_cast`; avoid `reinterpret_cast`.
- **Template constraints**: Constrain template parameters with `concept` (C++20) or `static_assert` to produce clear compile errors.
- **Performance**: Prefer move semantics (`&&`) and perfect forwarding; avoid unnecessary copies; avoid virtual calls on hot paths.
- **Compile safety**: Every header needs `#pragma once` or an include guard; prefer forward declarations over `#include`.

## Naming Conventions

- Classes/structs: `PascalCase` (`HttpRequest`, `JsonParser`)
- Variables/functions: `snake_case` (`process_data()`, `max_buffer_size`)
- Private members: trailing underscore (`private_member_`) or `m_` prefix (`m_private_member`) — be consistent across the team
- Macros/constants: `UPPER_SNAKE_CASE` (`BUFFER_SIZE`, `DEBUG_MODE`)
- Template parameters: `CamelCase` (`InputIt`, `Alloc`)

## Code Organization

- Headers expose interfaces only; implementation goes in `.cpp` (template classes excepted).
- Single responsibility: at most ~5 public methods per class; functions under ~30 lines (simple delegation excepted).
- Include order: related header → C libraries → C++ libraries → third-party → project headers, with a blank line between groups.
- Never `using namespace std;`; use targeted `using std::string` instead.

## Memory & Resources

- Zero tolerance for raw `new`/`delete` — use `std::make_unique` and `std::make_shared`.
- Use `std::vector` or `std::array` for arrays; never C-style arrays (`int arr[10]`).
- Use `std::string`; never raw `char*` operations (`strcpy`, `sprintf`, etc.).
- Manage locks with `std::lock_guard` or `std::unique_lock`; never bare `mutex.lock()`.

<example>
// Correct: RAII, smart pointers, exception safety, modern C++
class FileProcessor {
public:
    explicit FileProcessor(std::string_view path)
        : file_(std::fopen(path.data(), "r")) {
        if (!file_) {
            throw std::runtime_error("Failed to open file: " + std::string(path));
        }
    }

    // Disable copy, enable move
    FileProcessor(const FileProcessor&) = delete;
    FileProcessor& operator=(const FileProcessor&) = delete;

    FileProcessor(FileProcessor&& other) noexcept
        : file_(std::exchange(other.file_, nullptr)) {}

    ~FileProcessor() noexcept {
        if (file_) std::fclose(file_);
    }

    std::string read_all() {
        std::string content;
        constexpr size_t buffer_size = 4096;
        std::vector<char> buffer(buffer_size);

        while (std::fgets(buffer.data(), buffer.size(), file_)) {
            content.append(buffer.data());
        }
        return content;
    }

private:
    std::FILE* file_;
};

// Usage
void process() {
    auto processor = std::make_unique<FileProcessor>("data.txt");
    auto content = processor->read_all(); // Return value optimization (RVO)
}
</example>

<example type="invalid">
// Wrong: raw pointers, memory leaks, not exception-safe, C-style
class BadProcessor {
public:
    BadProcessor(const char* path) {
        file = fopen(path, "r"); // may fail, unchecked
        buffer = new char[1024]; // raw new
    }

    ~BadProcessor() {
        fclose(file);
        delete[] buffer; // skipped if the constructor throws -> leak
    }

    char* read() {
        fgets(buffer, 1024, file);
        return buffer; // dangling-pointer risk
    }

private:
    FILE* file;
    char* buffer;
};
</example>
