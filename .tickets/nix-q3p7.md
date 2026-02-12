---
id: nix-q3p7
status: open
deps: [nix-dfca]
links: []
created: 2026-02-12T20:11:54Z
type: task
priority: 3
assignee: Otto Ahoniemi
tags: [agents, sandbox, security]
---

# Set up agent sandboxing for autonomous loops

Set up sandboxing for autonomous agent execution. Evaluate sandvault for macOS-native work and Docker sandboxes for general dev. See docs/nix-mbg5-autonomous-agent-loops.md section 4.

## Acceptance Criteria

- Sandboxing solution installed and tested
- Agent can run in sandbox with restricted filesystem access
- Agent cannot push to remote or modify system files
- Documented setup and usage
