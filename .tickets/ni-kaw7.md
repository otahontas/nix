---
id: ni-kaw7
status: open
deps: []
links: [ni-9i14]
created: 2026-02-12T18:54:09Z
type: task
priority: 2
assignee: Otto Ahoniemi
parent: ni-vljj
tags: [pi, orchestration, tk, tickets]
---

# Integrate orchestrator skill with tk ticket workflow

Design how the orchestrator skill should create, update, and close tk tickets during multi-agent runs.

## Acceptance Criteria

- Define when the orchestrator should call `tk create`, `tk start`, `tk status`, and `tk close`.
- Map orchestrator workflow steps to ticket states and dependency updates.
- Document failure and retry handling for ticket updates.
