# Git & GitHub Engineering Reference

Load for CI templates, branch-protection setup, release automation, and history recovery.

## Branch protection (main)
Require: PR review (≥1), passing status checks, up-to-date branch, linear history; restrict force-push/delete. Via `gh`:
```bash
gh api -X PUT repos/{owner}/{repo}/branches/main/protection \
  -F required_pull_request_reviews.required_approving_review_count=1 \
  -F required_status_checks.strict=true \
  -F enforce_admins=true -F restrictions=null
```

## CI workflow (least-privilege, cached)
`scripts/scaffold-ci.sh node|python|go` generates this. Principles:
- `permissions: { contents: read }` by default; grant more per-job only when needed.
- `concurrency` to cancel superseded runs. Cache deps via `setup-*` `cache:`.
- **Pin actions** (tag at least, SHA for high-security). Matrix across versions/OS.

## Conventional Commits → automated releases
`type(scope)!: subject` — `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`. `!` or `BREAKING CHANGE:` = major bump. Enables changelog/SemVer automation (`release-please`, semantic-release). `scripts/release-notes.sh` builds notes from these.

## History recovery cookbook
| Goal | Command |
|------|---------|
| See everything (incl. lost commits) | `git reflog` |
| Recover a dropped commit | `git checkout -b save <sha-from-reflog>` |
| Undo last commit, keep changes | `git reset --soft HEAD~1` |
| Undo a pushed commit safely | `git revert <sha>` |
| Update branch after rebase | `git push --force-with-lease` |
| Find which commit broke it | `git bisect start / good / bad` |
| Move uncommitted work to a branch | `git stash` → `git switch -c x` → `git stash pop` |
| Apply one commit elsewhere | `git cherry-pick <sha>` |

**Golden rule:** rewrite only local, unpushed history. Never rewrite shared `main`. `--force-with-lease`, never bare `--force`.

## Merge strategies
| Strategy | Result | Use when |
|----------|--------|----------|
| Squash | one tidy commit | feature branches, noisy WIP history |
| Merge commit | preserves branch history | release/long-lived branches |
| Rebase | linear, no merge commit | small, clean changes |

## PR hygiene
Small & single-purpose; title in Conventional-Commit style; describe *why*; link issues (`Fixes #123`); keep the diff reviewable (<~400 lines). Draft early for feedback.

## Scripts
- `scripts/repo-health.sh [dir]` — audit essential files, CI, binaries, branch protection (via gh).
- `scripts/scaffold-ci.sh [node|python|go] [dir]` — least-privilege CI workflow + PR template + CODEOWNERS.
- `scripts/release-notes.sh [since-ref]` — Markdown changelog from Conventional Commits, with breaking-changes section.
