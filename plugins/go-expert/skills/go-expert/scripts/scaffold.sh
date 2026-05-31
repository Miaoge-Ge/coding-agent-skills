#!/usr/bin/env bash
# scaffold.sh — initialize a Go module with a conventional layout (cmd/, internal/),
# a Makefile, and a CI workflow. Never overwrites existing files.
# Usage: scripts/scaffold.sh MODULE_PATH [DIR]   e.g. github.com/me/app
set -euo pipefail
mod="${1:-}"; dir="${2:-.}"
[[ -z "$mod" ]] && { echo "usage: scaffold.sh MODULE_PATH [DIR]" >&2; exit 2; }
command -v go >/dev/null 2>&1 || { echo "go not found"; exit 127; }
app="${mod##*/}"
mkdir -p "$dir/cmd/$app" "$dir/internal/$app"
cd "$dir"
[[ -f go.mod ]] || go mod init "$mod"

w(){ [[ -e "$1" ]] && { echo "skip: $1"; return; }; cat > "$1"; echo "wrote $1"; }
w "cmd/$app/main.go" <<EOF
package main

import "fmt"

func main() {
	fmt.Println("hello from $app")
}
EOF
w "Makefile" <<'EOF'
.PHONY: build test lint
build: ; go build ./...
test:  ; go test -race ./...
lint:  ; go vet ./... && gofmt -l .
EOF
mkdir -p .github/workflows
w ".github/workflows/ci.yml" <<'EOF'
name: CI
on: [push, pull_request]
permissions: { contents: read }
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: "1.23", cache: true }
      - run: go vet ./...
      - run: go test -race ./...
EOF
echo "✔ module '$mod' ready. Build: make build  Test: make test"
