#!/usr/bin/env bash
# new-script.sh — scaffold a robust Bash script with strict mode, usage,
# getopts argument parsing, and an EXIT trap for cleanup. Never overwrites.
# Usage: scripts/new-script.sh PATH [Title...]
set -euo pipefail
out="${1:-}"; [[ -z "$out" ]] && { echo "usage: new-script.sh PATH [title]" >&2; exit 2; }
shift || true
title="${*:-script}"
[[ -e "$out" ]] && { echo "refusing to overwrite $out" >&2; exit 1; }

cat > "$out" <<EOF
#!/usr/bin/env bash
# ${out##*/} — ${title}
set -euo pipefail
IFS=\$'\n\t'

usage() {
  cat >&2 <<USAGE
usage: \$0 [-v] [-o OUT] <input>
  -v        verbose
  -o OUT    output path (default: stdout)
USAGE
  exit 2
}

verbose=0; out=""
while getopts ":vo:h" opt; do
  case "\$opt" in
    v) verbose=1 ;;
    o) out=\$OPTARG ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift \$((OPTIND - 1))
[[ \$# -ge 1 ]] || usage
input=\$1

tmp=\$(mktemp)
trap 'rm -f "\$tmp"' EXIT

[[ \$verbose -eq 1 ]] && echo "processing \$input" >&2
# --- do work into "\$tmp" ---
printf 'processed %s\n' "\$input" > "\$tmp"

if [[ -n \$out ]]; then mv -- "\$tmp" "\$out"; trap - EXIT; else cat "\$tmp"; fi
EOF

chmod +x "$out" 2>/dev/null || true
echo "✔ wrote $out (strict mode, getopts, EXIT-trap cleanup). Lint it: scripts/check.sh $out"
