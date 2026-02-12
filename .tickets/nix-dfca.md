---
id: nix-dfca
status: open
deps: []
links: []
created: 2026-02-12T20:11:54Z
type: task
priority: 3
assignee: Otto Ahoniemi
tags: [agents, automation, prototype]
---

# Prototype budget-aware autonomous agent loop

Build a prototype script that runs agents in a loop with budget awareness. Tiered model strategy (expensive for planning, cheap for execution). See docs/nix-mbg5-autonomous-agent-loops.md.

## Acceptance Criteria

- Script tracks token/request usage per provider
- Sleeps when budget threshold reached, resumes after reset
- Tiered model selection (planner vs executor)
- Circuit breakers: cost cap, loop cap, deduplication
- Tested on at least one real task
