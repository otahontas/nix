---
id: Nix-e5pi
status: closed
deps: [Nix-f4x8]
links: []
created: 2026-04-10T08:27:26Z
type: feature
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add context seeding to ticket workflow

Add a context file mechanism so that pi -p sessions in work-tickets.sh don't start from zero each time. The agent re-discovers build commands, file structure, and conventions on every invocation — this wastes 3-4 turns per ticket.

Inspired by ForgeCode's context engine (their biggest proprietary advantage).

Two changes needed:

1. Modify ticket-creator skill (home/configs/pi-coding-agent/skills/ticket-creator/SKILL.md):
   - Add a step in Mode 2 (decompose) and Mode 3 (seed from plan) workflows
   - After exploring the codebase and before creating tickets: check if plans/.ticket-context.md exists
   - If not, create it with: verification commands (from devenv.nix, package.json, Makefile, flake.nix), key directories relevant to the tickets, and any conventions discovered during exploration
   - The context file is project-local, reusable across all tickets for that batch

2. Modify work-tickets.sh (home/configs/pi-coding-agent/scripts/work-tickets.sh):
   - Before the work loop, read plans/.ticket-context.md if it exists
   - Prepend the context to the pi -p prompt so the agent starts with known build commands and key paths
   - If the file doesn't exist, proceed normally (no hard dependency)

Context file format (plans/.ticket-context.md):

## Verification commands

- Build: <command>
- Test: <command>
- Lint: <command>

## Key directories

- path/ — description

## Conventions

- Description of relevant patterns

## Acceptance Criteria

1. ticket-creator SKILL.md Mode 2 (decompose) includes a step that creates plans/.ticket-context.md if it doesn't exist
2. ticket-creator SKILL.md Mode 3 (seed from plan) includes the same context file creation step
3. The context file step comes after codebase exploration but before ticket creation
4. work-tickets.sh reads plans/.ticket-context.md before the work loop starts
5. work-tickets.sh prepends the context content to the pi -p prompt when the file exists
6. work-tickets.sh works correctly when plans/.ticket-context.md doesn't exist (no error, no context in prompt)
7. Context file includes verification commands, key directories, and conventions

## Notes

**2026-04-10T08:52:15Z**

Added context seeding mechanism to ticket workflow. ticket-creator SKILL.md now includes a 'Context seeding' section used by Mode 2 (decompose) and Mode 3 (seed from plan) to create plans/.ticket-context.md with verification commands, key directories, and conventions. work-tickets.sh reads this file before the work loop and prepends it to the pi prompt so ticket-worker sessions start with project context instead of discovering it from scratch each time.
