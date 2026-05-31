#!/usr/bin/env bash
# init-config.sh — drop in a strict tsconfig.json, an ESLint flat config, and a
# Prettier config. Never overwrites existing files.
# Usage: scripts/init-config.sh [DIR]
set -euo pipefail
dir="${1:-.}"
mkdir -p "$dir"
w(){ [[ -e "$1" ]] && { echo "skip (exists): $1"; return; }; cat > "$1"; echo "wrote $1"; }

w "$dir/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "declaration": true,
    "sourceMap": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
EOF

w "$dir/eslint.config.js" <<'EOF'
// @ts-check
import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: { parserOptions: { projectService: true } },
    rules: { "@typescript-eslint/no-explicit-any": "error" },
  },
);
EOF

w "$dir/.prettierrc.json" <<'EOF'
{ "semi": true, "singleQuote": false, "trailingComma": "all", "printWidth": 100 }
EOF

echo "✔ done. Install: npm i -D typescript typescript-eslint @eslint/js eslint prettier"
echo "  then verify with: scripts/check.sh"
