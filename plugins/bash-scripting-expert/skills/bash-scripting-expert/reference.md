# Bash Engineering Reference

Load for robust-scripting patterns, argument parsing, and portability rules.

## Strict-mode header
```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```
- `-e` exit on error, `-u` error on unset var, `-o pipefail` fail if any pipe stage fails.
- **`-e` does NOT trigger** inside `if`/`while` conditions, `&&`/`||` chains, or command substitution. Check those explicitly.

## Argument parsing (getopts)
```bash
usage(){ echo "usage: $0 [-v] [-o OUT] <in>" >&2; exit 2; }
verbose=0; out=""
while getopts ":vo:h" opt; do case "$opt" in
  v) verbose=1;; o) out=$OPTARG;; h) usage;; *) usage;;
esac; done
shift $((OPTIND-1))
[[ $# -ge 1 ]] || usage
```
`scripts/new-script.sh PATH` generates this skeleton with an EXIT trap.

## Quoting & word-splitting (the #1 bug source)
- Always quote expansions: `"$var"`, `"${arr[@]}"`, `"$@"` (not `$*`).
- Unquoted `$var` splits on `$IFS` and globs. `"${arr[@]}"` preserves elements; `"$@"` preserves args.
- Iterate files safely: `find . -type f -print0 | while IFS= read -r -d '' f; do ...; done`.

## Errors, cleanup, exit codes
```bash
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT     # cleanup even on failure/^C
command -v jq >/dev/null || { echo "need jq" >&2; exit 1; }
```
- Errors/logs → stderr (`>&2`); keep stdout for real output so the script composes in pipes.
- Meaningful exit codes: `0` ok, `2` usage error, non-zero on failure.

## Subshell gotcha
`grep x | while read l; do ((n++)); done` — the `while` runs in a **subshell**; `$n` is lost. Use process substitution: `while read l; do ((n++)); done < <(grep x file)`.

## Portability
| Bash-only | POSIX sh alternative |
|-----------|----------------------|
| `[[ ... ]]` | `[ ... ]` |
| arrays | positional params / temp files |
| `local` | (none — restructure) |
| `${var//a/b}` | `sed` |
Declare `#!/usr/bin/env bash` if you use bashisms. `printf` over `echo` for anything with escapes/variables.

## Common idioms
```bash
"${VAR:-default}"        # default if unset/empty
"${VAR:?must be set}"    # error if unset
"${file%.txt}.md"        # strip suffix / change ext
"${path##*/}"            # basename ; "${path%/*}" dirname
mapfile -t lines < file  # read lines into an array (bash 4+)
```

## Pitfalls → fixes
| Pitfall | Fix |
|---------|-----|
| unquoted `$var` | `"$var"` |
| `for f in $(ls)` | glob or `find -print0` |
| backticks | `$(...)` |
| `[ $x = y ]` | `[[ $x == y ]]` |
| `echo -e` | `printf` |
| `cd dir; ...` | `cd dir || exit` |
| counter lost after pipe | process substitution |
| no temp cleanup | `trap 'rm -f "$tmp"' EXIT` |

## Scripts
- `scripts/check.sh FILE|DIR` — `bash -n` + shellcheck + shfmt (degrades gracefully).
- `scripts/new-script.sh PATH` — scaffold a strict-mode script (getopts + EXIT trap).
- `scripts/harden.sh FILE.sh` — heuristic review (unquoted vars, backticks, missing strict mode, ls-parsing…).
