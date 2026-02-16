---
id: nix-xjxm
status: closed
deps: []
links: [nix-7ny4]
created: 2026-02-16T07:32:58Z
type: task
priority: 2
assignee: Otto Ahoniemi
---

# Investigate devenv claude-code integration for automatic formatting

Investigate https://devenv.sh/integrations/claude-code/ and how to add automatic formatting using that integration.

## Notes

**2026-02-16T07:34:51Z**

## Investigation findings

### What `claude.code.enable = true` does

Adding `claude.code.enable = true;` to `devenv.nix` generates a `.claude/settings.json` with PostToolUse hooks. When git-hooks are configured (which this repo already has), it auto-generates a hook that runs `pre-commit run --files <edited-file>` after every file edit/write by Claude Code.

This repo already has the necessary formatters configured in git-hooks:

- nixfmt, prettier, shfmt, stylua, taplo, fish_indent (via treefmt)
- deadnix, statix, shellcheck, typos (linters)

### The problem: pi agent, not claude code

This repo uses **pi coding agent**, not Claude Code CLI. The devenv claude-code integration generates `.claude/settings.json` hooks — a Claude Code-specific format. Pi does not read `.claude/settings.json`; it has its own extension system with lifecycle events (`tool_result`, `tool_execution_end`, etc.).

### What would be needed for pi

A pi extension that:

1. Listens to `tool_execution_end` or `tool_result` events for edit/write tools
2. Extracts the file path from the tool input
3. Runs `pre-commit run --files <file>` (or `treefmt --paths <file>`)
4. Returns the formatted result back to the agent

This is exactly what ticket `nix-7ny4` covers — using claude code hooks concept in pi via extensions.

### Verdict

The devenv `claude.code.enable` integration is not directly usable with pi agent. It's designed for Claude Code CLI only. The auto-formatting concept is sound, but needs a pi extension implementation instead. Linking this ticket to `nix-7ny4` for the implementation path.
