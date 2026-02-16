---
id: nix-7ny4
status: closed
deps: []
links: [nix-xjxm]
created: 2026-02-16T07:33:00Z
type: task
priority: 2
assignee: Otto Ahoniemi
---

# Investigate using claude code hooks in pi agent via extensions

Investigate how to use claude code hooks in the pi coding agent using extensions.

## Notes

**2026-02-16T07:53:01Z**

## Implementation

- Added `claude.code.enable = true` to devenv.nix — generates `.claude/settings.json` with PostToolUse hook that runs `pre-commit run` after edits
- Added `.claude/` to `.gitignore` (it's a generated symlink)
- Created `~/.pi/agent/extensions/claude-code-hooks.ts` — reads `.claude/settings.json` and executes hooks in pi
- Removed `~/.pi/agent/extensions/pre-commit-hook.ts` (superseded)

### How it works

1. On `session_start`, reads `.claude/settings.json` from project root
2. Maps Claude Code events to pi events: PreToolUse → tool_call, PostToolUse → tool_result, Stop → agent_end
3. Maps pi tool names to Claude Code names (edit → Edit, etc.) for matcher regex
4. Pipes Claude Code-compatible JSON to hook commands via stdin using node:child_process spawn
5. PostToolUse failures append error output to tool result so the LLM sees and fixes them
