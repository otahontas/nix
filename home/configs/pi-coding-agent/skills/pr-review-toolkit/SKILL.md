---
name: pr-review-toolkit
description: Multi-angle PR/branch review using specialized analysis passes (comments, tests, errors, types, security). Use when reviewing a PR, preparing code for merge, or doing a thorough pre-commit review.
---

# PR review toolkit

Comprehensive code review using specialized analysis passes, each focusing on a different aspect of code quality.

## Arguments

Optional: specify which review aspects to run. Default: all applicable.

Available aspects:

- `comments` — comment accuracy and maintainability
- `tests` — test coverage quality and completeness
- `errors` — silent failures and error handling
- `types` — type design and invariants (if new types added)
- `security` — security vulnerability patterns
- `all` — run all applicable reviews (default)

## Workflow

### 1. Determine scope

```bash
git diff --name-only HEAD~1..HEAD  # or against base branch
```

If a specific base branch is provided, use that. Otherwise detect:

```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```

Fallback: `main`, then `master`, then `develop`.

### 2. Read project context

```bash
find . -name "AGENTS.md" 2>/dev/null | head -10
```

Read AGENTS.md files for project conventions.

### 3. Determine applicable reviews

Based on changed files:

- **Always**: general code quality check
- **If test files changed**: test analysis pass
- **If comments/docs added or modified**: comment analysis pass
- **If error handling changed** (try/catch, error callbacks): silent failure hunt
- **If types added/modified**: type design analysis
- **If GitHub workflows or security-sensitive patterns**: security pass

### 4. Run review passes

For each applicable pass, read the reference file and apply it to the diff:

- [Comment analyzer](references/comment-analyzer.md) — verifies comment accuracy, identifies rot
- [Test analyzer](references/test-analyzer.md) — reviews test coverage quality
- [Silent failure hunter](references/silent-failure-hunter.md) — finds silent failures, bad error handling
- [Type design analyzer](references/type-design-analyzer.md) — analyzes type encapsulation and invariants
- [Security patterns](references/security-patterns.md) — checks for common security vulnerabilities

For general code quality: check AGENTS.md compliance, bug detection (logic errors, null handling, race conditions), and significant code quality issues. Use confidence scoring 0-100, report only issues >= 80.

### 5. Aggregate results

Organize findings into a single report:

```markdown
# PR review summary

## Scope

- Base: <branch>
- Changed files: <count>
- Reviews run: <list>

## Critical issues (must fix)

- [pass-name]: description [file:line] (confidence: X)

## Important issues (should fix)

- [pass-name]: description [file:line] (confidence: X)

## Suggestions (nice to have)

- [pass-name]: description [file:line]

## Strengths

- What's well-done in this change

## Recommended action

1. Fix critical issues first
2. Address important issues
3. Consider suggestions
```

### 6. Present to user

Show the aggregated report. If no issues found above confidence threshold, say so.

## Tips

- Run before creating PR, not after
- Address critical issues first
- Re-run after fixes to verify
- Use specific aspects when you know the concern: e.g., `/skill:pr-review-toolkit errors tests`
