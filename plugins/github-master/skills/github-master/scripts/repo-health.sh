#!/usr/bin/env bash
# repo-health.sh — audit a repo for community/CI hygiene. Checks essential files
# and, if `gh` is authenticated, branch protection on the default branch.
# Usage: scripts/repo-health.sh [REPO_DIR]   (default: .)
set -uo pipefail
dir="${1:-.}"; cd "$dir" || { echo "no such dir: $dir"; exit 2; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repo: $dir"; exit 2; }
n=0; ok(){ printf '  \033[32m✔ %s\033[0m\n' "$1"; }; miss(){ printf '  \033[33m✘ %s\033[0m\n' "$1"; n=$((n+1)); }

echo "== essential files =="
for x in README.md LICENSE .gitignore; do [[ -e "$x" ]] && ok "$x" || miss "missing $x"; done
[[ -e CONTRIBUTING.md ]] && ok "CONTRIBUTING.md" || miss "no CONTRIBUTING.md"
{ [[ -e CODEOWNERS ]] || [[ -e .github/CODEOWNERS ]]; } && ok "CODEOWNERS" || miss "no CODEOWNERS"
ls .github/workflows/*.y*ml >/dev/null 2>&1 && ok "CI workflow(s)" || miss "no .github/workflows/*.yml (CI)"
ls .github/ISSUE_TEMPLATE* .github/PULL_REQUEST_TEMPLATE* >/dev/null 2>&1 && ok "issue/PR templates" || miss "no issue/PR templates"

echo "== git hygiene =="
big=$(git ls-files | grep -iE '\.(zip|jar|exe|dll|mp4|psd)$' | head -3 || true)
[[ -z "$big" ]] && ok "no obvious binaries tracked" || { miss "binaries tracked (use LFS/.gitignore):"; echo "$big" | sed 's/^/      /'; }
git log -1 --pretty=%s 2>/dev/null | grep -Eq '^(feat|fix|docs|chore|refactor|test|build|ci|perf)(\(.+\))?!?:' \
  && ok "last commit follows Conventional Commits" || echo "  · tip: adopt Conventional Commits for automated changelogs"

echo "== branch protection (needs gh, authenticated) =="
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  br=$(git symbolic-ref --short HEAD 2>/dev/null || echo main)
  if gh api "repos/{owner}/{repo}/branches/$br/protection" >/dev/null 2>&1; then ok "branch '$br' is protected"; else miss "branch '$br' has no protection rule"; fi
else echo "  · gh not available/authenticated — skipped"; fi

echo "== $([[ $n -eq 0 ]] && echo '✔ healthy' || echo "⚠ $n item(s) to address") =="
exit 0
