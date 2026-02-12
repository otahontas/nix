---
id: nix-z1lq
status: open
deps: [nix-5zf7]
links: []
created: 2026-02-12T20:11:54Z
type: task
priority: 2
assignee: Otto Ahoniemi
tags: [pi, orchestration, plan-mode]
---

# Integrate plan mode UI into orchestrate skill

Update orchestrate/SKILL.md to use plan mode tools for TUI visibility during orchestration. Sync tk state to plan\_\* tools. See docs/ni-9i14-orchestration-plan-mode-design.md and docs/ni-jlnr-orchestration-adaptation-plan.md section 2.4.

## Acceptance Criteria

- SKILL.md references plan_set_goal, plan_add_step, plan_mark_active, plan_mark_done
- Plan mode syncs with tk ticket states
- User sees progress widget during orchestration
