---
id: nix-yi4c
status: open
deps: []
links: []
created: 2026-02-12T20:11:54Z
type: task
priority: 2
assignee: Otto Ahoniemi
tags: [pi, dx, hooks]
---

# Install pi pre-commit hook extension

Install the pre-commit hook extension from docs/nix-gksq-pi-agent-pre-commit-hooks.md into .pi/extensions/pre-commit-hook.ts. Runs prek checks on files after each edit/write tool call.

## Acceptance Criteria

- Extension at .pi/extensions/pre-commit-hook.ts
- Runs prek on modified files after edit/write tool calls
- Lint failures shown to LLM as tool result errors
- Does not crash agent if prek unavailable
