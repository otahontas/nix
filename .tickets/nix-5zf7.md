---
id: nix-5zf7
status: open
deps: [nix-5r18]
links: []
created: 2026-02-12T20:11:54Z
type: task
priority: 1
assignee: Otto Ahoniemi
tags: [pi, orchestration, tk]
---

# Integrate tk ticket workflow into orchestrate skill

Update orchestrate/SKILL.md to mandate tk usage for persistent state. Map orchestrator phases to tk commands. See docs/ni-kaw7-orchestrator-tk-integration.md and docs/ni-jlnr-orchestration-adaptation-plan.md section 2.3.

## Acceptance Criteria

- SKILL.md documents when to call tk create, start, dep, add-note, close
- Failure handling: failed agents leave tickets open with notes
- Orchestrator can resume from tk state after crash
- Example workflow walkthrough included
