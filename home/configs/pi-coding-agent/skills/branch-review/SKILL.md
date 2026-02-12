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
   - **Always run:**
     - Policy / AGENTS compliance: check diff against AGENTS.md guidance
     - Bug scan: inspect diff only (avoid large context)
     - History / blame: use `git blame` + `git log` on modified files/lines
     - Silent failure hunt: check error handling — see [references/silent-failure-hunter.md](references/silent-failure-hunter.md)
   - **Conditional passes** (run when relevant files changed):
     - Comment analysis (comments/docs added or modified): see [references/comment-analyzer.md](references/comment-analyzer.md)
     - Test analysis (test files changed): see [references/test-analyzer.md](references/test-analyzer.md)
     - Type design analysis (types added or modified): see [references/type-design-analyzer.md](references/type-design-analyzer.md)
     - Security patterns (GitHub workflows, auth, input handling): see [references/security-patterns.md](references/security-patterns.md)
   - **Optional:**
     - Prior PRs: if repo is on GitHub and `gh` is available, use `gh` to list recent merged PRs touching modified files (limit 20–50). Skip if unavailable.
5. Score issues (0–100)
   - Use rubric: 0, 25, 50, 75, 100
   - Filter to >= 80 only
6. Report
   - If no issues >= 80: do not write the report file
   - Otherwise write the report with:
     - Summary (base branch, current branch, files reviewed, passes run)
     - AGENTS.md files used
     - Critical issues (must fix): description, pass name, confidence score, file path + line range + commit SHA
     - Important issues (should fix): same format
     - Suggestions (nice to have): description, pass name, file path + line range
     - Strengths: what's well-done in this change
   - For commit SHA: `git blame -L start,end -- <file>` and use the first SHA

## Linking

Each issue must include file path + line range + commit SHA. Do not use GitHub URLs.
