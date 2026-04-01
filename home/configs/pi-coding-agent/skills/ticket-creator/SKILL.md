---
name: ticket-creator
description: Create agent-friendly tickets for the tk ticket system. Use when the user says 'create tickets for X', 'break this into tickets', 'seed tickets from plan', or anything about creating tk tickets.
---

# Ticket creator

Create well-structured tickets that the ticket-worker skill can consume without ambiguity.

## Ticket format contract

Every ticket must have:

| Field               | Required           | How                                                                            |
| ------------------- | ------------------ | ------------------------------------------------------------------------------ |
| Title               | Yes                | Imperative, scoped action: `tk create "Add rate limiting to auth endpoints"`   |
| Description         | Yes                | What to do, why, and file hints (`see src/auth/`)                              |
| Acceptance criteria | Yes                | Numbered, each independently verifiable. Prefer criteria that map to a command |
| Type                | Yes                | `bug`, `feature`, `task`, `epic`, `chore`                                      |
| Dependencies        | When order matters | `tk dep <id> <blocks-id>` — the second arg depends on the first                |

### Good ticket example

```bash
tk create "Fix token refresh returning 401 on expired tokens" \
  -d "The /auth/refresh endpoint returns 401 when the refresh token is expired.
Should return 403 with a clear error message instead.
Relevant code in src/auth/refresh.ts and src/auth/middleware.ts." \
  --acceptance "1. POST /auth/refresh with expired token returns 403 (not 401)
2. Response body includes 'error' field with descriptive message
3. Existing tests pass
4. New test covers expired token case" \
  -t bug
```

### Bad ticket example

```bash
tk create "Fix the bug" -d "There's a bug somewhere in auth"
```

No acceptance criteria, no file hints, no verification command. The agent will wander.

## Acceptance criteria guidelines

- Each criterion must be independently verifiable
- Prefer criteria that map to a command: "tests pass", "linter clean", "curl returns X"
- Always include "existing tests still pass" as one criterion (unless no tests exist)
- For refactors: "behavior unchanged" + "tests pass" is sufficient
- Never use vague criteria like "code is clean" or "well-structured"

## Size rule

A single ticket should be completable in one agent session (~30 min of agent work). If a task is larger, split it into multiple tickets with dependencies.

## Modes

### Mode 1: single ticket

User says: "create a ticket for X"

1. Clarify scope if ambiguous
2. Explore the codebase to find relevant files
3. Create one ticket with all fields populated
4. Show the created ticket to the user

### Mode 2: decompose

User says: "break this goal into tickets" or "create tickets for refactoring X"

1. Understand the full goal
2. Explore the codebase to understand scope and relevant files
3. Break into small, independently completable tickets
4. Create tickets in dependency order (create the prerequisite tickets first so you have their IDs)
5. Set dependencies: `tk dep <downstream-id> <upstream-id>` (downstream depends on upstream)
6. Show all created tickets and their dependency chain

### Mode 3: seed from plan

User says: "seed tickets from this plan" or provides a plan file path

1. Read the plan file
2. Identify discrete work items
3. Create tickets for each, preserving the plan's ordering via dependencies
4. Show the created tickets

## Workflow

1. Read the user's request
2. Explore the codebase to understand relevant files and context
3. Draft ticket(s) mentally — title, description with file hints, acceptance criteria
4. Create tickets via `tk create` with all fields populated
5. If multiple tickets: set dependencies via `tk dep <id> <dep-id>`
6. Present created tickets for review
