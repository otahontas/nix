---
id: Nix-osdd
status: closed
deps: [Nix-2eqw]
links: []
created: 2026-04-10T10:28:21Z
type: feature
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Create pi extension to rewrite bash commands through rtk

Create ~/.pi/agent/extensions/rtk.ts that intercepts bash tool calls and rewrites commands through rtk for token savings.

Use createBashTool with spawnHook pattern (see pi examples/extensions/bash-spawn-hook.ts). The spawnHook should:

1. Skip if command already starts with 'rtk '
2. Call rtk rewrite via execSync with the command as argument
3. Use the rewritten command if rtk rewrite succeeds (exit 0)
4. Fall back to original command if rtk rewrite exits 1 (no rewrite needed)
5. Handle errors gracefully (fallback to original command)

rtk rewrite behavior:

- Accepts command string, exits 0 with rewritten command on stdout
- Exits 1 if no rewrite applies (unsupported command)
- Handles compound commands (&&, ||, ;), heredocs, already-rtk commands

Reference files:

- pi example: examples/extensions/bash-spawn-hook.ts
- Existing extension pattern: ~/.pi/agent/extensions/guardrails.ts

Context in plans/.ticket-context.md

## Acceptance Criteria

1. File ~/.pi/agent/extensions/rtk.ts exists and loads without errors on pi startup
2. Extension overrides the bash tool using createBashTool + spawnHook
3. Commands like 'git status' get rewritten to 'rtk git status' when rtk rewrite supports them
4. Commands not supported by rtk (e.g. 'echo hello') pass through unchanged
5. Commands already prefixed with 'rtk' are not double-rewritten
6. If rtk binary is missing, commands pass through unchanged (graceful degradation)
7. spawnHook handles errors without crashing the bash tool

## Notes

**2026-04-10T11:31:16Z**

Created ~/.pi/agent/extensions/rtk.ts using createBashTool + spawnHook pattern. Interceptts bash commands, calls rtk rewrite via execSync, passes through on failure. All 7 acceptance criteria verified.
