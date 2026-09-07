---
description: Commit, rebase, merge, and remove a worktree
---

# Finalize worktree

Finalize the worktree implied by the conversation. If no single target is clear, ask which worktree and stop. Never use `main` as the target worktree.

1. Verify the target is a linked worktree on a non-`main`, non-detached branch, and locate the local `main` worktree. Stop before changing anything if either checkout is unsafe or the `main` worktree is dirty.
2. Commit all changes in the target worktree. Skip the commit when clean.
3. Rebase the target branch onto local `main`. Resolve safe conflicts; stop and ask when intent is unclear.
4. Fast-forward merge the rebased branch into `main`. Do not fetch, pull, push, or create a merge commit.
5. Verify `main` matches the branch tip and both worktrees are clean.
6. Remove the target worktree, delete its merged branch, then run `git worktree prune`. Do not force cleanup.
7. Report commit, rebase, merge, and cleanup results.
