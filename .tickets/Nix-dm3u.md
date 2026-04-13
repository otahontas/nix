---
id: Nix-dm3u
status: closed
deps: []
links: []
created: 2026-04-12T23:48:08Z
type: task
priority: 1
assignee: Otto Ahoniemi
---

# Fix /task and /plan to decouple filenames from user input

Problem: /task and /plan use user's freeform text as the plan file slug. E.g. '/task work on this blaa blaa' tries to slugify 'work on this blaa blaa' into a filename. This is wrong.

Desired behavior:

- /task [freeform description] -> always writes to plans/task.md (single active task, since user always works in a worktree)
- /plan [freeform description] -> always writes to plans/plan.md (single active plan, same reason)
- Filenames are fixed/static, never derived from user input
- Content inside the files reflects the actual task/plan, filename does not
- If a plan/task file already exists, overwrite it (single-plan workflow)

Context: user always works in worktrees so there's only one active plan at a time. No need for unique slugs.
