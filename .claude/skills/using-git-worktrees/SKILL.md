---
name: using-git-worktrees
description: Use when starting feature work or reviewing PRs - uses git-worktree-new/pr/prune shell functions with automatic git-crypt support, Husky disabled, and .worktrees/ location. No manual setup needed.
---

# Using Git Worktrees

## CRITICAL: Use Shell Functions Only

**NEVER use manual `git worktree add` commands.**

**ALWAYS use these shell functions:**
- `git-worktree-new BRANCH_NAME` for feature work
- `git-worktree-pr PR_NUMBER` for PR review
- `git-worktree-prune BRANCH_NAME` for cleanup

If you find yourself typing `git worktree`, STOP. Use the functions above.

## Overview

Shell functions handle everything automatically:
- git-crypt decryption
- HUSKY=0 (CI mode)
- .worktrees/ location
- CD into worktree
- Requires GitHub CLI `gh` for PR lookups

## Commands

### git-worktree-new BRANCH_NAME

Creates new worktree with new branch:

```bash
git-worktree-new feature/auth
```

Creates `.worktrees/feature/auth`, new branch, handles git-crypt, CDs in.

### git-worktree-pr PR_NUMBER

Reviews PR in isolated worktree:

```bash
git-worktree-pr 123
```

Fetches PR, creates `.worktrees/pr-123-branch-name`, CDs in.
If `gh` is not available, this command cannot resolve PR metadata and will fail early.

### git-worktree-prune BRANCH_NAME

Cleanup when done:

```bash
git-worktree-prune feature/auth
```

Removes worktree directory and force-deletes branch (-D).
For PR worktrees, pass the slug printed when the worktree was created (e.g. `pr-123-feature-auth`) so the matching `.worktrees/` directory can be removed and the branch deleted.

## Quick Reference

| Task | Command | Result |
|------|---------|--------|
| Start feature | `git-worktree-new feature/name` | New branch in .worktrees/feature/name |
| Review PR | `git-worktree-pr 123` | PR in .worktrees/pr-123-branch |
| Cleanup | `git-worktree-prune feature/name` | Removes worktree + branch |

## What Happens Automatically

- ✓ Creates `.worktrees/BRANCH_NAME`
- ✓ Handles git-crypt (if present)
- ✓ Sets HUSKY=0 (no hooks)
- ✓ CDs into worktree
- ✓ Warns if uncommitted changes

## What You DON'T Do

- ✗ Don't run `git worktree add` manually
- ✗ Don't install dependencies (npm ci, cargo build, etc.)
- ✗ Don't run tests after creating worktree
- ✗ Don't run builds after creating worktree
- ✗ Don't verify .gitignore (`.worktrees/` in global gitignore)
- ✗ Don't add .worktrees to project .gitignore
- ✗ Don't ask about directory location
- ✗ Don't check if branch is merged before cleanup
- ✗ Don't ask "should I verify it's safe?" before cleanup
- ✗ Don't run verification commands before cleanup

The functions handle isolation. You jump in when ready. User handles any setup needed.

## Common Mistakes

**Using manual git worktree commands**
- Problem: Bypasses git-crypt, HUSKY=0, wrong location
- Fix: Always use git-worktree-new/pr/prune

**Running setup commands after worktree creation**
- Problem: Not part of this workflow, wastes time
- Fix: Just run the command, CD in, let user handle any setup

**Verifying "is it safe to cleanup?"**
- Problem: git-worktree-prune uses -D (force delete), user already decided
- Fix: Just run git-worktree-prune, no verification

**Asking about directory location**
- Problem: Always `.worktrees/`, no exceptions
- Fix: Use commands directly

**Checking merge status before cleanup**
- Problem: User said "clean it up", they know the status
- Fix: Run git-worktree-prune immediately

**Verifying .gitignore**
- Problem: `.worktrees/` in global gitignore already
- Fix: Never check or modify .gitignore

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I should install dependencies first" | Not part of this workflow. User handles setup. |
| "I should run tests to verify" | Not part of this workflow. User handles testing. |
| "I should verify it's safe to cleanup" | User said cleanup, they know status. Run prune. |
| "I should check if merged first" | git-worktree-prune uses -D, checking wastes time. |
| "Let me verify .gitignore" | `.worktrees/` in global gitignore. Never check. |
| "I should ask about location" | Always `.worktrees/`. Never ask. |

## Red Flags - STOP

If you catch yourself doing any of these, STOP and use the functions instead:

- `git worktree add` manually
- `npm ci` or `npm install` after worktree creation
- `npm test` or any test commands after worktree creation
- `cargo build` or other build commands after worktree creation
- Checking .gitignore
- Asking "should I install dependencies?"
- Asking "should I verify it's safe to cleanup?"
- Asking "where should I create the worktree?"
- `git branch -d` (safe delete) instead of letting prune handle it
- Running `git status` or `git branch --merged` before cleanup

**All of these mean: Just run git-worktree-new/pr/prune directly.**

## Integration

**Use this skill when:**
- User says "implement X feature"
- User says "review PR #N"
- User says "clean up" or "we're done"
- brainstorming skill suggests creating worktree
- Any task needing isolated workspace
