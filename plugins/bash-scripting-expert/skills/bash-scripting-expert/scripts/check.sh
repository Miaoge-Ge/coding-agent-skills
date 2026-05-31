#!/usr/bin/env bash
# check.sh — lint & format-check shell scripts. Runs shellcheck and shfmt when
# installed; always runs `bash -n` syntax check so it works with no deps.
# Usage: scripts/check.sh FILE_OR_DIR ...   (default: .)
set -uo pipefail
targets=("$@"); [[ ${#targets[@]} -eq 0 ]] && targets=(".")
files=()
for t in "${targets[@]}"; do
  if [[ -d "$t" ]]; then while IFS= read -r f; do files+=("$f"); done < <(find "$t" -type f -name '*.sh'); else files+=("$t"); fi
done
[[ ${#files[@]} -eq 0 ]] && { echo "no .sh files found"; exit 2; }
status=0; sec(){ printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

sec "bash -n (syntax)"
for f in "${files[@]}"; do bash -n "$f" && echo "ok  $f" || { echo "BAD $f"; status=1; }; done

sec "shellcheck"
if command -v shellcheck >/dev/null 2>&1; then shellcheck "${files[@]}" || status=1
else echo "skip: shellcheck not installed (https://shellcheck.net)"; fi

sec "shfmt -d (format)"
if command -v shfmt >/dev/null 2>&1; then shfmt -d "${files[@]}" || status=1
else echo "skip: shfmt not installed (mvdan.cc/sh)"; fi

sec "result"; [[ $status -eq 0 ]] && echo "✔ passed" || echo "✘ issues found"
exit $status
