#!/usr/bin/env python3
"""Validate every plugin/skill in the marketplace.

Checks per plugin:
  - plugin.json is valid JSON and `name` matches the directory
  - each skill has a SKILL.md with frontmatter, name==dir, non-empty description,
    balanced code fences, and (for non-threejs) the required sections
  - reference.md exists
  - >= MIN_SCRIPTS scripts exist, and each script is syntactically valid
    (bash -n for *.sh / *.bash; py_compile for *.py; node --check for *.mjs/*.js)

Exit code is non-zero if any ERROR is found. Use --strict to also fail on
plugins below the script minimum (the rollout target).

Usage: python tests/validate_skills.py [--strict]
"""
from __future__ import annotations
import json, re, subprocess, sys, shutil
from pathlib import Path

# Make output robust on Windows/GBK consoles and CI.
for _s in (sys.stdout, sys.stderr):
    try:
        _s.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
    except Exception:
        pass

def _run(cmd: list[str]):
    return subprocess.run(cmd, capture_output=True, text=True,
                          encoding="utf-8", errors="replace")

def _bash_works() -> bool:
    """True only if `bash -n` can parse a known-good script with our path style.
    Guards against WSL-bash-on-Windows, which mangles Windows paths."""
    if not shutil.which("bash"):
        return False
    import tempfile, os
    fd, name = tempfile.mkstemp(suffix=".sh")
    try:
        os.write(fd, b"#!/usr/bin/env bash\nset -euo pipefail\necho ok\n"); os.close(fd)
        return _run(["bash", "-n", name]).returncode == 0
    except Exception:
        return False
    finally:
        try: os.unlink(name)
        except OSError: pass

BASH_OK = _bash_works()

ROOT = Path(__file__).resolve().parent.parent
MIN_SCRIPTS = 3
REQUIRED = ["## When to Use", "## When NOT to Use", "## See Also"]
strict = "--strict" in sys.argv

errors: list[str] = []
warns: list[str] = []

def check_script(p: Path) -> str | None:
    """Return an error string if the script is invalid, else None."""
    ext = p.suffix
    try:
        if ext in (".sh", ".bash") or (ext == "" and p.read_text(errors="ignore").startswith("#!")):
            if BASH_OK:
                r = _run(["bash", "-n", str(p)])
                return None if r.returncode == 0 else f"bash -n failed: {r.stderr.strip()[:200]}"
            return None  # no usable bash (e.g. WSL on Windows) — checked in CI instead
        if ext == ".py":
            r = _run([sys.executable, "-m", "py_compile", str(p)])
            return None if r.returncode == 0 else f"py_compile failed: {r.stderr.strip()[:200]}"
        if ext in (".mjs", ".js") and shutil.which("node"):
            r = _run(["node", "--check", str(p)])
            return None if r.returncode == 0 else f"node --check failed: {r.stderr.strip()[:200]}"
    except Exception as e:  # pragma: no cover
        return f"could not check: {e}"
    return None

def main() -> int:
    plugins = sorted(ROOT.glob("plugins/*/.claude-plugin/plugin.json"))
    if not plugins:
        print("no plugins found"); return 1
    n_ok_scripts = 0
    print(f"Validating {len(plugins)} plugins (min {MIN_SCRIPTS} scripts each)\n")
    for pj in plugins:
        pdir = pj.parent.parent
        slug = pdir.name
        try:
            meta = json.loads(pj.read_text(encoding="utf-8"))
        except Exception as e:
            errors.append(f"{slug}: plugin.json invalid JSON: {e}"); continue
        if meta.get("name") != slug:
            errors.append(f"{slug}: plugin.json name={meta.get('name')!r} != dir")

        skills = sorted((pdir / "skills").glob("*/SKILL.md"))
        if not skills:
            errors.append(f"{slug}: no SKILL.md"); continue
        for sk in skills:
            d = sk.parent.name
            txt = sk.read_text(encoding="utf-8")
            m = re.match(r"^---\n(.*?)\n---\n", txt, re.S)
            if not m:
                errors.append(f"{d}: no frontmatter"); continue
            fm = m.group(1)
            nm = re.search(r"^name:\s*(.+)$", fm, re.M)
            if not nm or nm.group(1).strip().strip('"') != d:
                errors.append(f"{d}: SKILL name mismatch")
            if not re.search(r'^description:\s*"?\S', fm, re.M):
                errors.append(f"{d}: empty description")
            if txt.count("```") % 2:
                errors.append(f"{d}: unbalanced code fences")
            if not d.startswith("threejs"):
                for r in REQUIRED:
                    if r not in txt:
                        errors.append(f"{d}: missing section {r!r}")
            if not (sk.parent / "reference.md").exists():
                warns.append(f"{d}: no reference.md")

        # scripts live under each skill dir; count across the plugin
        scripts = [p for p in pdir.glob("skills/*/scripts/*") if p.is_file()]
        for s in scripts:
            err = check_script(s)
            if err:
                errors.append(f"{slug}/{s.name}: {err}")
        if len(scripts) >= MIN_SCRIPTS:
            n_ok_scripts += 1
            mark = "✔"
        else:
            mark = "·"
            (errors if strict else warns).append(
                f"{slug}: {len(scripts)} script(s) (< {MIN_SCRIPTS})")
        print(f"  {mark} {slug:30} scripts={len(scripts)} skills={len(skills)}")

    print(f"\nplugins meeting >= {MIN_SCRIPTS} scripts: {n_ok_scripts}/{len(plugins)}")
    if warns:
        print(f"\n{len(warns)} warning(s):")
        for w in warns: print("  -", w)
    if errors:
        print(f"\n{len(errors)} ERROR(s):")
        for e in errors: print("  ✘", e)
        return 1
    print("\n✔ all checks passed")
    return 0

if __name__ == "__main__":
    sys.exit(main())
