---
id: sscfb-u6el
status: closed
deps: [sscfb-cjbq]
links: []
created: 2026-04-10T20:56:27Z
type: task
priority: 2
assignee: Otto Ahoniemi
parent: sscfb-cjbq
tags: [ready-for-development]
---
# Add bash implementations for cd-dependent worktree functions

These functions cd into a worktree directory, so they must remain shell functions (scripts can't change parent cwd).

Functions needing bash versions:
- git-worktree-new (gwnew): creates worktree + branch, cds into it
- git-worktree-pr (gwpr): creates worktree from PR, cds into it
- git-worktree-cd (gwcd): cds into existing worktree

Reference implementations in home/configs/git/worktree.fish.

Write bash equivalents and add via programs.bash.bashrcExtra or programs.bash.initExtra.
The fish versions stay as-is.

The gwprune function does NOT cd — it will be converted to a script in the scripts ticket.

## Acceptance Criteria

1. gwnew, gwpr, gwcd work in bash
2. Fish versions unchanged
3. home-manager build succeeds


## Notes

**2026-04-11T01:31:37Z**

Added bash implementations for git-worktree-new, git-worktree-pr, git-worktree-cd via programs.bash.bashrcExtra. Fish versions unchanged.
