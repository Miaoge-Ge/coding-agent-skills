---
name: bash-scripting-expert
description: "Expert Bash scripting: robust, safe, portable shell scripts. Trigger keywords: bash, shell script, sh, quoting, word splitting, set -euo pipefail, trap, IFS, getopts, mktemp, shellcheck, POSIX, CLI, automation. Use for writing/debugging shell scripts and automation, or fixing quoting, exit-code, and portability bugs."
---

# Bash Scripting Expert

> Scripts fail in production on the input you didn't quote. Start strict, quote everything, clean up on exit, and run ShellCheck. When logic gets complex (JSON, data structures), switch to a real language.

## When to Use
- Writing or debugging a Bash/POSIX shell script or CI/automation glue.
- "Works until a path has a space/newline" bugs; word-splitting, globbing, quoting.
- Argument parsing, exit codes, error handling, temp files, cleanup.

## When NOT to Use
- Complex data/JSON/HTTP logic → `python-expert` (shell is the wrong tool).
- PowerShell scripting → use PowerShell tooling.
- CI pipeline YAML → `github-master`.

## Core Principles

### 1. Strict mode, every script
- `#!/usr/bin/env bash` + `set -euo pipefail`: exit on error, error on unset vars, fail on any pipeline stage. Set `IFS=$'\n\t'` to stop surprise word-splitting on spaces.
- Know `set -e`'s gotchas: it's suppressed inside `if`/`||`/`&&` conditions and command substitutions — check critical commands explicitly when needed.

### 2. Quote everything
- Always `"$var"`, `"${arr[@]}"`, `"$@"` (not `$*`). Unquoted expansions split on `IFS` and glob — the #1 source of bugs.
- Use `[[ … ]]` for tests (not `[ … ]`), `$(…)` not backticks, `(( … ))` for arithmetic, and `local` for all function variables.

### 3. Errors, cleanup, and exit codes
- `trap 'cleanup' EXIT` to remove temp files even on failure/interrupt. Create temps with `mktemp`.
- Validate args and required commands up front; print usage to **stderr** and `exit` non-zero on misuse. Exit codes are meaningful — `0` success, non-zero failure.
- Send errors/logs to `stderr` (`>&2`); keep `stdout` for real output so the script composes in pipes.

### 4. Robust file & data handling
- `printf` over `echo` for anything with escapes/variables. Use `--` before paths, and `find … -print0 | while IFS= read -r -d ''` for filenames with spaces/newlines.
- For POSIX `sh`, avoid bashisms (`[[`, arrays, `local`); if you use them, declare `bash` in the shebang. Lint with **ShellCheck** and format with `shfmt`.

## Common Mistakes
- **Unquoted `$var`** → breaks on spaces/globs/empties.
- **Parsing `ls`** or `for f in $(ls)` → use globs or `find -print0`.
- **`set -e` assumed to catch everything** → it won't inside conditions/substitutions; check explicitly.
- **`cd somewhere` without `||exit`** → subsequent commands run in the wrong directory.
- **No cleanup trap** → leftover temp files on failure.
- **`echo` with `-e`/escapes** → non-portable; use `printf`.
- **Mixing logs into stdout** → corrupts piped output.

## Examples

**Defensive script skeleton**
```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

usage() { printf 'usage: %s <input-dir> <out-file>\n' "$0" >&2; exit 2; }
[[ $# -eq 2 ]] || usage

input_dir=$1
out_file=$2
[[ -d $input_dir ]] || { printf 'no such dir: %s\n' "$input_dir" >&2; exit 1; }
command -v jq >/dev/null || { printf 'jq required\n' >&2; exit 1; }

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# safe iteration (handles spaces/newlines in names)
find "$input_dir" -type f -name '*.log' -print0 |
  while IFS= read -r -d '' f; do
    wc -l -- "$f" >> "$tmp"
  done

mv -- "$tmp" "$out_file"
trap - EXIT
printf 'wrote %s\n' "$out_file"
```

## See Also
- `github-master` — running scripts safely in GitHub Actions.
- `docker-expert` — robust container entrypoint scripts.
- `python-expert` — when a script outgrows the shell.
