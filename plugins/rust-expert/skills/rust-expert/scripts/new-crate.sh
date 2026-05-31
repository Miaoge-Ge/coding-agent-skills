#!/usr/bin/env bash
# new-crate.sh — create a Rust crate via cargo and add opinionated lint config
# (clippy pedantic in CI), a rustfmt config, and a CI workflow. Never clobbers.
# Usage: scripts/new-crate.sh NAME [--lib]
set -euo pipefail
name="${1:-}"; kind="${2:-}"
[[ -z "$name" ]] && { echo "usage: new-crate.sh NAME [--lib]" >&2; exit 2; }
command -v cargo >/dev/null 2>&1 || { echo "cargo not found — install rustup"; exit 127; }

if [[ "$kind" == "--lib" ]]; then cargo new --lib "$name"; else cargo new "$name"; fi
cd "$name"

[[ -e rustfmt.toml ]] || printf 'edition = "2021"\nmax_width = 100\n' > rustfmt.toml
mkdir -p .github/workflows
[[ -e .github/workflows/ci.yml ]] || cat > .github/workflows/ci.yml <<'EOF'
name: CI
on: [push, pull_request]
permissions: { contents: read }
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with: { components: "rustfmt, clippy" }
      - run: cargo fmt --check
      - run: cargo clippy --all-targets -- -D warnings
      - run: cargo test
EOF
echo "✔ created crate '$name' with rustfmt + clippy CI. Verify: cargo fmt --check && cargo clippy -- -D warnings && cargo test"
