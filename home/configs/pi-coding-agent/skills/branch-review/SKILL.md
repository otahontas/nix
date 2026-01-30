---
name: branch-review
description: Local multi-angle code review against the default branch that writes a markdown report.
---

# Branch review

Run a local multi-angle code review against the default branch and write a markdown report.

## Report path

- Default: `./code-review.md` (repo root)
- Allow override when the user passes either:
  - `path=docs/review.md`
  - `docs/review.md`

Treat the argument as a path if it does not contain `=`. If `path=` is provided, use the value after `=`.

## Workflow

1. Detect default branch
   - Try: `git symbolic-ref refs/remotes/origin/HEAD` and extract the branch name
   - Fallback order: `main`, `master`, `develop`, `development`
2. Compute diff
   - `git diff --name-only <base>...HEAD`
   - `git diff <base>...HEAD` (use for hunks/line ranges)
3. Locate AGENTS.md
   - `find . -name "AGENTS.md" 2>/dev/null`
   - Use repo-root AGENTS.md plus any AGENTS.md in directories containing changed files
4. Run review passes (sequential is fine)
   - Policy / AGENTS compliance: check diff against AGENTS.md guidance
   - Bug scan: inspect diff only (avoid large context)
   - History / blame: use `git blame` + `git log` on modified files/lines
   - Prior PRs (optional):
     - If repo is on GitHub and `gh` is available:
       - Detect GitHub via `git remote get-url origin` containing `github.com`
       - Use `gh` to list recent merged PRs and check if they touched modified files (limit 20–50 PRs)
     - If not on GitHub or `gh` unavailable: skip this pass
   - Comment compliance: read code comments in modified files and verify changes follow comment guidance
5. Score issues (0–100)
   - Use rubric: 0, 25, 50, 75, 100
   - Filter to >= 80 only
6. Report
   - If no issues >= 80: do not write the report file
   - Otherwise write the report with:
     - Summary (base branch, current branch, files reviewed)
     - AGENTS.md files used
     - Issues list: description, reason/type, confidence score, file path + line range + commit SHA
   - For commit SHA: `git blame -L start,end -- <file>` and use the first SHA

## Linking

Each issue must include file path + line range + commit SHA. Do not use GitHub URLs.
