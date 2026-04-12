---
name: task-pipeline
description: Structured workflow for research → plan → tickets → work. Use when starting or continuing a task with /task, /plan, or /tickets commands.
---

# Task pipeline

A phased workflow for complex tasks. State lives in files, not session memory. Any session can pick up where the last one left off by reading the docs.

## File structure

All work happens in a worktree at `<repo>/.worktrees/<slug>/`. Docs go in `plans/`:

```
plans/
  <slug>.md          # research findings
  <slug>.plan.md     # implementation plan
```

One research doc, one plan doc. Never create alternatives or numbered versions. Update in place.

## Slug naming

Derived from the task description: lowercase, hyphens, short. Examples:

- "add redis caching to session store" → `redis-caching`
- "fix token refresh returning 401" → `token-refresh-fix`
- "lat.md integration" → `lat-md-integration`

## Phase 1: Research

**Entry:** `/task <description>` or `/task <slug>` (to continue)

1. If worktree doesn't exist: create it
   ```bash
   repo_root=$(git rev-parse --show-toplevel)
   mkdir -p "$repo_root/.worktrees"
   git worktree add "$repo_root/.worktrees/<slug>" -b "<slug>"
   ```
2. If `plans/<slug>.md` exists: read it, continue research
3. Research the codebase, web, past sessions — be thorough
4. Write/update `plans/<slug>.md`

### Research doc format

```markdown
# <task description>

## Findings

- Finding 1 with evidence
- Finding 2 with source references
- ...

## Open questions

- Question that couldn't be answered
- ...

## Sources

- file paths, URLs, session references
```

Keep writing until you can't find more. The user will tell you when to move on.

## Phase 2: Plan

**Entry:** `/plan <slug>`

1. Read `plans/<slug>.md` — this is your input
2. If `plans/<slug>.plan.md` exists: read it, iterate based on user feedback
3. Write/update `plans/<slug>.plan.md`

### Plan doc format

```markdown
# Plan: <task description>

Research: `plans/<slug>.md`

## Steps

### Step 1: <title>

- **What:** description
- **Files:** paths to change
- **Verify:** how to confirm it works

### Step 2: <title>

- **What:** description
- **Files:** paths to change
- **Verify:** how to confirm it works

## Notes

- Design decisions, trade-offs, things to watch out for
```

Each step maps 1:1 to a ticket. Steps are ordered by dependency.

The user reviews and iterates. Do not proceed to tickets until the user explicitly says to.

## Phase 3: Tickets

**Entry:** `/tickets <slug>`

1. Read `plans/<slug>.plan.md`
2. Explore the codebase for file hints and verification commands
3. Seed `plans/.ticket-context.md` if it doesn't exist (see context seeding in ticket-creator skill)
4. Create one ticket per plan step using ticket-creator skill Mode 3
5. **Self-validate** (see ticket-creator skill for checklist):

## Phase transitions

| From     | To       | Trigger                        |
| -------- | -------- | ------------------------------ |
| —        | Research | `/task <description>`          |
| Research | Research | `/task <slug>` (continue)      |
| Research | Plan     | `/plan <slug>`                 |
| Plan     | Plan     | `/plan <slug>` (iterate)       |
| Plan     | Tickets  | `/tickets <slug>`              |
| Tickets  | Work     | `work-tickets` in the worktree |

You can go back: run `/plan <slug>` after tickets exist to revise, then `/tickets <slug>` to recreate. Clean up old tickets first (`tk close` or recreate with new deps).

## Rules

- Always work in the worktree, not main checkout
- Always read existing files before writing — pick up where you left off
- Research and plan docs are living documents — update, don't replace with alternatives
- Plan steps must be small enough for one agent session (~30 min of work)
- Never skip self-validation when creating tickets
