#!/usr/bin/env bash
# scaffold-ci.sh — create a least-privilege GitHub Actions CI workflow plus a
# PR template and CODEOWNERS. Never overwrites existing files.
# Usage: scripts/scaffold-ci.sh [node|python|go|generic] [REPO_DIR]
set -euo pipefail
stack="${1:-generic}"; dir="${2:-.}"
mkdir -p "$dir/.github/workflows"
wf="$dir/.github/workflows/ci.yml"

steps_generic='      - run: echo "add build/test steps"'
case "$stack" in
  node)   setup='      - uses: actions/setup-node@v4
        with: { node-version: "22", cache: npm }
      - run: npm ci
      - run: npm test --if-present';;
  python) setup='      - uses: actions/setup-python@v5
        with: { python-version: "3.12", cache: pip }
      - run: pip install -e .[dev] || pip install -r requirements.txt
      - run: pytest -q';;
  go)     setup='      - uses: actions/setup-go@v5
        with: { go-version: "1.23", cache: true }
      - run: go vet ./...
      - run: go test -race ./...';;
  *)      setup="$steps_generic";;
esac

if [[ -e "$wf" ]]; then echo "skip (exists): $wf"; else
cat > "$wf" <<EOF
name: CI
on:
  pull_request:
  push: { branches: [main] }
permissions:
  contents: read
concurrency:
  group: ci-\${{ github.ref }}
  cancel-in-progress: true
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
$setup
EOF
echo "wrote $wf ($stack)"; fi

pr="$dir/.github/PULL_REQUEST_TEMPLATE.md"
[[ -e "$pr" ]] || { cat > "$pr" <<'EOF'
## What & why

## How tested

## Checklist
- [ ] Tests added/updated
- [ ] Docs updated if needed
- [ ] Linked issue (Fixes #)
EOF
echo "wrote $pr"; }

co="$dir/.github/CODEOWNERS"
[[ -e "$co" ]] || { printf '# Default owners for everything\n# *       @your-team\n' > "$co"; echo "wrote $co (edit owners)"; }
echo "✔ done. Pin action SHAs for stricter supply-chain safety."
