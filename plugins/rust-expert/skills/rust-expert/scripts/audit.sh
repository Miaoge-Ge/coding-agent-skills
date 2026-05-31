#!/usr/bin/env bash
# audit.sh — supply-chain & hygiene checks for a Cargo project: known security
# advisories (cargo-audit), policy/license/bans (cargo-deny), and outdated deps.
# Installs hints if a tool is missing; never fails just because a tool is absent.
# Usage: scripts/audit.sh
set -uo pipefail
command -v cargo >/dev/null 2>&1 || { echo "cargo not found"; exit 127; }
[[ -f Cargo.toml ]] || { echo "no Cargo.toml in $(pwd)"; exit 2; }
status=0; sec(){ printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

sec "cargo audit (RUSTSEC advisories)"
if cargo audit --version >/dev/null 2>&1; then cargo audit || status=1
else echo "skip: cargo install cargo-audit"; fi

sec "cargo deny (advisories/licenses/bans)"
if cargo deny --version >/dev/null 2>&1; then cargo deny check || status=1
else echo "skip: cargo install cargo-deny (needs deny.toml)"; fi

sec "outdated deps"
if cargo outdated --version >/dev/null 2>&1; then cargo outdated -R || true
else echo "skip: cargo install cargo-outdated"; fi

sec "result"; [[ $status -eq 0 ]] && echo "✔ no advisories (from available tools)" || echo "✘ issues found — review above"
exit $status
