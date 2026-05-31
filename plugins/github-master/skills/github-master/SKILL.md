---
name: github-master
description: "Expert Git & GitHub: workflows, history recovery, pull requests, branch protection, and Actions CI/CD. Trigger keywords: git, GitHub, merge conflict, rebase, cherry-pick, reflog, bisect, force push, pull request, branch protection, GitHub Actions, CI/CD, release, conventional commits. Use for Git troubleshooting, collaboration/automation setup, or recovering lost work."
---

# GitHub Master

> Commits are cheap, lost work is recoverable (reflog), and history is communication. Rebase your own local work, never shared history; force-push only with `--force-with-lease`.

## When to Use
- Git commands or trouble: conflicts, detached HEAD, lost commits, undo/redo.
- Repo management, PRs, issues, branch protection, CODEOWNERS.
- Branching strategy or GitHub Actions CI/CD.
- Recovering or rewriting history safely.

## When NOT to Use
- Writing application code → relevant language skill.
- High-level system design → `software-architect`.
- Shell logic inside workflows → `bash-scripting-expert`.

## Core Principles

### 1. Core operations & recovery
- Fluent with `add`/`commit`/`push`/`pull`/`branch`/`merge`/`rebase`, plus `stash`, `cherry-pick`, `bisect`, `worktree`.
- **Almost nothing is truly lost**: `git reflog` finds detached/`reset`-away commits. Prefer `git revert` (safe, new commit) over `reset --hard` on anything shared.
- Undo map: un-add → `restore --staged`; amend last (local) commit → `commit --amend`; move branch pointer → `reset`; recover → `reflog` + `checkout -b`.

### 2. Rewriting history — the safety rule
- Rewrite **only local, unpushed** commits (interactive rebase to clean up). **Never** rewrite shared/`main` history.
- If you must update a shared branch after rebase, use `git push --force-with-lease` (refuses if someone else pushed) — never plain `--force`.

### 3. Workflow & commits
- **GitHub Flow** (main + short-lived feature branches) for most teams; Git Flow only for heavy release trains. Protect `main` with required reviews + status checks; use CODEOWNERS and PR/issue templates.
- **Conventional Commits** (`feat:`, `fix:`, `docs:`) enable automated changelogs/SemVer. Small, focused PRs that explain *why*; link issues (`Fixes #123`). Know merge strategies: squash (clean linear history), merge commit (preserve context), rebase (linear, no merge commit).

### 4. GitHub Actions CI/CD
- Workflows in `.github/workflows/*.yml`: triggers (`on`), jobs, steps, runners. Cache dependencies (`actions/cache` or `setup-*` cache), use matrix builds, **pin action versions**, and scope `permissions:` to least privilege. Secrets via encrypted Secrets/Variables — never echo them.

## Common Mistakes
- **`push --force`** on a shared branch → overwrites teammates' work; use `--force-with-lease`.
- **`reset --hard`** to "undo" pushed commits → use `revert`.
- **Rebasing a shared/public branch** → diverges everyone; rebase only local work.
- **Committing secrets / large binaries** → use env/secret manager + `.gitignore`/LFS; rotate if leaked.
- **Giant, mixed PRs** → hard to review; keep them small and single-purpose.
- **Unpinned actions / over-broad `permissions`** → supply-chain and token risk.
- **Panic after a bad `reset`/`rebase`** → check `git reflog` before despairing.

## Examples

**Recover a commit removed by a bad reset**
```bash
git reflog                          # find the lost SHA, e.g. a1b2c3d
git checkout -b recovered a1b2c3d
```

**Safely update a feature branch after rebase**
```bash
git rebase origin/main
git push --force-with-lease         # refuses if remote moved underneath you
```

**Minimal cached CI workflow (pinned, matrixed, least-priv)**
```yaml
name: CI
on: [pull_request]
permissions: { contents: read }
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix: { node: ["20", "22"] }
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: "${{ matrix.node }}", cache: npm }
      - run: npm ci
      - run: npm test
```

## See Also
- `software-architect` — turning design into branching/release strategy.
- `bash-scripting-expert` — robust scripts inside workflows.
- `docker-expert` / `kubernetes-expert` — building/deploying from CI.
