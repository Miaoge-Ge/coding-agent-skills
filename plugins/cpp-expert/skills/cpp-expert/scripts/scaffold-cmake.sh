#!/usr/bin/env bash
# scaffold-cmake.sh — create a modern CMake C++ project with strict warnings and
# a Debug-config sanitizer setup. Never overwrites existing files.
# Usage: scripts/scaffold-cmake.sh PROJECT_NAME [DIR]
set -euo pipefail
name="${1:-}"; dir="${2:-.}"
[[ -z "$name" ]] && { echo "usage: scaffold-cmake.sh NAME [DIR]" >&2; exit 2; }
mkdir -p "$dir/src"
w(){ [[ -e "$1" ]] && { echo "skip: $1"; return; }; cat > "$1"; echo "wrote $1"; }

w "$dir/CMakeLists.txt" <<EOF
cmake_minimum_required(VERSION 3.20)
project($name LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)   # for clang-tidy / IDEs

add_executable($name src/main.cpp)
target_compile_options($name PRIVATE -Wall -Wextra -Wpedantic -Wshadow -Wconversion)
target_compile_options($name PRIVATE \$<\$<CONFIG:Debug>:-fsanitize=address,undefined -g>)
target_link_options($name    PRIVATE \$<\$<CONFIG:Debug>:-fsanitize=address,undefined>)
EOF

w "$dir/src/main.cpp" <<'EOF'
#include <iostream>
int main() {
    std::cout << "hello\n";
    return 0;
}
EOF
echo "✔ project '$name'. Build (Debug+sanitizers):"
echo "  cmake -S \"$dir\" -B \"$dir/build\" -DCMAKE_BUILD_TYPE=Debug && cmake --build \"$dir/build\""
